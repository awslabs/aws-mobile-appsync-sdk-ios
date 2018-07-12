//
//  AppSyncMQTTClientTests.swift
//  AWSAppSync
//
//  Created by Mario Araujo on 10/07/2018.
//  Copyright © 2018 Dubal, Rohan. All rights reserved.
//

import Foundation
import XCTest
@testable import AWSAppSync

class MockSubscriptionWatcher: MQTTSubscritionWatcher {
    let identifier: Int
    let topics: [String]
    let messageCallbackBlock: ((Data) -> Void)?
    let disconnectCallbackBlock: ((Error) -> Void)?
    let deallocBlock: ((MQTTSubscritionWatcher) -> Void)?
    
    init(topics: [String], deallocBlock:((MQTTSubscritionWatcher) -> Void)? = nil, messageCallbackBlock:((Data) -> Void)? = nil, disconnectCallbackBlock:((Error) -> Void)? = nil) {
        self.identifier = NSUUID().hash
        self.topics = topics
        self.deallocBlock = deallocBlock
        self.messageCallbackBlock = messageCallbackBlock
        self.disconnectCallbackBlock = disconnectCallbackBlock
    }
    
    deinit {
        self.deallocBlock?(self)
    }
    
    func getIdentifier() -> Int {
        return self.identifier
    }
    func getTopics() -> [String] {
        return self.topics
    }
    func messageCallbackDelegate(data: Data) {
        self.messageCallbackBlock?(data)
    }
    func disconnectCallbackDelegate(error: Error) {
        self.disconnectCallbackBlock?(error)
    }
}

class AppSyncMQTTClientTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        MQTTClient<AnyObject, AnyObject>.restoreSwizzledMethods()
        super.tearDown()
    }
    
    func testMQTTConnectionAttempt() {
        
        let expectation = XCTestExpectation(description: "MQTTClient should connect")
        
        let connect: @convention(block) (MQTTClient<AnyObject, AnyObject>, NSString, NSString, Any?) -> Bool = { (_, _, _, _) -> Bool in
            expectation.fulfill()
            return true
        }
        
        MQTTClient<AnyObject, AnyObject>.swizzle(selector: #selector(MQTTClient<AnyObject, AnyObject>.connect(withClientId:toHost:statusCallback:)), withBlock: connect)
        
        let client = AppSyncMQTTClient()
        
        let watcher = MockSubscriptionWatcher(topics: ["1", "2"])
        client.addWatcher(watcher: watcher, topics: watcher.getTopics(), identifier: watcher.getIdentifier())
        client.startSubscriptions(subscriptionInfo: [AWSSubscriptionInfo(clientId: "1", url: "url", topics: watcher.getTopics())])
        
        wait(for: [expectation], timeout: 2)
    }
    
    func testSubscriptionsCoalescing() {
        
        let expectation = XCTestExpectation(description: "Single call to MQTTClient connect should be made")
        expectation.isInverted = true
        expectation.expectedFulfillmentCount = 2
        
        let connect: @convention(block) (MQTTClient<AnyObject, AnyObject>, NSString, NSString, Any?) -> Bool = { (_, _, _, _) -> Bool in
            expectation.fulfill()
            return true
        }
        
        MQTTClient<AnyObject, AnyObject>.swizzle(selector: #selector(MQTTClient<AnyObject, AnyObject>.connect(withClientId:toHost:statusCallback:)), withBlock: connect)
        
        let client = AppSyncMQTTClient()
        
        let watcher0 = MockSubscriptionWatcher(topics: ["1", "2"])
        
        client.addWatcher(watcher: watcher0, topics: watcher0.getTopics(), identifier: watcher0.getIdentifier())
        client.startSubscriptions(subscriptionInfo: [AWSSubscriptionInfo(clientId: "1", url: "url", topics: watcher0.getTopics())])
        
        let watcher1 = MockSubscriptionWatcher(topics: ["2", "3"])
        
        let allTopics = [watcher0.getTopics(), watcher1.getTopics()].flatMap({ $0 })
        client.addWatcher(watcher: watcher1, topics: watcher1.getTopics(), identifier: watcher1.getIdentifier())
        client.startSubscriptions(subscriptionInfo: [AWSSubscriptionInfo(clientId: "1", url: "url", topics: allTopics)])
            
        wait(for: [expectation], timeout: 2)
    }
    
    func testIgnoreSubscriptionsWithoutInterestedTopics() {
        
        let expectation = XCTestExpectation(description: "No call to MQTTClient connect should be made")
        expectation.isInverted = true
        
        let connect: @convention(block) (MQTTClient<AnyObject, AnyObject>, NSString, NSString, Any?) -> Bool = { (_, _, _, _) -> Bool in
            expectation.fulfill()
            return true
        }
        
        MQTTClient<AnyObject, AnyObject>.swizzle(selector: #selector(MQTTClient<AnyObject, AnyObject>.connect(withClientId:toHost:statusCallback:)), withBlock: connect)
        
        let client = AppSyncMQTTClient()
        
        let watcher = MockSubscriptionWatcher(topics: ["1", "2"])
        let unwantedTopics = ["3"]
        
        client.addWatcher(watcher: watcher, topics: watcher.getTopics(), identifier: watcher.getIdentifier())
        client.startSubscriptions(subscriptionInfo: [AWSSubscriptionInfo(clientId: "1", url: "url", topics: unwantedTopics)])
        
        wait(for: [expectation], timeout: 2)
    }
    
    func testSubscriptionsWithInterestedTopics() {
        
        let expectation = XCTestExpectation(description: "MQTTClient should connect")
        
        let connect: @convention(block) (MQTTClient<AnyObject, AnyObject>, NSString, NSString, Any?) -> Bool = { (_, _, _, _) -> Bool in
            expectation.fulfill()
            return true
        }
        
        MQTTClient<AnyObject, AnyObject>.swizzle(selector: #selector(MQTTClient<AnyObject, AnyObject>.connect(withClientId:toHost:statusCallback:)), withBlock: connect)
        
        let client = AppSyncMQTTClient()
        
        let watcher = MockSubscriptionWatcher(topics: ["1", "2"])
        let topics = ["2", "3"]
        
        client.addWatcher(watcher: watcher, topics: watcher.getTopics(), identifier: watcher.getIdentifier())
        client.startSubscriptions(subscriptionInfo: [AWSSubscriptionInfo(clientId: "1", url: "url", topics: topics)])
        
        wait(for: [expectation], timeout: 2)
    }
    
    func testStopSubscriptionsOnWatcherDealloc() {
        
        let connectExpectation = XCTestExpectation(description: "MQTTClient should connect")
        let disconnectExpectation = XCTestExpectation(description: "MQTTClient should disconnect")
        
        let connect: @convention(block) (MQTTClient<AnyObject, AnyObject>, NSString, NSString, Any?) -> Bool = { (_, _, _, _) -> Bool in
            connectExpectation.fulfill()
            return true
        }
        
        let disconnect: @convention(block) (MQTTClient<AnyObject, AnyObject>) -> Void = { (_) in
            disconnectExpectation.fulfill()
        }
        
        MQTTClient<AnyObject, AnyObject>.swizzle(selector: #selector(MQTTClient<AnyObject, AnyObject>.connect(withClientId:toHost:statusCallback:)), withBlock: connect)
        MQTTClient<AnyObject, AnyObject>.swizzle(selector: #selector(MQTTClient<AnyObject, AnyObject>.disconnect), withBlock: disconnect)
        
        let client = AppSyncMQTTClient()
        
        weak var weakWatcher: MockSubscriptionWatcher?
        
        autoreleasepool {
            let deallocBlock: (MQTTSubscritionWatcher) -> Void = { (object) in
                client.stopSubscription(subscription: object)
            }
            
            let watcher = MockSubscriptionWatcher(topics: ["1", "2"], deallocBlock: deallocBlock)
            client.addWatcher(watcher: watcher, topics: watcher.getTopics(), identifier: watcher.getIdentifier())
            client.startSubscriptions(subscriptionInfo: [AWSSubscriptionInfo(clientId: "1", url: "url", topics: watcher.topics)])
            weakWatcher = watcher
            
            wait(for: [connectExpectation], timeout: 2)
        }
        
        XCTAssert(weakWatcher == nil, "Watcher should have been deallocated")
        
        wait(for: [disconnectExpectation], timeout: 1)
    }
    
    func testSubscribeTopicsAfterConnected() {
        
        let connectExpectation = XCTestExpectation(description: "MQTTClient should connect")
        
        let subscriptionExpectation = XCTestExpectation(description: "MQTTClient should subscribe to topic once connected")
        subscriptionExpectation.expectedFulfillmentCount = 2
        
        var triggerConnectionStatusChangedToConnected: (() -> Void)?
        
        let connect: @convention(block) (MQTTClient<AnyObject, AnyObject>, NSString, NSString, Any?) -> Bool = { (instance, client, url, wat) -> Bool in
            connectExpectation.fulfill()
            triggerConnectionStatusChangedToConnected = {
                instance.clientDelegate.connectionStatusChanged(.connected, client: instance)
            }
            return true
        }
        
        var subscribedTopics = [String]()
        
        let subscribe: @convention(block) (MQTTClient<AnyObject, AnyObject>, NSString, UInt8, Any?) -> Void = { (_, topic, _, _) in
            subscribedTopics.append(topic as String)
            subscriptionExpectation.fulfill()
        }
        
        MQTTClient<AnyObject, AnyObject>.swizzle(selector: #selector(MQTTClient<AnyObject, AnyObject>.connect(withClientId:toHost:statusCallback:)), withBlock: connect)
        MQTTClient<AnyObject, AnyObject>.swizzle(selector: #selector(MQTTClient<AnyObject, AnyObject>.subscribe(toTopic:qos:extendedCallback:)), withBlock: subscribe)
        
        let client = AppSyncMQTTClient()
        
        let watcher = MockSubscriptionWatcher(topics: ["1", "2", "3"])
        let topics = ["2", "3"]
        
        client.addWatcher(watcher: watcher, topics: watcher.getTopics(), identifier: watcher.getIdentifier())
        client.startSubscriptions(subscriptionInfo: [AWSSubscriptionInfo(clientId: "1", url: "url", topics: topics)])
        
        wait(for: [connectExpectation], timeout: 2)
        
        triggerConnectionStatusChangedToConnected?()
        
        wait(for: [subscriptionExpectation], timeout: 1)
        
        XCTAssertEqual(topics, subscribedTopics)
    }
    
    func testDisconnectDelegate() {
        
        let connectExpectation = XCTestExpectation(description: "MQTTClient should connect")
        
        let errorDelegateExpectation = XCTestExpectation(description: "MQTTClient should subscribe to topic once connected")
        
        var triggerConnectionStatusChangedToConnectionError: (() -> Void)?
        
        let connect: @convention(block) (MQTTClient<AnyObject, AnyObject>, NSString, NSString, Any?) -> Bool = { (instance, client, url, wat) -> Bool in
            connectExpectation.fulfill()
            triggerConnectionStatusChangedToConnectionError = {
                instance.clientDelegate.connectionStatusChanged(.connectionError, client: instance)
            }
            return true
        }
        
        MQTTClient<AnyObject, AnyObject>.swizzle(selector: #selector(MQTTClient<AnyObject, AnyObject>.connect(withClientId:toHost:statusCallback:)), withBlock: connect)
        
        let client = AppSyncMQTTClient()
        
        let disconnectCallbackBlock: (Error) -> Void = { (error) in
            errorDelegateExpectation.fulfill()
        }
        
        let watcher = MockSubscriptionWatcher(topics: ["1"], disconnectCallbackBlock: disconnectCallbackBlock)
        
        client.addWatcher(watcher: watcher, topics: watcher.getTopics(), identifier: watcher.getIdentifier())
        client.startSubscriptions(subscriptionInfo: [AWSSubscriptionInfo(clientId: "1", url: "url", topics: watcher.getTopics())])
        
        wait(for: [connectExpectation], timeout: 2)
        
        triggerConnectionStatusChangedToConnectionError?()
        
        wait(for: [errorDelegateExpectation], timeout: 1)
    }
    
    func testReceiveMessageDelegate() {
        
        let connectExpectation = XCTestExpectation(description: "MQTTClient should connect")
        
        let receivedMessageExpectation = XCTestExpectation(description: "MQTTClient should trigger received messages delegate only for subscribed topics")
        receivedMessageExpectation.expectedFulfillmentCount = 2
        
        var triggerReceivedMessageFromTopic: ((String) -> Void)?
        
        let connect: @convention(block) (MQTTClient<AnyObject, AnyObject>, NSString, NSString, Any?) -> Bool = { (instance, client, url, wat) -> Bool in
            connectExpectation.fulfill()
            triggerReceivedMessageFromTopic = { (topic) in
                instance.clientDelegate.receivedMessageData(Data(), onTopic: topic)
            }
            return true
        }
        
        MQTTClient<AnyObject, AnyObject>.swizzle(selector: #selector(MQTTClient<AnyObject, AnyObject>.connect(withClientId:toHost:statusCallback:)), withBlock: connect)
        
        let client = AppSyncMQTTClient()
        
        let messageCallbackBlock: (Data) -> Void = { (_) in
            receivedMessageExpectation.fulfill()
        }
        
        let watcher = MockSubscriptionWatcher(topics: ["1"], messageCallbackBlock: messageCallbackBlock)
        
        client.addWatcher(watcher: watcher, topics: watcher.getTopics(), identifier: watcher.getIdentifier())
        client.startSubscriptions(subscriptionInfo: [AWSSubscriptionInfo(clientId: "1", url: "url", topics: watcher.getTopics())])
        
        wait(for: [connectExpectation], timeout: 2)
        
        triggerReceivedMessageFromTopic?("2")
        triggerReceivedMessageFromTopic?("1")
        triggerReceivedMessageFromTopic?("3")
        triggerReceivedMessageFromTopic?("1")
        
        wait(for: [receivedMessageExpectation], timeout: 1)
    }
}
