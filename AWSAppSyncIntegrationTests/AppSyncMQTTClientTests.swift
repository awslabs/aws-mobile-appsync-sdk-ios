//
//  AppSyncMQTTClientTests.swift
//  AWSAppSync
//
//  Created by Mario Araujo on 10/07/2018.
//  Copyright © 2018 Amazon Web Services. All rights reserved.
//

import XCTest

@testable import AWSAppSync
@testable import AWSAppSyncTestCommon

class AppSyncMQTTClientTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        AWSIoTMQTTClient<AnyObject, AnyObject>.restoreSwizzledMethods()
        super.tearDown()
    }
    
    func testMQTTConnectionAttempt() {
        
        let expectation = XCTestExpectation(description: "AWSIoTMQTTClient should connect")
        
        let connect: @convention(block) (AWSIoTMQTTClient<AnyObject, AnyObject>, NSString, NSString, Any?) -> Bool = { (_, _, _, _) -> Bool in
            expectation.fulfill()
            return true
        }
        
        AWSIoTMQTTClient<AnyObject, AnyObject>.swizzle(selector: #selector(AWSIoTMQTTClient<AnyObject, AnyObject>.connect(withClientId:presignedURL:statusCallback:)), withBlock: connect)
        
        let client = AppSyncMQTTClient()
        
        let watcher = MockSubscriptionWatcher(topics: ["1", "2"])
        client.add(watcher: watcher, forNewTopics: watcher.getTopics())
        client.startSubscriptions(subscriptionInfos: [AWSSubscriptionInfo(clientId: "1", url: "url", topics: watcher.getTopics())], identifier: 1)
        
        wait(for: [expectation], timeout: 2)
    }
    
    func testSubscriptionsCoalescing() {
        
        let expectation = XCTestExpectation(description: "Single call to AWSIoTMQTTClient connect should be made")
        expectation.isInverted = true
        expectation.expectedFulfillmentCount = 2
        
        let connect: @convention(block) (AWSIoTMQTTClient<AnyObject, AnyObject>, NSString, NSString, Any?) -> Bool = { (_, _, _, _) -> Bool in
            expectation.fulfill()
            return true
        }
        
        AWSIoTMQTTClient<AnyObject, AnyObject>.swizzle(selector: #selector(AWSIoTMQTTClient<AnyObject, AnyObject>.connect(withClientId:presignedURL:statusCallback:)), withBlock: connect)
        
        let client = AppSyncMQTTClient()
        
        let watcher0 = MockSubscriptionWatcher(topics: ["1", "2"])
        
        client.add(watcher: watcher0, forNewTopics: watcher0.getTopics())
        client.startSubscriptions(subscriptionInfos: [AWSSubscriptionInfo(clientId: "1", url: "url", topics: watcher0.getTopics())], identifier: 1)
        
        let watcher1 = MockSubscriptionWatcher(topics: ["2", "3"])
        
        let allTopics = [watcher0.getTopics(), watcher1.getTopics()].flatMap({ $0 })
        client.add(watcher: watcher1, forNewTopics: watcher1.getTopics())
        client.startSubscriptions(subscriptionInfos: [AWSSubscriptionInfo(clientId: "1", url: "url", topics: allTopics)], identifier: 1)

        wait(for: [expectation], timeout: 2)
    }
    
    func testDisconnectIssuedByMQTTClient() {
        
        let expectation = XCTestExpectation(description: "AWSIoTMQTTClient should connect")
        
        let connect: @convention(block) (AWSIoTMQTTClient<AnyObject, AnyObject>, NSString, NSString, Any?) -> Bool = { (client, _, _, _) -> Bool in
            expectation.fulfill()
            
            // Schedule a disconnect status trigger as if MQTT client dropped connection
            DispatchQueue.init(label: "appsync.test.disconnect").asyncAfter(deadline: .now() + .seconds(3), execute: {
                client.clientDelegate.connectionStatusChanged(.connectionError, client: client)
            })
            
            return true
        }
        
        AWSIoTMQTTClient<AnyObject, AnyObject>.swizzle(selector: #selector(AWSIoTMQTTClient<AnyObject, AnyObject>.connect(withClientId:presignedURL:statusCallback:)), withBlock: connect)
        
        let client = AppSyncMQTTClient()
        
        let watcher = MockSubscriptionWatcher(topics: ["1", "2"])
        let topics = ["2", "3"]
        
        client.add(watcher: watcher, forNewTopics: watcher.getTopics())
        client.startSubscriptions(subscriptionInfos: [AWSSubscriptionInfo(clientId: "1", url: "url", topics: topics)], identifier: 1)
        
        wait(for: [expectation], timeout: 2)
        
        XCTAssert(client.cancelledSubscriptions.count == 0, "No subscriptions should be cancelled as the disconnect is invoked after 3 seconds and the timeout for tests is 2 seconds.")
        
        XCTAssert(client.topicsByClient.count == 1, "There should be 1 client mapped for the watcher as the disconnect is invoked after 3 seconds and the timeout for tests is 2 seconds.")
        
        // sleep till the dispatch queue "appsync.test.disconnect" fires a connection error event
        sleep(5)
        
        // The connection error event would notify the watcher of connection error
        // The AppSyncMQTTClient is then responsible for discarding terminated AppSyncIOTMQTT clients
        // The AppSyncMQTTClient should not have any details of topics and MQTT clients after cleanup
        
        XCTAssert(client.cancelledSubscriptions.count == 1, "1 subscription should be cancelled due to disconnect error.")
        
        XCTAssert(client.topicsByClient.count == 0, "The topics by client dictionary should be cleaned up as there was a connection error received. The clean up should be done regardless of developer calling `cancel`.")
        
    }
    
    func testIgnoreSubscriptionsWithoutInterestedTopics() {
        
        let expectation = XCTestExpectation(description: "No call to AWSIoTMQTTClient connect should be made")
        expectation.isInverted = true
        
        let connect: @convention(block) (AWSIoTMQTTClient<AnyObject, AnyObject>, NSString, NSString, Any?) -> Bool = { (_, _, _, _) -> Bool in
            expectation.fulfill()
            return true
        }
        
        AWSIoTMQTTClient<AnyObject, AnyObject>.swizzle(selector: #selector(AWSIoTMQTTClient<AnyObject, AnyObject>.connect(withClientId:presignedURL:statusCallback:)), withBlock: connect)
        
        let client = AppSyncMQTTClient()
        
        let watcher = MockSubscriptionWatcher(topics: ["1", "2"])
        let unwantedTopics = ["3"]
        
        client.add(watcher: watcher, forNewTopics: watcher.getTopics())
        client.startSubscriptions(subscriptionInfos: [AWSSubscriptionInfo(clientId: "1", url: "url", topics: unwantedTopics)], identifier: 1)
        
        wait(for: [expectation], timeout: 2)
    }
    
    func testSubscriptionsWithInterestedTopics() {
        
        let expectation = XCTestExpectation(description: "AWSIoTMQTTClient should connect")
        
        let connect: @convention(block) (AWSIoTMQTTClient<AnyObject, AnyObject>, NSString, NSString, Any?) -> Bool = { (_, _, _, _) -> Bool in
            expectation.fulfill()
            return true
        }
        
        AWSIoTMQTTClient<AnyObject, AnyObject>.swizzle(selector: #selector(AWSIoTMQTTClient<AnyObject, AnyObject>.connect(withClientId:presignedURL:statusCallback:)), withBlock: connect)
        
        let client = AppSyncMQTTClient()
        
        let watcher = MockSubscriptionWatcher(topics: ["1", "2"])
        let topics = ["2", "3"]
        
        client.add(watcher: watcher, forNewTopics: watcher.getTopics())
        client.startSubscriptions(subscriptionInfos: [AWSSubscriptionInfo(clientId: "1", url: "url", topics: topics)], identifier: 1)
        
        wait(for: [expectation], timeout: 2)
    }
    
    func testStopSubscriptionsOnWatcherDealloc() {

        let connectExpectation = XCTestExpectation(description: "AWSIoTMQTTClient should connect")
        let disconnectExpectation = XCTestExpectation(description: "AWSIoTMQTTClient should disconnect")
        
        let connect: @convention(block) (AWSIoTMQTTClient<AnyObject, AnyObject>, NSString, NSString, Any?) -> Bool = { (_, _, _, _) -> Bool in
            connectExpectation.fulfill()
            return true
        }
        
        let disconnect: @convention(block) (AWSIoTMQTTClient<AnyObject, AnyObject>) -> Void = { (_) in
            disconnectExpectation.fulfill()
        }
        
        AWSIoTMQTTClient<AnyObject, AnyObject>.swizzle(selector: #selector(AWSIoTMQTTClient<AnyObject, AnyObject>.connect(withClientId:presignedURL:statusCallback:)), withBlock: connect)
        AWSIoTMQTTClient<AnyObject, AnyObject>.swizzle(selector: #selector(AWSIoTMQTTClient<AnyObject, AnyObject>.disconnect), withBlock: disconnect)
        
        let client = AppSyncMQTTClient()
        
        weak var weakWatcher: MockSubscriptionWatcher?
        
        autoreleasepool {
            let deallocBlock: (MQTTSubscriptionWatcher) -> Void = { (object) in
                client.cancelSubscription(for: object, userOriginatedDisconnect: true)
            }
            
            let watcher = MockSubscriptionWatcher(topics: ["1", "2"], deallocBlock: deallocBlock)
            client.add(watcher: watcher, forNewTopics: watcher.getTopics())
            client.startSubscriptions(subscriptionInfos: [AWSSubscriptionInfo(clientId: "1", url: "url", topics: watcher.topics)], identifier: 1)
            weakWatcher = watcher
            
            wait(for: [connectExpectation], timeout: 2)
        }
        
        XCTAssert(weakWatcher == nil, "Watcher should have been deallocated")
        
        wait(for: [disconnectExpectation], timeout: 2)
    }
    
    func testSubscribeTopicsAfterConnected() {
        let connectExpectation = XCTestExpectation(description: "AWSIoTMQTTClient should connect")
        
        let subscriptionExpectation = XCTestExpectation(description: "AWSIoTMQTTClient should subscribe to topic once connected")
        subscriptionExpectation.expectedFulfillmentCount = 2
        
        var triggerConnectionStatusChangedToConnected: (() -> Void)?
        
        let connect: @convention(block) (AWSIoTMQTTClient<AnyObject, AnyObject>, NSString, NSString, Any?) -> Bool = { (instance, _, _, _) -> Bool in
            connectExpectation.fulfill()
            triggerConnectionStatusChangedToConnected = {
                instance.clientDelegate.connectionStatusChanged(.connected, client: instance)
            }
            return true
        }
        
        var subscribedTopics = [String]()
        
        let subscribe: @convention(block) (AWSIoTMQTTClient<AnyObject, AnyObject>, NSString, UInt8, Any?, Any?) -> Void = { (_, topic, _, _, _) in
            subscribedTopics.append(topic as String)
            subscriptionExpectation.fulfill()
        }
        
        AWSIoTMQTTClient<AnyObject, AnyObject>.swizzle(selector: #selector(AWSIoTMQTTClient<AnyObject, AnyObject>.connect(withClientId:presignedURL:statusCallback:)), withBlock: connect)
        AWSIoTMQTTClient<AnyObject, AnyObject>.swizzle(selector: #selector(AWSIoTMQTTClient<AnyObject, AnyObject>.subscribe(toTopic:qos:extendedCallback:ackCallback:)), withBlock: subscribe)
        
        let client = AppSyncMQTTClient()
        
        let watcher = MockSubscriptionWatcher(topics: ["1", "2", "3"])
        let topics = ["2", "3"]
        
        client.add(watcher: watcher, forNewTopics: watcher.getTopics())
        client.startSubscriptions(subscriptionInfos: [AWSSubscriptionInfo(clientId: "1", url: "url", topics: topics)], identifier: 1)
        
        wait(for: [connectExpectation], timeout: 5)
        
        triggerConnectionStatusChangedToConnected?()
        
        wait(for: [subscriptionExpectation], timeout: 5)
        
        XCTAssertEqual(topics.count, subscribedTopics.count)
    }
    
    func testDisconnectDelegate() {
        
        let connectExpectation = XCTestExpectation(description: "AWSIoTMQTTClient should connect")
        
        let errorDelegateExpectation = XCTestExpectation(description: "AWSIoTMQTTClient should subscribe to topic once connected")
        
        var triggerConnectionStatusChangedToConnectionError: (() -> Void)?
        
        let connect: @convention(block) (AWSIoTMQTTClient<AnyObject, AnyObject>, NSString, NSString, Any?) -> Bool = { (instance, client, url, wat) -> Bool in
            connectExpectation.fulfill()
            triggerConnectionStatusChangedToConnectionError = {
                instance.clientDelegate.connectionStatusChanged(.connectionError, client: instance)
            }
            return true
        }
        
        AWSIoTMQTTClient<AnyObject, AnyObject>.swizzle(selector: #selector(AWSIoTMQTTClient<AnyObject, AnyObject>.connect(withClientId:presignedURL:statusCallback:)), withBlock: connect)
        
        let client = AppSyncMQTTClient()
        
        let disconnectCallbackBlock: (Error) -> Void = { (error) in
            errorDelegateExpectation.fulfill()
        }
        
        let watcher = MockSubscriptionWatcher(topics: ["1"], disconnectCallbackBlock: disconnectCallbackBlock)
        
        client.add(watcher: watcher, forNewTopics: watcher.getTopics())
        client.startSubscriptions(subscriptionInfos: [AWSSubscriptionInfo(clientId: "1", url: "url", topics: watcher.getTopics())], identifier: 1)
        
        wait(for: [connectExpectation], timeout: 2)
        
        triggerConnectionStatusChangedToConnectionError?()
        
        wait(for: [errorDelegateExpectation], timeout: 5)
    }
    
    func testReceiveMessageDelegate() {
        
        let connectExpectation = XCTestExpectation(description: "AWSIoTMQTTClient should connect")
        
        let receivedMessageExpectation = XCTestExpectation(description: "AWSIoTMQTTClient should trigger received messages delegate only for subscribed topics")
        receivedMessageExpectation.expectedFulfillmentCount = 2
        
        var triggerReceivedMessageFromTopic: ((String) -> Void)?
        
        let connect: @convention(block) (AWSIoTMQTTClient<AnyObject, AnyObject>, NSString, NSString, Any?) -> Bool = { (instance, client, url, wat) -> Bool in
            connectExpectation.fulfill()
            triggerReceivedMessageFromTopic = { (topic) in
                instance.clientDelegate.receivedMessageData(Data(), onTopic: topic)
            }
            return true
        }
        
        AWSIoTMQTTClient<AnyObject, AnyObject>.swizzle(selector: #selector(AWSIoTMQTTClient<AnyObject, AnyObject>.connect(withClientId:presignedURL:statusCallback:)), withBlock: connect)
        
        let client = AppSyncMQTTClient()
        
        let messageCallbackBlock: (Data) -> Void = { (_) in
            receivedMessageExpectation.fulfill()
        }
        
        let watcher = MockSubscriptionWatcher(topics: ["1"], messageCallbackBlock: messageCallbackBlock)
        
        client.add(watcher: watcher, forNewTopics: watcher.getTopics())
        client.startSubscriptions(subscriptionInfos: [AWSSubscriptionInfo(clientId: "1", url: "url", topics: watcher.getTopics())], identifier: 1)
        
        wait(for: [connectExpectation], timeout: 2)
        
        triggerReceivedMessageFromTopic?("2")
        triggerReceivedMessageFromTopic?("1")
        triggerReceivedMessageFromTopic?("3")
        triggerReceivedMessageFromTopic?("1")
        
        wait(for: [receivedMessageExpectation], timeout: 2)
    }
    
    func testSubscribeAndUnsubscribe() {
        let expectation = XCTestExpectation(description: "AWSIoTMQTTClient should connect")
        let disconnectExpectation = XCTestExpectation(description: "AWSIoTMQTTClient should disconnect")
        
        let connect: @convention(block) (AWSIoTMQTTClient<AnyObject, AnyObject>, NSString, NSString, Any?) -> Bool = { (_, _, _, _) -> Bool in
            expectation.fulfill()
            return true
        }
        
        let disconnect: @convention(block) (AWSIoTMQTTClient<AnyObject, AnyObject>) -> Void = { (_) in
            disconnectExpectation.fulfill()
        }
        
        AWSIoTMQTTClient<AnyObject, AnyObject>.swizzle(selector: #selector(AWSIoTMQTTClient<AnyObject, AnyObject>.connect(withClientId:presignedURL:statusCallback:)), withBlock: connect)
        AWSIoTMQTTClient<AnyObject, AnyObject>.swizzle(selector: #selector(AWSIoTMQTTClient<AnyObject, AnyObject>.disconnect), withBlock: disconnect)
        
        let client = AppSyncMQTTClient()
        
        let watcher = MockSubscriptionWatcher(topics: ["1", "2"])
        
        client.add(watcher: watcher, forNewTopics: watcher.getTopics())
        client.startSubscriptions(subscriptionInfos: [AWSSubscriptionInfo(clientId: "1", url: "url", topics: watcher.topics)], identifier: 1)
        
        wait(for: [expectation], timeout: 2)
        
        client.cancelSubscription(for: watcher, userOriginatedDisconnect: true)
        
        wait(for: [disconnectExpectation], timeout: 2)
    }
    
    func testUserIssuedSubscriptionCancel() {
        let expectation = XCTestExpectation(description: "AWSIoTMQTTClient should connect")
        let disconnectExpectation = XCTestExpectation(description: "AWSIoTMQTTClient should disconnect")
        
        let connect: @convention(block) (AWSIoTMQTTClient<AnyObject, AnyObject>, NSString, NSString, Any?) -> Bool = { (_, _, _, _) -> Bool in
            expectation.fulfill()
            return true
        }
        
        let disconnect: @convention(block) (AWSIoTMQTTClient<AnyObject, AnyObject>) -> Void = { (_) in
            disconnectExpectation.fulfill()
        }
        
        AWSIoTMQTTClient<AnyObject, AnyObject>.swizzle(selector: #selector(AWSIoTMQTTClient<AnyObject, AnyObject>.connect(withClientId:presignedURL:statusCallback:)), withBlock: connect)
        AWSIoTMQTTClient<AnyObject, AnyObject>.swizzle(selector: #selector(AWSIoTMQTTClient<AnyObject, AnyObject>.disconnect), withBlock: disconnect)
        
        let client = AppSyncMQTTClient()
        
        let watcher = MockSubscriptionWatcher(topics: ["1", "2"])
        
        client.add(watcher: watcher, forNewTopics: watcher.getTopics())
        client.startSubscriptions(subscriptionInfos: [AWSSubscriptionInfo(clientId: "1", url: "url", topics: watcher.topics)], identifier: 1)
        
        wait(for: [expectation], timeout: 2)
        
        XCTAssert(client.cancelledSubscriptions.count == 0, "No subscriptions should be cancelled as the cancel opeartion is not yet performed.")
        
        XCTAssert(client.topicsByClient.count == 1, "There should be 1 client mapped for the watcher as the cancel operation is not yet performed.")
        
        client.cancelSubscription(for: watcher, userOriginatedDisconnect: true)
        
        wait(for: [disconnectExpectation], timeout: 2)
        
        // The test here is that when the developer invokes cancel, AppSyncMQTT client performs metadata cleanup
        // The AppSyncMQTTClient is responsible for discarding terminated AppSyncIOTMQTT clients
        // The AppSyncMQTTClient should not have any details of topics and MQTT clients after cleanup
        
        XCTAssert(client.cancelledSubscriptions.count == 1, "1 subscription should be cancelled due to developer invoking `cancelSubscription`.")
        
        XCTAssert(client.topicsByClient.count == 0, "The topics by client dictionary should be cleaned up as there was a cancel from developer received.")
    }

}
