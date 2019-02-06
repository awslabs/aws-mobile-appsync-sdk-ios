//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Dispatch
import os.log

@objc protocol MQTTSubscriptionWatcher: AnyObject {
    func getIdentifier() -> Int
    func getTopics() -> [String]
    func messageCallbackDelegate(data: Data)
    func disconnectCallbackDelegate(error: Error)
    func connectedCallbackDelegate()
}

class SubscriptionsOrderHelper {
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
    
    weak var client: AppSyncMQTTClient?
    weak var httpClient: AWSNetworkTransport?
    var subscription: Subscription?
    let handlerQueue: DispatchQueue
    var resultHandler: SubscriptionResultHandler<Subscription>?
    var connectedCallback: (() -> Void)?
    internal var subscriptionTopic: [String]?
    let store: ApolloStore
    public let uniqueIdentifier = SubscriptionsOrderHelper.sharedInstance.getLatestCount()
    internal var isCancelled: Bool = false
    
    init(client: AppSyncMQTTClient, httpClient: AWSNetworkTransport, store: ApolloStore, subscriptionsQueue: DispatchQueue, subscription: Subscription, handlerQueue: DispatchQueue, connectedCallback: (() -> Void)? = nil, resultHandler: @escaping SubscriptionResultHandler<Subscription>) {
        self.client = client
        self.httpClient = httpClient
        self.store = store
        self.subscription = subscription
        self.handlerQueue = handlerQueue
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
        
        self.performSubscriptionRequest(completionHandler: { [weak self] (success, error) in
            if let error = error {
                self?.resultHandler?(nil, nil, error)
            }
            semaphore.signal()
        })
        
        semaphore.wait()
    }
    
    private func performSubscriptionRequest(completionHandler: @escaping (Bool, Error?) -> Void) {
        do {
            _ = try self.httpClient?.sendSubscriptionRequest(operation: subscription!, completionHandler: {[weak self] (response, error) in
                guard let self = self else {return}
                guard self.isCancelled == false else {return}
                if let response = response {
                    do {
                        let subscriptionResult = try AWSGraphQLSubscriptionResponseParser(body: response).parseResult()
                        if let subscriptionInfo = subscriptionResult.subscriptionInfo {
                            self.subscriptionTopic = subscriptionResult.newTopics
                            self.client?.addWatcher(watcher: self, topics: subscriptionResult.newTopics!, identifier: self.uniqueIdentifier)
                            self.client?.startSubscriptions(subscriptionInfo: subscriptionInfo, identifier: self.uniqueIdentifier.description)
                        }
                        completionHandler(true, nil)
                    } catch {
                        completionHandler(false, AWSAppSyncSubscriptionError(additionalInfo: error.localizedDescription, errorDetails: nil))
                    }
                } else if let error = error {
                    completionHandler(false, AWSAppSyncSubscriptionError(additionalInfo: error.localizedDescription, errorDetails: nil))
                }
            })
        } catch {
            completionHandler(false, AWSAppSyncSubscriptionError(additionalInfo: error.localizedDescription, errorDetails: nil))
        }
    }
    
    func getTopics() -> [String] {
        return subscriptionTopic ?? [String]()
    }
    
    func disconnectCallbackDelegate(error: Error) {
        self.resultHandler?(nil, nil, error)
    }
    
    func connectedCallbackDelegate() {
        AppSyncLog.debug("DS: connectedCallback attempted. connected callback is null: \(connectedCallback == nil)")
        connectedCallback?()
    }
    
    func messageCallbackDelegate(data: Data) {
        do {
            AppSyncLog.verbose("Received message in messageCallbackDelegate")
            
            guard String(data: data, encoding: .utf8) != nil else {
                AppSyncLog.error("Unable to convert message data to String using UTF8 encoding")
                AppSyncLog.debug("Message data is [\(data)]")
                return
            }
           
            guard let jsonObject = try JSONSerializationFormat.deserialize(data: data) as? JSONObject else {
                AppSyncLog.error("Unable to deserialize message data")
                AppSyncLog.debug("Message data is [\(data)]")
                return
            }
            
            let response = GraphQLResponse(operation: subscription!, body: jsonObject)
            
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
                    self.resultHandler?(nil, nil, error)
            }
        } catch {
            self.resultHandler?(nil, nil, error)
        }
    }
    
    deinit {
        // call cancel here before exiting
        cancel()
    }    
    
    /// Cancel any in progress fetching operations and unsubscribe from the messages.
    public func cancel() {
        self.isCancelled = true
        client?.stopSubscription(subscription: self, subscriptionId: uniqueIdentifier.description)
        self.client = nil
        self.httpClient = nil
        self.resultHandler = nil
        self.subscriptionTopic = nil
        self.subscription = nil
    }
}
