//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AppSyncSubscriptionConnection {
    func handleConnectionEvent(connectionState: ConnectionState) {
        // If we get back not connected during an inprogress subscription connection
        // we should retry the connection
        if connectionState == .notConnected
            && subscriptionState == .inProgress {
            let connectionError = ConnectionProviderError.connection
            handleError(error: connectionError)
            return
        }
        if connectionState == .connected {
            startSubscription()
        }
    }

    // MARK: - Private implementations

    private func startSubscription() {
        guard
            let subscriptionItem = subscriptionItem,
            subscriptionState == .notSubscribed
        else {
            return
        }
        AppSyncLogger.debug("[AppSyncSubscriptionConnection] \(#function): connection is connected, start subscription.")
        subscriptionState = .inProgress

        guard let payload = convertToPayload(
            for: subscriptionItem.requestString,
            variables: subscriptionItem.variables
        ) else {
            return
        }

        let message = AppSyncMessage(
            id: subscriptionItem.identifier,
            payload: payload,
            type: .subscribe("start")
        )
        connectionProvider?.write(message)
    }

    private func convertToPayload(for query: String, variables: [String: Any?]?) -> AppSyncMessage.Payload? {
        guard let subscriptionItem = subscriptionItem else {
            AppSyncLogger.warn("[AppSyncSubscriptionConnection] \(#function): missing subscription item")
            return nil
        }

        var dataDict: [String: Any] = ["query": query]
        if let subVariables = variables {
            dataDict["variables"] = subVariables
        }
        var payload = AppSyncMessage.Payload()
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dataDict)
            payload.data = String(data: jsonData, encoding: .utf8)
        } catch {
            AppSyncLogger.error(error)
            let jsonError = ConnectionProviderError.jsonParse(nil, error)
            subscriptionItem.subscriptionEventHandler(.failed(jsonError), subscriptionItem)
        }
        return payload
    }
}
