//
// Copyright 2010-2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//

import Dispatch
import os.log

public enum SubscritionWatcherStatus {
    case authenticating
    case authenticated
    case connecting
    case connected
    case disconnected
    case connectionRefused
    case connectionError
    case protocolError
    case requestFailed(Error)
}

protocol MQTTSubscritionWatcher: class {
    var status: SubscritionWatcherStatus { get set }
    func getTopics() -> [String]
    func messageCallbackDelegate(data: Data)
    func statusDidChangeDelegate(status: SubscritionWatcherStatus)
    
    @available(*, deprecated)
    func getIdentifier() -> Int
}

/// A `AWSAppSyncSubscriptionWatcher` is responsible for watching the subscription, and calling the result handler with a new result whenever any of the data is published on the MQTT topic. It also normalizes the cache before giving the callback to customer.
public final class AWSAppSyncSubscriptionWatcher<Subscription: GraphQLSubscription>: MQTTSubscritionWatcher, Cancellable {
    
    weak var client: AppSyncMQTTClient?
    weak var httpClient: AWSNetworkTransport?
    let subscription: Subscription?
    let handlerQueue: DispatchQueue
    let resultHandler: SubscriptionResultHandler<Subscription>
    let statusObserver: SubscriptionStatusObserver?
    internal var subscriptionTopic: [String]?
    let store: ApolloStore
    @available(*, deprecated)
    public var uniqueIdentifier: Int {
        return internalUniqueIdentifier
    }
    private let internalUniqueIdentifier = UUID().hashValue
    var status: SubscritionWatcherStatus = .authenticating {
        didSet {
            self.statusObserver?(status)
            self.reportErrorIfNeeded()
        }
    }
    
    init(client: AppSyncMQTTClient,
         httpClient: AWSNetworkTransport,
         store: ApolloStore,
         subscriptionsQueue: DispatchQueue,
         subscription: Subscription,
         handlerQueue: DispatchQueue,
         resultHandler: @escaping SubscriptionResultHandler<Subscription>,
         statusObserver: SubscriptionStatusObserver? = nil) {
        self.client = client
        self.httpClient = httpClient
        self.store = store
        self.subscription = subscription
        self.handlerQueue = handlerQueue
        self.resultHandler = { (result, transaction, error) in
            handlerQueue.async {
                resultHandler(result, transaction, error)
            }
        }
        if let statusObserver = statusObserver {
            self.statusObserver = { (status) in
                handlerQueue.async {
                    statusObserver(status)
                }
            }
        } else {
            self.statusObserver = nil
        }
        subscriptionsQueue.async { [weak self] in
            self?.startSubscription()
        }
    }
    
    func getIdentifier() -> Int {
        return internalUniqueIdentifier
    }
    
    private func startSubscription()  {
        let semaphore = DispatchSemaphore(value: 0)
        
        self.performSubscriptionRequest(completionHandler: { [weak self] (success, error) in
            if let error = error {
                self?.status = .requestFailed(error)
            }
            semaphore.signal()
        })
        
        semaphore.wait()
    }
    
    private func performSubscriptionRequest(completionHandler: @escaping (Bool, Error?) -> Void) {
        do {
            let _ = try self.httpClient?.sendSubscriptionRequest(operation: subscription!, completionHandler: { (response, error) in
                if let response = response {
                    do {
                        let subscriptionResult = try AWSGraphQLSubscriptionResponseParser(body: response).parseResult()
                        if let subscriptionInfo = subscriptionResult.subscriptionInfo {
                            self.subscriptionTopic = subscriptionResult.newTopics
                            self.client?.addWatcher(watcher: self, topics: subscriptionResult.newTopics!)
                            self.client?.startSubscriptions(subscriptionInfo: subscriptionInfo)
                        }
                        completionHandler(true, nil)
                    } catch {
                        completionHandler(false, error)
                    }
                } else if let error = error {
                    completionHandler(false, error)
                }
            })
        } catch {
            completionHandler(false, error)
        }
    }
    
    func getTopics() -> [String] {
        return subscriptionTopic ?? [String]()
    }
    
    func messageCallbackDelegate(data: Data) {
        do {
            AppSyncLog.verbose("Received message in messageCallbackDelegate")
            
            guard let _ = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
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
                    let _ = self.store.withinReadWriteTransaction { transaction in
                        self.resultHandler(result, transaction, nil)
                    }
                    
                    if let records = records {
                        self.store.publish(records: records, context: nil).catch { error in
                            preconditionFailure(String(describing: error))
                        }
                    }
                }.catch { error in
                    self.resultHandler(nil, nil, AWSAppSyncSubscriptionError.parseError(error))
            }
        } catch {
            self.resultHandler(nil, nil, AWSAppSyncSubscriptionError.parseError(error))
        }
    }
    
    func statusDidChangeDelegate(status: SubscritionWatcherStatus) {
        self.status = status
    }
    
    private func reportErrorIfNeeded() {
        switch self.status {
        case .authenticating, .authenticated, .connecting, .connected:
            break
        case .connectionRefused:
            self.resultHandler(nil, nil, AWSAppSyncSubscriptionError.connectionRefused)
        case .connectionError:
            self.resultHandler(nil, nil, AWSAppSyncSubscriptionError.connectionError)
        case .protocolError:
            self.resultHandler(nil, nil, AWSAppSyncSubscriptionError.protocolError)
        case .requestFailed(let error):
            self.resultHandler(nil, nil, AWSAppSyncSubscriptionError.requestFailed(error))
        case .disconnected:
            self.resultHandler(nil, nil, AWSAppSyncSubscriptionError.disconnected)
        }
    }
    
    deinit {
        // call cancel here before exiting
        cancel()
    }    
    
    /// Cancel any in progress fetching operations and unsubscribe from the messages.
    public func cancel() {
        client?.stopSubscription(subscription: self)
    }
}

