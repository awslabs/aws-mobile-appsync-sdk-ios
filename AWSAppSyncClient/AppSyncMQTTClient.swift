//
//  AppSyncMQTTClient.swift
//  AWSAppSync
//

import Foundation
import Reachability

class AppSyncMQTTClient: MQTTClientDelegate {
    
    var mqttClient = MQTTClient<AnyObject, AnyObject>()
    var mqttClients = [MQTTClient<AnyObject, AnyObject>]()
    var mqttClientsWithTopics = [MQTTClient<AnyObject, AnyObject>: [String]]()
    var reachability: Reachability?
    var hostURL: String?
    var clientId: String?
    var topicSubscribersDictionary = [String: [MQTTSubscritionWatcher]]()
    var topicQueue = NSMutableSet()
    var initialConnection = true
    var shouldSubscribe = true
    var allowCellularAccess = true
    var shouldReconnect = false
    var previousAttempt: Date = Date()
   
    init() {
        self.mqttClient.clientDelegate = self
    }
    
    func receivedMessageData(_ data: Data!, onTopic topic: String!) {
        let topics = topicSubscribersDictionary[topic]
        for subscribedTopic in topics! {
            subscribedTopic.messageCallbackDelegate(data: data)
        }
    }
    
    func connectionStatusChanged(_ status: MQTTStatus, client mqttClient: MQTTClient<AnyObject, AnyObject>) {
        if status.rawValue == 2 {
            for topic in mqttClientsWithTopics[mqttClient]! {
                mqttClient.subscribe(toTopic: topic, qos: 1, extendedCallback: nil)
            }
            self.topicQueue = NSMutableSet()
        } else if status.rawValue >= 3  {
            for topic in mqttClientsWithTopics[mqttClient]! {
                let subscribers = topicSubscribersDictionary[topic]
                for subscriber in subscribers! {
                    let error = AWSAppSyncSubscriptionError(additionalInfo: "Subscription Terminated.", errorDetails:  [
                        "recoverySuggestion" : "Restart subscription request.",
                        "failureReason" : "Disconnected from service."])
                    
                    subscriber.disconnectCallbackDelegate(error: error)
                }
            }
        }
    }
    
    func addWatcher(watcher: MQTTSubscritionWatcher, topics: [String], identifier: Int) {
        for topic in topics {
            if var topicsDict = self.topicSubscribersDictionary[topic] {
                topicsDict.append(watcher)
                self.topicSubscribersDictionary[topic] = topicsDict
            } else {
                self.topicSubscribersDictionary[topic] = [watcher]
            }
        }
    }
    
    func startSubscriptions(subscriptionInfo: [AWSSubscriptionInfo]) {
        for client in mqttClients {
            client.clientDelegate = nil
            client.disconnect()
        }
        mqttClients = []
        mqttClientsWithTopics = [:]
        
        for subscription in subscriptionInfo {
            startNewSubscription(subscriptionInfo: subscription)
        }
    }
    
    func startNewSubscription(subscriptionInfo: AWSSubscriptionInfo) {
        var topicQueue = [String]()
        let mqttClient = MQTTClient<AnyObject, AnyObject>()
        mqttClient.clientDelegate = self
        for topic in subscriptionInfo.topics {
            if topicSubscribersDictionary[topic] != nil {
                // if the client wants subscriptions and is allowed we add it to list of subscribe
                topicQueue.append(topic)
            }
        }
        mqttClients.append(mqttClient)
        mqttClientsWithTopics[mqttClient] = topicQueue
        mqttClient.connect(withClientId: subscriptionInfo.clientId, toHost: subscriptionInfo.url, statusCallback: nil)
    }

    public func stopSubscription(subscription: MQTTSubscritionWatcher) {
        
        topicSubscribersDictionary = updatedDictionary(topicSubscribersDictionary, usingCancelling: subscription)
        
        topicSubscribersDictionary.filter({ $0.value.isEmpty })
                                  .map({ $0.key })
                                  .forEach(unsubscribeTopic)
    }
    
    
    /// Returnes updated dictionary
    /// it removes subscriber from the array
    ///
    /// - Parameters:
    ///   - dictionary: [String: [MQTTSubscritionWatcher]]
    ///   - subscription: MQTTSubscritionWatcher
    /// - Returns: [String: [MQTTSubscritionWatcher]]
    private func updatedDictionary(_ dictionary: [String: [MQTTSubscritionWatcher]] ,
                                   usingCancelling subscription: MQTTSubscritionWatcher) -> [String: [MQTTSubscritionWatcher]] {
        
        return topicSubscribersDictionary.reduce(into: [:]) { (result, element) in
            result[element.key] = removedSubscriber(array: element.value, of: subscription.getIdentifier())
        }
    }
    
    
    
    /// Unsubscribe topic
    ///
    /// - Parameter topic: String
    private func unsubscribeTopic(topic: String) {
        mqttClientsWithTopics.filter({ $0.value.contains(topic) })
                             .forEach({ $0.key.unsubscribeTopic(topic) })
    }
    
    /// Removes subscriber from the array using id
    ///
    /// - Parameters:
    ///   - array: [MQTTSubscritionWatcher]
    ///   - id: Int
    /// - Returns: updated array [MQTTSubscritionWatcher]
    private func removedSubscriber(array: [MQTTSubscritionWatcher], of id: Int) -> [MQTTSubscritionWatcher] {
        return array.filter({$0.getIdentifier() != id })
    }
}
