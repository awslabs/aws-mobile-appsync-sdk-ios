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
@testable import AppSyncRealTimeClient

class SubscriptionMiscTests: XCTestCase {
    
    /// Test whether calling start / stop subscription is working correctly
    ///
    /// To test this case, we'll set up a mock connection which has a delay before responding back to the caller
    /// This ensures that the subscription watchers can call `cancel` before the response comes back and thus allowing
    /// to mimick cases where calling cancel / start rapidly for subscriptions does not cause issues.
    ///
    /// - Given: A valid appsync client
    /// - When:
    ///    - I invoke cancel just after subscription
    ///    - Subscribe again
    /// - Then:
    ///    - When I call cancel just after subscription I should not get back any subscribed message
    ///    - But for the second subscription I should get subscribed messages.
    ///
    func testStartStopStartSubscriptions() {
        let secondsToWait = 1
        let subscriptionWatchers = 5

        let mockHTTPTransport = MockAWSNetworkTransport()
        let appSyncClient: AWSAppSyncClient = try! UnitTestHelpers.makeAppSyncClient(using: mockHTTPTransport,
                                                                                     cacheConfiguration: nil,
                                                                                     subscriptionFactory: MockDelayedSubscriptionFactory(secondsToWait))
        
        let shouldReceiveCallbackExpectation = expectation(description: "HTTP block of subscription was received.")
        shouldReceiveCallbackExpectation.expectedFulfillmentCount  =  subscriptionWatchers
        
        let shouldNotReceiveCallbackExpectation = expectation(description: "HTTP block of subscription should not be received.")
        shouldNotReceiveCallbackExpectation.isInverted = true
        
        // we create a dictionary where we hold all the watchers; this mimicks app holding reference to watchers
        var watchers: [String: AWSAppSyncSubscriptionWatcher<OnUpvotePostSubscription>] = [:]
        
        // create an array of object ids to be used in subscription
        var subscriptionIds: [String] = []
        for _ in 0 ..< subscriptionWatchers  {
            subscriptionIds.append(UUID().uuidString)
        }
        
        // Initiate subscription requests for the generated object ids
        for uuid in subscriptionIds {

            let watcher = try! appSyncClient.subscribe(subscription: OnUpvotePostSubscription(id: uuid)) { (_, _, error) in
                if error != nil {
                    // No callbacks are expected here since the subscriptions are cancelled immediately
                    shouldNotReceiveCallbackExpectation.fulfill()
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

            let watcher = try! appSyncClient.subscribe(subscription: OnUpvotePostSubscription(id: uuid)) { (_, _, error) in
                // All 5 subscriptions should receive callbacks. They should not be stuck in a frozen state.
                if error != nil {
                    shouldReceiveCallbackExpectation.fulfill()
                }
            }
            watchers[uuid] = watcher
        }
        
        // Wait to ensure that correct callbacks are made and no subscription requests are frozen.
        wait(for: [shouldReceiveCallbackExpectation, shouldNotReceiveCallbackExpectation], timeout: Double(subscriptionWatchers) * Double(secondsToWait) + 1.0)
    }
}

class MockDelayedSubscriptionFactory: SubscriptionConnectionFactory {

    let secondsToWait: Int

    init(_ delay: Int){
        self.secondsToWait = delay
    }

    func connection(connectionType: SubscriptionConnectionType) -> SubscriptionConnection? {
        return MockDelayedConnection(secondsToWait)
    }
}

class MockDelayedConnection: SubscriptionConnection {

    let secondsToWait: Int

    init(_ delay: Int){
        self.secondsToWait = delay
    }

    /// Current item that is subscriped
    var subscriptionItem: SubscriptionItem!

    func subscribe(requestString: String,
                   variables: [String : Any?]?,
                   eventHandler: @escaping SubscriptionEventHandler) -> SubscriptionItem {
        subscriptionItem = SubscriptionItem(requestString: requestString,
                                            variables: variables,
                                            eventHandler: eventHandler)
        DispatchQueue.global().asyncAfter(deadline:  DispatchTime.now() + .seconds(secondsToWait)) {

            self.subscriptionItem.subscriptionEventHandler(.failed(ConnectionProviderError.unknown(payload: nil)),
                                                           self.subscriptionItem)
        }
        return subscriptionItem
    }

    func unsubscribe(item: SubscriptionItem) {
        subscriptionItem.subscriptionEventHandler(.connection(.disconnected) , subscriptionItem)
    }


}
