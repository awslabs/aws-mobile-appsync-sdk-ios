//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Dispatch
import os.log

/// A protocol to allow our Swift AWSAppSyncSubscriptionWatcher class to be referenced by the Objective-C
/// AWSIoTMQTTClient.
@objc protocol MQTTSubscriptionWatcher {
    func getIdentifier() -> Int

    func getTopics() -> [String]

    func messageCallbackDelegate(data: Data)

    func disconnectCallbackDelegate(error: Error)

    func connectedCallbackDelegate()

    func statusChangeDelegate(status: AWSIoTMQTTStatus)

    func subscriptionAcknowledgementDelegate()
}

private class SubscriptionsOrderHelper {
    var count = 0
    var previousCall = Date()
    var pendingCount = 0
    var dispatchLock = DispatchQueue(label: "SubscriptionsQueue")
    var waitDictionary = [0: true]
    static let sharedInstance = SubscriptionsOrderHelper()
    
    func getLatestCount() -> Int {
        count += 1
        waitDictionary[count] = false
        return count
    }
    
    func markDone(id: Int) {
        waitDictionary[id] = true
    }
    
    func shouldWait(id: Int) -> Bool {
        for i in 0..<id where waitDictionary[i] == false {
            return true
        }
        return false
    }
    
}

/// A `AWSAppSyncSubscriptionWatcher` is responsible for watching the subscription, and calling the result handler with a new result whenever any of the data is published on the MQTT topic. It also normalizes the cache before giving the callback to customer.
public final class AWSAppSyncSubscriptionWatcher<Subscription: GraphQLSubscription>: MQTTSubscriptionWatcher, Cancellable {

    private weak var client: AppSyncMQTTClient?
    private weak var httpClient: AWSNetworkTransport?
    private let subscription: Subscription
    private let handlerQueue: DispatchQueue
    private var resultHandler: SubscriptionResultHandler<Subscription>?
    private var connectedCallback: (() -> Void)?
    private var statusChangeHandler: SubscriptionStatusChangeHandler?
    private let store: ApolloStore
    private var isCancelled: Bool = false
    private var subscriptionTopic: [String]?

    private let uniqueIdentifier = SubscriptionsOrderHelper.sharedInstance.getLatestCount()
    private var status = AWSAppSyncSubscriptionWatcherStatus.connecting

    init(client: AppSyncMQTTClient,
         httpClient: AWSNetworkTransport,
         store: ApolloStore,
         subscriptionsQueue: DispatchQueue,
         subscription: Subscription,
         handlerQueue: DispatchQueue,
         statusChangeHandler: SubscriptionStatusChangeHandler? = nil,
         connectedCallback: (() -> Void)? = nil,
         resultHandler: @escaping SubscriptionResultHandler<Subscription>) {
        AppSyncLog.verbose("Subscribing to operation \(subscription)")
        self.client = client
        self.httpClient = httpClient
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
    
    func getIdentifier() -> Int {
        return uniqueIdentifier
    }
    
    private func startSubscription() {
        let semaphore = DispatchSemaphore(value: 0)
        
        performSubscriptionRequest(completionHandler: { [weak self] (success, error) in
            if let error = error {
                self?.resultHandler?(nil, nil, error)
            }
            semaphore.signal()
        })
        
        semaphore.wait()
    }

    private func performSubscriptionRequest(completionHandler: @escaping (Bool, Error?) -> Void) {
        do {
            _ = try httpClient?.sendSubscriptionRequest(operation: subscription, completionHandler: {[weak self] (response, error) in
                AppSyncLog.debug("Received AWSGraphQLSubscriptionResponse")

                guard let self = self else {
                    return
                }

                guard self.isCancelled == false else {
                    return
                }

                guard error == nil else {
                    AppSyncLog.error("Unexpected error in subscription request: \(error!)")
                    completionHandler(false, AWSAppSyncSubscriptionError.setupError(error!.localizedDescription))
                    return
                }

                guard let response = response else {
                    let message = "Response unexpectedly nil subscribing \(self.getIdentifier())"
                    AppSyncLog.error(message)
                    let error = AWSAppSyncSubscriptionError.setupError(message)
                    completionHandler(false, error)
                    return
                }

                let subscriptionResult: AWSGraphQLSubscriptionResponse
                do {
                    subscriptionResult = try AWSGraphQLSubscriptionResponseParser(body: response).parseResult()
                } catch {
                    AppSyncLog.error("Error parsing subscription result: \(error)")
                    completionHandler(false, AWSAppSyncSubscriptionError.setupError(error.localizedDescription))
                    return
                }

                guard let subscriptionInfo = subscriptionResult.subscriptionInfo else {
                    let message = "Subscription info unexpectedly nil in subscription result \(self.getIdentifier())"
                    AppSyncLog.error(message)
                    let error = AWSAppSyncSubscriptionError.setupError(message)
                    completionHandler(false, error)
                    return
                }

                AppSyncLog.verbose("New subscription set: \(subscriptionInfo.count)")

                self.subscriptionTopic = subscriptionResult.newTopics
                AppSyncLog.debug("Subscription watcher \(self.getIdentifier()) now watching topics: \(self.subscriptionTopic ?? [])")

                self.client?.add(watcher: self, forNewTopics: subscriptionResult.newTopics!)

                self.client?.startSubscriptions(subscriptionInfos: subscriptionInfo, identifier: self.uniqueIdentifier)

                completionHandler(true, nil)
            })
        } catch {
            AppSyncLog.error("Error performing subscription request: \(error)")
            completionHandler(false, AWSAppSyncSubscriptionError.setupError(error.localizedDescription))
        }
    }
    
    func getTopics() -> [String] {
        return subscriptionTopic ?? [String]()
    }

    deinit {
        // call cancel here before exiting
        cancel()
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
        isCancelled = true
        status = .disconnected
        client?.cancelSubscription(for: self)
        client = nil
        httpClient = nil
        resultHandler = nil
        statusChangeHandler = nil
        subscriptionTopic = nil
    }

    // MARK: - MQTTSubscriptionWatcher

    func disconnectCallbackDelegate(error: Error) {
        self.resultHandler?(nil, nil, error)
    }

    func connectedCallbackDelegate() {
        AppSyncLog.debug("MQTT connectedCallback \(connectedCallback == nil ? "" : "(callback is null)")")
        connectedCallback?()
    }

    func messageCallbackDelegate(data: Data) {
        do {
            AppSyncLog.debug("Received message")
            AppSyncLog.verbose("First 128 bytes of message data is [\(data.prefix(upTo: 128))]")

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

    /// The watcher has received a status update for the underlying MQTT client. This method will translate the incoming
    /// status
    ///
    /// - Parameter status: The new AWSIoTMQTTStatus. This will be resolved to a AWSAppSyncSubscriptionStatus and trigger the notification handler
    func statusChangeDelegate(status: AWSIoTMQTTStatus) {
        let subscriptionWatcherStatus = status.toSubscriptionWatcherStatus
        statusChangeHandler?(subscriptionWatcherStatus)
    }

    /// The underlying client has received a subscription acknowledgement from the broker. This means the watcher is now
    /// receiving subscriptions. This is the only code path that can set the status to `.connected`.
    func subscriptionAcknowledgementDelegate() {
        guard !isCancelled else {
            return
        }

        status = .connected
        statusChangeHandler?(status)
    }

}
