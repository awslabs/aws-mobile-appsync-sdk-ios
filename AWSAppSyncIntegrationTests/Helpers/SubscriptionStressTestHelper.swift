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

import XCTest
@testable import AWSAppSync
@testable import AWSAppSyncTestCommon

class SubscriptionStressTestHelper: XCTestCase {
    private static let numberOfPostsToTest = 40

    private var appSyncClient: AWSAppSyncClient!
    private var testPostIDs = [GraphQLID](repeating: "", count: SubscriptionStressTestHelper.numberOfPostsToTest)

    // Hold onto this to retain references to the watchers during the test invocation
    var subscriptionWatchers = [AWSAppSyncSubscriptionWatcher<OnUpvotePostSubscription>]()

    // MARK: - Public test helper methods

    func stressTestSubscriptions(with appSyncClient: AWSAppSyncClient) {
        defer {
            subscriptionWatchers.forEach { $0.cancel() }
        }

        self.appSyncClient = appSyncClient

        let allPostsAreCreatedExpectations = createPostsAndMakeExpectations()
        wait(for: allPostsAreCreatedExpectations, timeout: TimeInterval(exactly: SubscriptionStressTestHelper.numberOfPostsToTest)!)

        XCTAssertEqual(testPostIDs.count, SubscriptionStressTestHelper.numberOfPostsToTest, "Number of created posts should be \(SubscriptionStressTestHelper.numberOfPostsToTest)")

        // Add subscriptions for each of the created posts. The expectations will be fulfilled
        // after the mutations are generated below.
        let allSubscriptionsAreTriggeredExpectations = subscribeToMutationsAndMakeExpectations()

        print("Waiting 10s for the server to begin delivering subscriptions")
        sleep(10)

        let mutationExpectations = mutatePostsAndMakeExpectations()

        let combinedExpectations = mutationExpectations + allSubscriptionsAreTriggeredExpectations
        wait(for: combinedExpectations, timeout: TimeInterval(exactly: SubscriptionStressTestHelper.numberOfPostsToTest)!)
    }

    // MARK: - Private utility methods

    private func createPostsAndMakeExpectations() -> [XCTestExpectation] {
        // Create records to mutate later
        var addPostsExpectations = [XCTestExpectation]()

        for i in 0 ..< SubscriptionStressTestHelper.numberOfPostsToTest {
            let addPostExpectation = XCTestExpectation(description: "Added post \(i)")
            addPostsExpectations.append(addPostExpectation)
            appSyncClient.perform(mutation: DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation) {
                (result: GraphQLResult<CreatePostWithoutFileUsingParametersMutation.Data>?, error: Error?) in
                XCTAssertNil(error, "Error should be nil")

                guard
                    let result = result,
                    let payload = result.data?.createPostWithoutFileUsingParameters
                    else {
                        XCTFail("Result & payload should not be nil")
                        return
                }

                XCTAssertEqual(payload.author, DefaultTestPostData.author, "Authors should match.")
                let id = payload.id
                self.testPostIDs[i] = id
                addPostExpectation.fulfill()
                print("Successful CreatePostWithoutFileUsingParametersMutation \(i) (\(id))")
            }
            print("Attempting CreatePostWithoutFileUsingParametersMutation \(i)")
        }

        return addPostsExpectations
    }

    private func subscribeToMutationsAndMakeExpectations() -> [XCTestExpectation] {
        var subscriptionsTriggeredExpectations = [XCTestExpectation]()

        for (i, id) in testPostIDs.enumerated() {
            let subscriptionTriggeredExpectation = XCTestExpectation(description: "Subscription triggered for post \(i) (\(id))")
            subscriptionsTriggeredExpectations.append(subscriptionTriggeredExpectation)

            let subscription: OnUpvotePostSubscription = OnUpvotePostSubscription(id: id)
            let optionalSubscriptionWatcher = try! appSyncClient.subscribe(subscription: subscription) {
                (result, _, error) in
                XCTAssertNil(error, "Error should be nil")

                guard let payload = result?.data?.onUpvotePost else {
                    XCTFail("Result & payload should not be nil")
                    return
                }

                let idFromPayload = payload.id

                subscriptionTriggeredExpectation.fulfill()
                print("Triggered OnUpvotePostSubscription \(i) (\(idFromPayload))")
            }
            print("Attempting OnUpvotePostSubscription \(i) (\(id))")

            guard let subscriptionWatcher = optionalSubscriptionWatcher else {
                XCTFail("Subscription watcher \(i) (\(id)) should not be nil")
                continue
            }

            subscriptionWatchers.append(subscriptionWatcher)
        }

        waitForRegistration(of: subscriptionWatchers)

        return subscriptionsTriggeredExpectations
    }

    typealias UnregisteredWatcherExpectation = (subscriptionWatcher: AWSAppSyncSubscriptionWatcher<OnUpvotePostSubscription>, expectation: XCTestExpectation)

    // Currently, `AWSAppSyncClient.subscribe(subscription:queue:resultHandler:)` doesn't have a
    // good way to inspect that the subscription has been registered on the service. We'll check
    // for `getTopics` returning a non-empty value to stand in for a completion handler
    private func waitForRegistration(of subscriptionWatchers: [AWSAppSyncSubscriptionWatcher<OnUpvotePostSubscription>]) {

        var subscriptionWatcherRegisteredExpectations = [XCTestExpectation]()

        var unregisteredWatcherExpectationsByIndex = [Int: UnregisteredWatcherExpectation]()
        for (i, watcher) in subscriptionWatchers.enumerated() {
            let expectation = XCTestExpectation(description: "Subscription watcher \(i) is registered")
            subscriptionWatcherRegisteredExpectations.append(expectation)
            unregisteredWatcherExpectationsByIndex[i] = (subscriptionWatcher: watcher, expectation: expectation)
        }

        // Wait until subscriptions are all registered
        let subscriptionWatcherRegistrationTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) {
            _ in
            var indexesToDelete = Set<Int>()
            for index in unregisteredWatcherExpectationsByIndex.keys {
                guard let (subscriptionWatcher, expectation) = unregisteredWatcherExpectationsByIndex[index] else {
                    continue
                }
                let isRegistered = !subscriptionWatcher.getTopics().isEmpty
                if isRegistered {
                    expectation.fulfill()
                    indexesToDelete.insert(index)
                    print("Registered OnUpvotePostSubscription \(index)")
                }
            }

            for index in indexesToDelete {
                unregisteredWatcherExpectationsByIndex.removeValue(forKey: index)
            }
        }

        // Wait for all subscriptions to be registered
        let timeToWait = Double(testPostIDs.count)
        wait(for: subscriptionWatcherRegisteredExpectations, timeout: timeToWait)
        subscriptionWatcherRegistrationTimer.invalidate()

        XCTAssertTrue(unregisteredWatcherExpectationsByIndex.isEmpty, "All subscriptions should have been registered by now")
    }

    /// Mutate the watched objects by upvoting them. This should fire each associated subscription
    /// We set up mutation expectations so that, if the test fails, we can tell whether it was the
    /// mutation that failed to complete, or the subscription that failed to trigger
    private func mutatePostsAndMakeExpectations() -> [XCTestExpectation] {
        var mutationExpectations = [XCTestExpectation]()
        for (i, id) in testPostIDs.enumerated() {
            let upvoteExpectation = XCTestExpectation(description: "Upvoted on event \(i)")
            mutationExpectations.append(upvoteExpectation)

            let mutation = UpvotePostMutation(id: id)

            appSyncClient.perform(mutation: mutation) { result, error in
                XCTAssertNil(error, "Error should be nil")

                guard
                    let result = result,
                    let _ = result.data?.upvotePost
                    else {
                        XCTFail("Result & payload should not be nil")
                        return
                }
                upvoteExpectation.fulfill()
                print("Successful UpvotePostMutation \(i) (\(id))")
            }
            print("Attempting UpvotePostMutation \(i) (\(id))")
        }

        return mutationExpectations
    }

}
