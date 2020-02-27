//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Dispatch
import AppSyncRealTimeClient

/// Used to determine the reason why a subscription is being cancelled/ disconnected.
///
/// - none: Indicates there is no source of cancellation yet.
/// - user: Indicates that the developer invoked `cancel`
/// - `error`: Indicates that there was a protocol/ network or service level error.
/// - `deinit`: Indicates that the watcher was released from memory and the subscription should be disconnected.
enum CancellationSource {
    case none, user, `error`, `deinit`
}

/// A `AWSAppSyncSubscriptionWatcher` is responsible for watching the subscription, and calling the result handler with
/// a new result whenever any of the data is published. It also normalizes the cache before giving the callback to customer.
public final class AWSAppSyncSubscriptionWatcher<Subscription: GraphQLSubscription>: Cancellable {

    private let store: ApolloStore
    private let subscription: Subscription
    private var connection: SubscriptionConnection?
    private var subscriptionItem: SubscriptionItem?

    private let handlerQueue: DispatchQueue
    private var resultHandler: SubscriptionResultHandler<Subscription>?
    private var connectedCallback: (() -> Void)?
    private var statusChangeHandler: SubscriptionStatusChangeHandler?

    private var isCancelled: Bool = false
    private var cancellationSource: CancellationSource = .none
    private var status = AWSAppSyncSubscriptionWatcherStatus.connecting

    init(connection: SubscriptionConnection,
         store: ApolloStore,
         subscriptionsQueue: DispatchQueue,
         subscription: Subscription,
         handlerQueue: DispatchQueue,
         statusChangeHandler: SubscriptionStatusChangeHandler? = nil,
         connectedCallback: (() -> Void)? = nil,
         resultHandler: @escaping SubscriptionResultHandler<Subscription>) {

        AppSyncLog.verbose("Subscribing to operation \(subscription)")
        self.connection = connection
        self.store = store
        self.subscription = subscription
        self.handlerQueue = handlerQueue
        self.statusChangeHandler = statusChangeHandler
        self.connectedCallback = connectedCallback
        self.resultHandler = { (result, transaction, error) in
            handlerQueue.async {
                resultHandler(result, transaction, error)
            }
        }
        subscriptionsQueue.async { [weak self] in
            guard let self = self else {return}
            if !self.isCancelled {
                self.startSubscription()
            }
        }
    }
    
    private func startSubscription() {
        guard let connection = connection else {
            AppSyncLog.debug("Connection is nil, could not subscribe")
            self.resultHandler?(nil, nil, AWSAppSyncSubscriptionError.setupError("Connection is nil"))
            return
        }

        let requestString = type(of: subscription).requestString
        subscriptionItem = connection.subscribe(requestString: requestString,
                                                variables: subscription.variables) { [weak self] (event, item) in
                                                    switch event {
                                                    case .connection(let value):
                                                        self?.handleConnectionEvent(value)
                                                    case .data(let data):
                                                        self?.handleMessage(data)
                                                    case .failed(let error):
                                                        self?.handleError(error)
                                                    }
        }
    }

    // MARK: - Result handling

    func handleConnectionEvent(_ event: SubscriptionConnectionEvent) {
        AppSyncLog.debug("Subscription connectedCallback \(connectedCallback == nil ? "" : "(callback is null)")")
        switch event {
        case .connected:
            connectedCallback?()
            statusChangeHandler?(AWSAppSyncSubscriptionWatcherStatus.connected)
        case .connecting:
            statusChangeHandler?(AWSAppSyncSubscriptionWatcherStatus.connecting)
        case .disconnected:
            statusChangeHandler?(AWSAppSyncSubscriptionWatcherStatus.disconnected)
        }
    }

    func handleMessage(_ data: Data) {
        do {
            AppSyncLog.debug("Received message")
            AppSyncLog.verbose("First \(min(data.count, 128)) bytes of message data is [\(data.prefix(upTo: min(data.count, 128)))]")

            guard String(data: data, encoding: .utf8) != nil else {
                let error = AWSAppSyncSubscriptionError.messageCallbackError("Unable to convert message data to String using UTF8 encoding")
                AppSyncLog.error(error)
                self.resultHandler?(nil, nil, error)
                return
            }

            // If `deserialize` throws an error, it will be caught in the `catch` block below. If it
            // succeeds, but the result cannot be cast to a JSON object, we'll handle it inside the body
            // of the guard statement.
            guard let jsonObject = try JSONSerializationFormat.deserialize(data: data) as? JSONObject else {
                let error = AWSAppSyncSubscriptionError.messageCallbackError("Unable to deserialize message data")
                AppSyncLog.error(error)
                self.resultHandler?(nil, nil, error)
                return
            }

            let response = GraphQLResponse(operation: subscription, body: jsonObject)

            firstly {
                try response.parseResult(cacheKeyForObject: self.store.cacheKeyForObject)
            }.andThen { (result, records) in
                _ = self.store.withinReadWriteTransaction { transaction in
                    self.resultHandler?(result, transaction, nil)
                }

                if let records = records {
                    self.store.publish(records: records, context: nil).catch { error in
                        preconditionFailure(String(describing: error))
                    }
                }
            }.catch { error in
                self.resultHandler?(nil, nil, AWSAppSyncSubscriptionError.parseError(error))
            }
        } catch {
            self.resultHandler?(nil, nil, AWSAppSyncSubscriptionError.parseError(error))
        }
    }

    func handleError(_ error: Error) {
        if let connectionError = error as? ConnectionProviderError {
            switch connectionError {
            case .connection:
                self.cancellationSource = .`error`
                statusChangeHandler?(.error(.other(error)))
            default:
                resultHandler?(nil, nil, error)
            }
        }
    }

    deinit {
        // call cancel here before exiting
        if self.cancellationSource == .none {
            self.cancellationSource = .deinit
        }
        performCleanUpTasksOnCancel()
    }    
    
    /// Cancel any in progress fetching operations and unsubscribe from the messages. After canceling, no updates will
    /// be delivered to the result handler or status change handler.
    ///
    /// Internally, this method sets an `isCancelled` flag to prevent any future activity, and issues a
    /// `cancelSubscription` on the client to cancel subscriptions on the service. It also releases retained handler
    /// blocks and clients.
    ///
    /// Specifically, this means that cancelling a subscription watcher will not invoke `statusChangeHandler` or
    /// `resultHandler`, although it will set the internal state of the watcher to `.disconnected`
    public func cancel() {
        if self.cancellationSource == .none {
            self.cancellationSource = .user
        }
        performCleanUpTasksOnCancel()
    }
    
    internal func performCleanUpTasksOnCancel() {
        isCancelled = true
        status = .disconnected
        resultHandler = nil
        statusChangeHandler = nil

        if self.cancellationSource != .error, let item = subscriptionItem {
            connection?.unsubscribe(item: item)
        }
        connection = nil
    }

}
