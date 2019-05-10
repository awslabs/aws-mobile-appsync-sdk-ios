//
//  AppSyncMQTTClient.swift
//  AWSAppSync
//

import Foundation

/// A class that manages the associations amongst individual AWSIoTMQTTClients, their associated topics, and
/// the watchers that have registered subscriptions for those topics. This class is thread safe.
class AppSyncMQTTClient: AWSIoTMQTTClientDelegate {

    /// Queue for synchronizing state
    private let concurrencyQueue = DispatchQueue(label: "com.amazonaws.AppSyncMQTTClient.concurrencyQueue", attributes: .concurrent)

    /// A set of subscriptions that have been requested to be stopped. Any future actions on them will be ignored.
    var cancelledSubscriptions = [Int: Bool]()

    /// A timer to start a subscription in the near future
    private var scheduledSubscription: DispatchSourceTimer?

    /// The queue on which subscription callbacks (e.g., connected callbacks, data received callbacks) will be
    /// invoked.
    private var subscriptionsQueue = DispatchQueue.global(qos: .userInitiated)

    // Associations of topics to clients to watchers

    /// A map of MQTT clients to their associated topics
    var topicsByClient = [AWSIoTMQTTClient<AnyObject, AnyObject>: Set<String>]()

    /// MQTT clients that have been flagged for cancellation due to a reconnect, but are waiting to be released pending
    /// a subscription acknowledgement from the service
    private var expiringClientsByTopic = TopicWeakMap<AWSIoTMQTTClient<AnyObject, AnyObject>>()

    /// A map of topics to their associated watcher blocks
    private var subscribersByTopic = TopicWeakMap<MQTTSubscriptionWatcher>()

    /// Adds a subscription watcher for new topics. This does not actually subscribe to the topics or create
    /// a connection, it only registers interest in the topic
    ///
    /// - Parameters:
    ///   - watcher: The MQTTSubscriptionWatcher that will receive updates for the topics
    ///   - topics: The new topics to be watched
    func add(watcher: MQTTSubscriptionWatcher, forNewTopics topics: [String]) {
        concurrencyQueue.async(flags: .barrier) { [weak self] in
            self?.subscribersByTopic.add(watcher, forTopics: topics)
        }
    }

    /// Schedules subscription connection/reconnections to start for the specified AWSSubscriptionInfo objects. If the
    /// watcher with `identifier` has already been cancelled, no subscriptions will be restarted.
    ///
    /// Internally, this method schedules the subscription connection/reconnection after a brief delay. This is to
    /// allow the AppSync service to propagate some policy information to the PubSub broker, AWSIoT.
    ///
    /// When this method returns, the subscription is scheduled, but the client is not yet connected. The watcher
    /// will receive a connection state callback when the initial socket is connected.
    ///
    /// - Parameters:
    ///   - subscriptionInfos: An array of AWSSubscriptionInfo objects to be subscribed to.
    ///   - identifier: The watcher that has registered interest in at least one of the topics in the
    ///     `subscriptionInfo` array.
    func startSubscriptions(subscriptionInfos: [AWSSubscriptionInfo], identifier: Int) {
        AppSyncLog.debug("Starting new subscriptions for watcher \(identifier)")

        scheduledSubscription = DispatchSource.makeOneOffDispatchSourceTimer(interval: .seconds(1), queue: subscriptionsQueue) { [weak self] in
            self?.resetAndStartSubscriptions(subscriptionInfos: subscriptionInfos, identifier: identifier)
        }
        scheduledSubscription?.resume()
    }

    /// Establishes new connections for each specified `subscriptionInfo`, as long as the watcher with `identifer`
    /// has not yet been cancelled.
    ///
    /// Internally, this method:
    /// - Create a candidate list of clients to expire, associated with their topics
    /// - Start new subscriptions for the specified subscriptionInfo objects
    /// - For each topic in subscriptionInfos, retain the expiring client in `expiringClientsByTopic`
    /// - For each remaining client in the candidate list (in other words, clients that have no associated
    ///   topics), immediately cancel it since it is not associated with an active topic
    /// - When the subscription acknowledgement is received for a topic, cancel and disconnect the old client,
    ///   and remove it from the expiring client list
    ///
    /// - Parameters:
    ///   - subscriptionInfos: An array of AWSSubscriptionInfo objects to be subscribed to.
    ///   - identifier: The watcher that has registered interest in at least one of the topics in the
    ///     `subscriptionInfo` array.
    private func resetAndStartSubscriptions(subscriptionInfos: [AWSSubscriptionInfo], identifier: Int) {

        concurrencyQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else {
                return
            }

            AppSyncLog.debug("Starting \(subscriptionInfos.count) new clients; disconnecting \(self.topicsByClient.count) old clients")

            // Now that we've saved the old clients, clear the active clients. They will be repopulated during
            // the startNewConnection
            for (client, topics) in self.topicsByClient {
                self.expiringClientsByTopic.add(client, forTopics: Array(topics))
            }
            self.topicsByClient.removeAll()

            // If any of the new subscriptions are uncancelled, start new subscriptions before destroying
            // the old ones
            if self.shouldSubscribe(identifier: identifier) {
                for subscriptionInfo in subscriptionInfos {
                    self.startNewConnection(for: subscriptionInfo)
                }
            }
        }
    }

    /// Returns `false` if the given subscription identifier has been cancelled. `true` indicates the identifier
    /// is not cancelled and should be resubscribed.
    ///
    /// This method must be called from `concurrencyQueue`.
    ///
    /// - Parameter identifier: The subscription identifier
    /// - Returns: `true` if the identifier should be resubscribed; `false` otherwise
    private func shouldSubscribe(identifier: Int) -> Bool {
        if cancelledSubscriptions[identifier] != nil {
            cancelledSubscriptions[identifier] = true
            return false
        }
        return true
    }

    /// Start new subscriptions to the specified topics
    ///
    /// Internally, this method:
    /// - Creates a new, unconnected MQTTClient and assigns `self` as its delegate
    /// - Associates the client with the list of topics in `subscriptionInfo` that have a registered watcher
    /// - Calls `connect` on the client
    ///
    /// This method must be called from `concurrencyQueue`.
    ///
    /// - Parameter subscriptionInfo: The SubscriptionInfo that contains the list of topics, URL and client ID for
    ///   the subscription
    private func startNewConnection(for subscriptionInfo: AWSSubscriptionInfo) {
        let interestedTopics = subscriptionInfo.topics.filter { subscribersByTopic[$0] != nil }
        
        guard !interestedTopics.isEmpty else {
            return
        }
        
        let mqttClient = AWSIoTMQTTClient<AnyObject, AnyObject>()
        mqttClient.clientDelegate = self
        
        topicsByClient[mqttClient] = Set(interestedTopics)
        
        mqttClient.connect(withClientId: subscriptionInfo.clientId,
                           presignedURL: subscriptionInfo.url,
                           statusCallback: nil)
    }

    /// Cancels the subscriptions currently registered for `watcher`. If cancelling a subscription removes the
    /// last registered watcher for a given client connection, this method also disconnects the client.
    ///
    /// - Parameters:
    ///   - watcher: The watcher for which to cancel subscriptions
    func cancelSubscription(for watcher: MQTTSubscriptionWatcher, userOriginatedDisconnect: Bool) {
        let watcherId = watcher.getIdentifier()

        AppSyncLog.debug("Stopping watcher \(watcherId)")

        concurrencyQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else {
                AppSyncLog.verbose("### Unexpectedly no self in cancelSubscription")
                return
            }
            self.subscribersByTopic.remove { $0.getIdentifier() == watcherId }
            self.cancelledSubscriptions[watcherId] = false

            let unwatchedTopics = self.subscribersByTopic.removeUnassociatedTopics()
            // If the user issued disconnect on an active subscription, we notify the underlying
            // MQTT client to unsubscribe from the topic which was getting the messages.
            if userOriginatedDisconnect {
                unwatchedTopics.forEach(self.unsubscribeTopic)
            }
            
            // We clean up internal book keeping of topic-client since we do not need it anymore.
            unwatchedTopics.forEach(self.cleanUpMQTTClientMetadata(for:))

            let clientsWithNoTopics = self.removeClientsWithNoTopics()

            // Send the `disconnect` on the subscriptions queue since we don't need it for internal consistency
            self.subscriptionsQueue.async {
                clientsWithNoTopics.forEach { $0.disconnect() }
            }
        }
    }

    /// Removes clients with no topics from internal storage, and returns the clients so removed.
    ///
    /// This method must be called from `concurrencyQueue`.
    ///
    /// - Returns: An array of clients without topics that have been removed from internal storage
    private func removeClientsWithNoTopics() -> [AWSIoTMQTTClient<AnyObject, AnyObject>] {
        let clientsWithNoTopics = self.topicsByClient
            .filter { $0.value.isEmpty }
            .map { $0.key }

        for client in clientsWithNoTopics {
            self.topicsByClient.removeValue(forKey: client)
        }

        return clientsWithNoTopics
    }

    /// Invokes `unsubscribeTopic` on the MQTTClient associated with `topic`, and removes the topic from the list
    /// of registered topics for that client.
    ///
    /// This method must be called from `concurrencyQueue`.
    ///
    /// - Parameter topic: String
    private func unsubscribeTopic(topic: String) {
        for (client, _) in topicsByClient.filter({ $0.value.contains(topic) }) {
            switch client.mqttStatus {
            case .connecting, .connected, .connectionError, .connectionRefused, .protocolError:
                client.unsubscribeTopic(topic)
            case .disconnected, .unknown:
                break
            }
        }
    }
    
    /// Cleans up internal book keeping where we hold the topic-client mapping.
    /// This method must be called from `concurrencyQueue`.
    ///
    /// - Parameter topic: String
    private func cleanUpMQTTClientMetadata(for topic: String) {
        for (client, _) in topicsByClient.filter({ $0.value.contains(topic) }) {
            topicsByClient[client]?.remove(topic)
        }
    }
    
    // MARK: - AWSIoTMQTTClientDelegate

    /// Notifies subscribers' `messageCallbackDelegate`s of incoming data on the specified topic
    ///
    /// - Parameters:
    ///   - data: The data received on the topic
    ///   - topic: The topic receiving the data
    func receivedMessageData(_ data: Data!, onTopic topic: String!) {
        concurrencyQueue.sync {
            guard let subscribers = subscribersByTopic[topic] else {
                return
            }

            subscriptionsQueue.async {
                for subscriber in subscribers {
                    subscriber.messageCallbackDelegate(data: data)
                }
            }
        }
    }

    /// Notifies subscribers of a status change on `mqttClient`'s connection
    ///
    /// - Parameters:
    ///   - status: The new status of the client
    ///   - mqttClient: The client affected by the status change
    func connectionStatusChanged(_ status: AWSIoTMQTTStatus, client mqttClient: AWSIoTMQTTClient<AnyObject, AnyObject>) {
        AppSyncLog.debug("\(mqttClient.clientId ?? "(no clientId)"): \(status)")
        concurrencyQueue.sync {
            notifyStatusCallbackDelegates(for: mqttClient, ofNewStatus: status)

            switch status {
            case .connecting:
                break
            case .connected:
                subscribeToTopicsAndNotifyConnectedCallbackDelegates(for: mqttClient)
            default:
                notifyDisconnectCallbackDelegates(for: mqttClient, ofNewStatus: status)
            }
        }
    }

    /// Notifies watchers of a status change in its underlying client. Because of the mapping between subscription
    /// watchers, topics and clients, a status change on a single client may alert multiple subscription watchers
    /// of the same status event.
    ///
    /// This method must be called from `concurrencyQueue`.
    ///
    /// - Parameters:
    /// - Parameter mqttClient: The client that received the status update
    ///   - status: The new status
    private func notifyStatusCallbackDelegates(for mqttClient: AWSIoTMQTTClient<AnyObject, AnyObject>,
                                               ofNewStatus status: AWSIoTMQTTStatus) {
        guard let topics = topicsByClient[mqttClient], !topics.isEmpty else {
            return
        }

        let subscribers = subscribersByTopic.elements(for: topics)

        subscriptionsQueue.async {
            subscribers.forEach { $0.statusChangeDelegate(status: status) }
        }
    }

    /// Subscribes to the topics registered as with `mqttClient`, and notifies connected callback delegates that
    /// the client is now connected.
    ///
    /// **NOTE**: A connection notification does not mean that the client is receiving subscription messages, only
    /// that the initial connection to the broker is established. Delegates that need to know when a watcher is actually
    /// ready to receive messages should create a subscription watcher with a status callback.
    ///
    /// This method must be called from `concurrencyQueue`.
    ///
    /// - Parameter mqttClient: The client being subscribed
    private func subscribeToTopicsAndNotifyConnectedCallbackDelegates(for mqttClient: AWSIoTMQTTClient<AnyObject, AnyObject>) {
        guard let topics = topicsByClient[mqttClient], !topics.isEmpty else {
            return
        }
        for topic in topics {
            let ackCallback: () -> Void = { [weak self] in
                self?.handleSubscriptionAcknowledgement(for: topic)
            }

            mqttClient.subscribe(toTopic: topic, qos: 1, extendedCallback: nil, ackCallback: ackCallback)
        }

        let subscribers = subscribersByTopic.elements(for: topics)

        subscriptionsQueue.async {
            subscribers.forEach { $0.connectedCallbackDelegate() }
        }
    }

    /// When we get a subscription acknowledgement:
    /// - Clear the client delegate for any expiring client associated with that topic
    /// - Disconnect expiring client
    /// - Remove our reference to the expired client in all topics

    private func handleSubscriptionAcknowledgement(for topic: String) {
        AppSyncLog.debug("Topic has been subscribed \(topic)")

        clearTopicFromExpiredClientsAndCleanup(topic: topic)

        let subscribers = subscribersByTopic.elements(for: [topic])

        guard !subscribers.isEmpty else {
            return
        }

        subscriptionsQueue.async {
            subscribers.forEach { $0.subscriptionAcknowledgementDelegate() }
        }

    }

    /// Removes MQTT clients that have been flagged as expired, and whose topics are handled by another client
    
    private func clearTopicFromExpiredClientsAndCleanup(topic: String) {
        concurrencyQueue.async(flags: .barrier) {
            guard let expiringClients = self.expiringClientsByTopic[topic] else {
                return
            }

            for client in expiringClients {
                client.clientDelegate = nil
                client.disconnect()
            }

            let expiringClientIds = Set(expiringClients.map { $0.clientId })
            self.expiringClientsByTopic.remove { expiringClientIds.contains($0.clientId) }
            self.expiringClientsByTopic.removeUnassociatedTopics()
        }
    }

    /// Notifies subscribers' `disconnectCallbackDelegate` of a disconnection that was not user-requested
    ///
    /// This method must be called from `concurrencyQueue`.
    ///
    /// - Parameter mqttClient: The client that received the disconnect error
    private func notifyDisconnectCallbackDelegates(for mqttClient: AWSIoTMQTTClient<AnyObject, AnyObject>, ofNewStatus status: AWSIoTMQTTStatus) {
        // If the incoming status doesn't represent an error condition, no notification
        // is necessary
        guard let error = AWSAppSyncSubscriptionError.from(status: status) else {
            return
        }

        guard let topics = topicsByClient[mqttClient], !topics.isEmpty else {
            return
        }

        let subscribers = subscribersByTopic.elements(for: topics)

        guard !subscribers.isEmpty else {
            return
        }

        subscriptionsQueue.async {
            subscribers.forEach { self.cancelSubscription(for: $0.self, userOriginatedDisconnect: false) }
            subscribers.forEach { $0.disconnectCallbackDelegate(error: error) }
        }
    }

    /// Reverse-maps the existing mqttClientsWithTopics map to be keyed by topic, with a set of associated
    /// clients.
    ///
    /// - Returns: A map of clients by topic
    private func clientsByTopic() -> [String: Set<AWSIoTMQTTClient<AnyObject, AnyObject>>] {
        var clientsByTopic = [String: Set<AWSIoTMQTTClient<AnyObject, AnyObject>>]()
        for (client, topics) in topicsByClient {
            for topic in topics {
                var oldClients = clientsByTopic[topic] ?? []
                oldClients.insert(client)
                clientsByTopic[topic] = oldClients
            }
        }
        return clientsByTopic
    }

}

/// A structure to maintain a map of weak references to elements, keyed by topic.
///
/// Note: This class is not thread safe. Callers are responsible for managing concurrency
private class TopicWeakMap<T: AnyObject> {
    private var dictionary = [String: NSHashTable<T>]()

    subscript(key: String) -> [T]? {
        return dictionary[key]?.allObjects
    }

    /// Adds an element to the array of associated objects for each topic in `topics`
    ///
    /// - Parameters:
    ///   - element: The element associated with `topics`
    ///   - topics: The array of topics with which `element` is associated
    func add(_ element: T, forTopics topics: [String]) {
        for topic in topics {
            if let elements = dictionary[topic] {
                elements.add(element)
            } else {
                let elements = NSHashTable<T>.weakObjects()
                elements.add(element)
                dictionary[topic] = elements
            }
        }
    }

    /// Scans each topic and removes elements matching the predicate
    ///
    /// - Parameter where: A predicate to test each element
    func remove(where: (T) -> Bool) {
        for elements in dictionary.values {
            let elementsToRemove = elements.allObjects.filter(`where`)
            elementsToRemove.forEach { elements.remove($0) }
        }
    }

    /// Cleans topics with no associated elements from storage, and returns the list of topics
    ///
    /// - Returns: A list of topics that have no matching elements
    @discardableResult func removeUnassociatedTopics() -> [String] {
        let unusedTopics = dictionary
            .filter { $0.value.allObjects.isEmpty }
            .map { $0.key }

        unusedTopics.forEach {
            dictionary.removeValue(forKey: $0)
        }

        return unusedTopics
    }

    /// Returns an array of elements that are associated with at least one member of `topics`
    ///
    /// - Parameter topics: The topics for which to return associated elements
    /// - Returns: An array of elements that are associated with at least one member of `topics`
    func elements(for topics: Set<String>) -> [T] {
        let elements = topics.map { self[$0] }
            .compactMap { $0 }
            .flatMap { $0 }
        return elements
    }
}
