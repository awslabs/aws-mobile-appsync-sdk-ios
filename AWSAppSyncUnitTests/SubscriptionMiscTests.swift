//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
import XCTest
@testable import AWSAppSync
@testable import AWSCore
@testable import AWSAppSyncTestCommon

class SubscriptionMiscTests: XCTestCase {
    
    func testSubscriptionUniqueIdentifiers() {
        var uniqueIdSet: Set<Int> = Set()
        let expectation1 = expectation(description: "operations on queue1 did not encounter duplicate IDs")
        let expectation2 = expectation(description: "operations on queue2 did not encounter duplicate IDs")
        let syncDispatchQueueForSet = DispatchQueue(label: "dispatch.queue.for.set")

        DispatchQueue(label: "testSubscriptionUniqueIdentifiers.queue1").async {
            for _ in 0...1000 {
                let uniqueID = SubscriptionsOrderHelper.getNextUniqueIdentifier()
                syncDispatchQueueForSet.sync {
                    if uniqueIdSet.contains(uniqueID) {
                        XCTFail("Found a unique id which was already generated previously.")
                    } else {
                        uniqueIdSet.insert(uniqueID)
                    }
                }
            }
            expectation1.fulfill()
        }
        
        DispatchQueue(label: "testSubscriptionUniqueIdentifiers.queue2").async {
            for _ in 0...1000 {
                let uniqueID = SubscriptionsOrderHelper.getNextUniqueIdentifier()
                syncDispatchQueueForSet.sync {
                    if uniqueIdSet.contains(uniqueID) {
                        XCTFail("Found a unique id which was already generated previously.")
                    } else {
                        uniqueIdSet.insert(uniqueID)
                    }
                }
            }
            expectation2.fulfill()
        }
        
        wait(for: [expectation1, expectation2], timeout: 5.0)
    }
    
    func testStartStopStartSubscriptions() {
        let secondsToWait = 1
        let subscriptionWatchers = 5
        
        // To test this case, we'll set up a mock http transport which has a delay before responding back to the caller
        // This ensures that the subscription watchers can call `cancel` before the response comes back and thus allowing
        // to mimick cases where calling cancel / start rapidly for subscriptions does not cause issues.
        let mockHTTPTransport = MockAWSNetworkTransport()
        
        // First add a response block that delays response to subscription request
        let delayedResponseBlock: SendOperationResponseBlock<OnUpvotePostSubscription> = {
            operation, completionHandler in
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .seconds(secondsToWait)) {
                completionHandler(nil, AWSAppSyncSubscriptionError.connectionError)
            }
        }
        
        // Create client without any persistent cache but using our mock http transport
        let appSyncClient: AWSAppSyncClient = try! UnitTestHelpers.makeAppSyncClient(using: mockHTTPTransport, cacheConfiguration: nil)
        
        let watchersWhichShouldReceiveCallbackExpectation = expectation(description: "HTTP block of subscription was received.")
        watchersWhichShouldReceiveCallbackExpectation.expectedFulfillmentCount  =  subscriptionWatchers
        
        let watchersWhichShouldNotReceiveCallbackExpectation = expectation(description: "HTTP block of subscription should not be received.")
        watchersWhichShouldNotReceiveCallbackExpectation.isInverted = true
        
        // we create a dictionary where we hold all the watchers; this mimicks app holding reference to watchers
        var watchers: [String: AWSAppSyncSubscriptionWatcher<OnUpvotePostSubscription>] = [:]
        
        // create an array of object ids to be used in subscription
        var subscriptionIds: [String] = []
        for _ in 0 ..< subscriptionWatchers  {
            subscriptionIds.append(UUID().uuidString)
        }
        
        // Initiate subscription requests for the generated object ids
        for uuid in subscriptionIds {
            mockHTTPTransport.sendOperationResponseQueue.append(delayedResponseBlock)
            let watcher = try! appSyncClient.subscribe(subscription: OnUpvotePostSubscription(id: uuid)) { (_, _, error) in
                if error != nil {
                    // No callbacks are expected here since the subscriptions are cancelled immediately
                    watchersWhichShouldNotReceiveCallbackExpectation.fulfill()
                }
            }
            watchers[uuid] = watcher
        }
        // Immediately cancel all subscriptions (before delayed http callback which we implemented above can be executed.)
        for uuid in subscriptionIds {
            watchers[uuid]?.cancel()
        }
        // Remove references
        watchers.removeAll()
        
        // Try starting the subscriptions again
        for uuid in subscriptionIds {
            mockHTTPTransport.sendOperationResponseQueue.append(delayedResponseBlock)
            let watcher = try! appSyncClient.subscribe(subscription: OnUpvotePostSubscription(id: uuid)) { (_, _, error) in
                // All 5 subscriptions should receive callbacks. They should not be stuck in a frozen state.
                if error != nil {
                    watchersWhichShouldReceiveCallbackExpectation.fulfill()
                }
            }
            watchers[uuid] = watcher
        }
        
        // Wait to ensure that correct callbacks are made and no subscription requests are frozen.
        wait(for: [watchersWhichShouldReceiveCallbackExpectation, watchersWhichShouldNotReceiveCallbackExpectation], timeout: Double(subscriptionWatchers) * Double(secondsToWait) + 1.0)
    }
}
