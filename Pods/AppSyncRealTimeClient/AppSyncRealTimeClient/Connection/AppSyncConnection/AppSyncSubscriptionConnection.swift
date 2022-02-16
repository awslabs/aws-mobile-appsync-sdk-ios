//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum SubscriptionState {
    case notSubscribed

    case inProgress

    case subscribed
}

public class AppSyncSubscriptionConnection: SubscriptionConnection, RetryableConnection {
    /// Connection provider that connects with the service
    weak var connectionProvider: ConnectionProvider?

    /// The current state of subscription
    var subscriptionState: SubscriptionState = .notSubscribed

    /// Current item that is subscribed
    private(set) var subscriptionItem: SubscriptionItem?

    /// Retry logic to handle
    var retryHandler: ConnectionRetryHandler?

    public init(provider: ConnectionProvider) {
        self.connectionProvider = provider
    }

    public func subscribe(
        requestString: String,
        variables: [String: Any?]?,
        eventHandler: @escaping (SubscriptionItemEvent, SubscriptionItem) -> Void
    ) -> SubscriptionItem {
        let subscriptionItem = SubscriptionItem(
            requestString: requestString,
            variables: variables,
            eventHandler: eventHandler
        )
        self.subscriptionItem = subscriptionItem
        addListener()
        subscriptionItem.subscriptionEventHandler(.connection(.connecting), subscriptionItem)
        connectionProvider?.connect()
        return subscriptionItem
    }

    public func unsubscribe(item: SubscriptionItem) {
        AppSyncLogger.debug("[AppSyncSubscriptionConnection] Unsubscribe \(item.identifier)")

        let message = AppSyncMessage(id: item.identifier, type: .unsubscribe("stop"))

        guard let connectionProvider = connectionProvider else {
            AppSyncLogger.warn("[AppSyncSubscriptionConnection] \(#function): missing connection provider")
            return
        }

        guard let subscriptionItem = subscriptionItem else {
            AppSyncLogger.warn("[AppSyncSubscriptionConnection] \(#function): missing subscription item")
            return
        }

        connectionProvider.write(message)
        connectionProvider.removeListener(identifier: subscriptionItem.identifier)
    }

    private func addListener() {
        guard let connectionProvider = connectionProvider else {
            AppSyncLogger.warn("[AppSyncSubscriptionConnection] \(#function): no connection provider")
            return
        }

        guard let subscriptionItem = subscriptionItem else {
            AppSyncLogger.warn("[AppSyncSubscriptionConnection] \(#function): no subscription item")
            return
        }

        connectionProvider.addListener(identifier: subscriptionItem.identifier) { [weak self] event in
            guard let self = self else {
                AppSyncLogger.debug("[AppSyncSubscriptionConnection] \(#function): Self is nil, listener is not called.")
                return
            }
            switch event {
            case .connection(let state):
                self.handleConnectionEvent(connectionState: state)
            case .data(let response):
                self.handleDataEvent(response: response)
            case .error(let error):
                self.handleError(error: error)
            }
        }
    }

    public func addRetryHandler(handler: ConnectionRetryHandler) {
        retryHandler = handler
    }
}
