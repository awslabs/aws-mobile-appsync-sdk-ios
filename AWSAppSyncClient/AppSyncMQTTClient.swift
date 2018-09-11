//
//  AppSyncMQTTClient.swift
//  AWSAppSync
//

import Foundation

class AppSyncMQTTClient: AWSIoTMQTTClientDelegate {
    
    var mqttClients = Set<AWSIoTMQTTClient<AnyObject, AnyObject>>()
    var mqttClientsWithTopics = [AWSIoTMQTTClient<AnyObject, AnyObject>: Set<String>]()
    var topicSubscribers = TopicSubscribers()
    var allowCellularAccess = true
    var scheduledSubscription: DispatchSourceTimer?
    var subscriptionsQueue = DispatchQueue.global(qos: .userInitiated)
    
    func receivedMessageData(_ data: Data!, onTopic topic: String!) {
        self.subscriptionsQueue.async { [weak self] in
            guard let `self` = self, let topics = self.topicSubscribers[topic] else {
                return
            }
            
            for subscribedTopic in topics {
                subscribedTopic.messageCallbackDelegate(data: data)
            }
        }
    }
    
    func connectionStatusChanged(_ status: AWSIoTMQTTStatus, client mqttClient: AWSIoTMQTTClient<AnyObject, AnyObject>) {
        self.subscriptionsQueue.async { [weak self] in
            guard let `self` = self, let topics = self.mqttClientsWithTopics[mqttClient] else {
                return
            }
            
            if status.rawValue == 2 {
                for topic in topics {
                    mqttClient.subscribe(toTopic: topic, qos: 1, extendedCallback: nil)
                }
            } else if status.rawValue >= 3  {
                let error = AWSAppSyncSubscriptionError(additionalInfo: "Subscription Terminated.", errorDetails:  [
                    "recoverySuggestion" : "Restart subscription request.",
                    "failureReason" : "Disconnected from service."])
                
                topics.map({ self.topicSubscribers[$0] })
                      .flatMap({$0})
                      .flatMap({$0})
                      .forEach({$0.disconnectCallbackDelegate(error: error)})
            }
        }
    }
    
    func addWatcher(watcher: MQTTSubscritionWatcher, topics: [String], identifier: Int) {
        topicSubscribers.add(watcher: watcher, topics: topics)
    }
    
    func startSubscriptions(subscriptionInfo: [AWSSubscriptionInfo]) {
        func createTimer(_ interval: Int, queue: DispatchQueue, block: @escaping () -> Void ) -> DispatchSourceTimer {
            let timer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: 0), queue: queue)
            #if swift(>=4)
            timer.schedule(deadline: .now() + .seconds(interval))
            #else
            timer.scheduleOneshot(deadline: .now() + .seconds(interval))
            #endif
            timer.setEventHandler(handler: block)
            timer.resume()
            return timer
        }
        
        self.scheduledSubscription = createTimer(1, queue: subscriptionsQueue, block: { [weak self] in
            self?.resetAndStartSubscriptions(subscriptionInfo: subscriptionInfo)
        })
    }
    
    private func resetAndStartSubscriptions(subscriptionInfo: [AWSSubscriptionInfo]){
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
    
    private func startNewSubscription(subscriptionInfo: AWSSubscriptionInfo) {
        let interestedTopics = subscriptionInfo.topics.filter({ topicSubscribers[$0] != nil })
        
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
        self.topicSubscribers.remove(subscription: subscription)

        self.subscriptionsQueue.async { [weak self] in

            guard let `self` = self else {
                return
            }
            
            self.topicSubscribers.cleanUp(topicRemovedHandler: self.unsubscribeTopic)

            for (client, _) in self.mqttClientsWithTopics.filter({ $0.value.isEmpty }) {
                client.disconnect()
                self.mqttClientsWithTopics[client] = nil
                self.mqttClients.remove(client)
            }
        }
    }
    
    /// Unsubscribe topic
    ///
    /// - Parameter topic: String
    private func unsubscribeTopic(topic: String) {
        for (client, _)  in mqttClientsWithTopics.filter({ $0.value.contains(topic) }) {
            switch client.mqttStatus {
            case .connecting, .connected, .connectionError, .connectionRefused, .protocolError:
                client.unsubscribeTopic(topic)
            case .disconnected, .unknown:
                break
            }
            mqttClientsWithTopics[client]?.remove(topic)
        }
    }
    
    class TopicSubscribers {
        
        private var dictionary = [String : NSHashTable<MQTTSubscritionWatcher>]()
        
        private var lock = NSLock()
        
        subscript(key: String) -> [MQTTSubscritionWatcher]? {
            get {
                return synchronized() {
                    return self.dictionary[key]?.allObjects
                }
            }
        }
        
        func add(watcher: MQTTSubscritionWatcher, topics: [String]) {
            synchronized() {
                for topic in topics {
                    if let watchers = self.dictionary[topic] {
                        watchers.add(watcher)
                    } else {
                        let watchers = NSHashTable<MQTTSubscritionWatcher>.weakObjects()
                        watchers.add(watcher)
                        self.dictionary[topic] = watchers
                    }
                }
            }
        }
        
        func remove(subscription: MQTTSubscritionWatcher) {
            synchronized() {
                dictionary.forEach({ (element) in
                    element.value.allObjects.filter({ $0.getIdentifier() == subscription.getIdentifier() }).forEach({ (watcher) in
                        element.value.remove(watcher)
                    })
                })
            }
        }
        
        func cleanUp(topicRemovedHandler:(String) -> Void) {
            let unusedTopics: [String] = synchronized() {
                let unusedTopics = dictionary.filter({ $0.value.allObjects.isEmpty })
                                             .map({ $0.key })
                unusedTopics.forEach({
                    dictionary.removeValue(forKey: $0)
                })
                
                return unusedTopics
            }
            unusedTopics.forEach(topicRemovedHandler)
        }
        
        func synchronized<T>(_ body: () throws -> T) rethrows -> T {
            lock.lock()
            defer { lock.unlock() }
            return try body()
        }
    }
}
