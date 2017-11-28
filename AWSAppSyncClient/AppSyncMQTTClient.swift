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
        // This function should unsusbscribe from a topic ONLY if its the only watcher on a topic,
        // else this function should only remove the completion handler callback
        for topic in subscription.getTopics() {
            //self.topicSubscribersDictionary[topic].remo
            if self.topicSubscribersDictionary[topic]!.count > 1 {
                // do nothing if there are other subscribers on the same topic, just remove from the array  of callbacks
                for i in 0..<self.topicSubscribersDictionary[topic]!.count {
                    if self.topicSubscribersDictionary[topic]![i].getIdentifier() == subscription.getIdentifier() {
                        // remove that watcher for no further notification
                        self.topicSubscribersDictionary[topic]!.remove(at: i)
                    }
                }
            } else {
                for client in mqttClientsWithTopics {
                    if client.value.contains(topic) {
                        client.key.unsubscribeTopic(topic)
                    }
                }
                // remove topic from dictionary if its the only subscriber
                self.topicSubscribersDictionary.removeValue(forKey: topic)
            }
        }
    }
}
