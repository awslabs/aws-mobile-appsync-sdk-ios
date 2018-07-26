//
//  AppSyncMQTTClient.swift
//  AWSAppSync
//

import Foundation
import Reachability

class AppSyncMQTTClient: AWSIoTMQTTClientDelegate {
    
    var mqttClient = AWSIoTMQTTClient<AnyObject, AnyObject>()
    var mqttClients = Set<AWSIoTMQTTClient<AnyObject, AnyObject>>()
    var mqttClientsWithTopics = [AWSIoTMQTTClient<AnyObject, AnyObject>: Set<String>]()
    var reachability: Reachability?
    var hostURL: String?
    var clientId: String?
    var topicSubscribersDictionary = [String: [MQTTSubscritionWatcher]]()
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
    
    func connectionStatusChanged(_ status: AWSIoTMQTTStatus, client mqttClient: AWSIoTMQTTClient<AnyObject, AnyObject>) {
        if status.rawValue == 2 {
            for topic in mqttClientsWithTopics[mqttClient]! {
                mqttClient.subscribe(toTopic: topic, qos: 1, extendedCallback: nil)
            }
        } else if status.rawValue >= 3  {
            guard mqttClientsWithTopics[mqttClient] != nil else {return}
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
        mqttClients.removeAll()
        mqttClientsWithTopics.removeAll()
        
        for subscription in subscriptionInfo {
            startNewSubscription(subscriptionInfo: subscription)
        }
    }
    
    func startNewSubscription(subscriptionInfo: AWSSubscriptionInfo) {
        let interestedTopics = subscriptionInfo.topics.filter({ topicSubscribersDictionary[$0] != nil })
        
        guard !interestedTopics.isEmpty else {
            return
        }
        
        let mqttClient = AWSIoTMQTTClient<AnyObject, AnyObject>()
        mqttClient.clientDelegate = self
        
        mqttClients.insert(mqttClient)
        mqttClientsWithTopics[mqttClient] = Set(interestedTopics)
        
        mqttClient.connect(withClientId: subscriptionInfo.clientId, presignedURL: subscriptionInfo.url, statusCallback: nil)
    }

    public func stopSubscription(subscription: MQTTSubscritionWatcher) {
        
        topicSubscribersDictionary = updatedDictionary(topicSubscribersDictionary, usingCancelling: subscription)
        
        topicSubscribersDictionary.filter({ $0.value.isEmpty })
                                  .map({ $0.key })
                                  .forEach(unsubscribeTopic)
        
        for (client, _) in mqttClientsWithTopics.filter({ $0.value.isEmpty }) {
            DispatchQueue.global(qos: .userInitiated).async {
                client.disconnect()
            }
            mqttClientsWithTopics[client] = nil
            mqttClients.remove(client)
        }
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
        for (client, _)  in mqttClientsWithTopics.filter({ $0.value.contains(topic) }) {
            client.unsubscribeTopic(topic)
            mqttClientsWithTopics[client]?.remove(topic)
        }
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
