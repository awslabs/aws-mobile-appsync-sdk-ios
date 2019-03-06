//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import XCTest
@testable import AWSAppSync
@testable import AWSAppSyncTestCommon

class SubscriptionStressTestHelper: XCTestCase {
    private static let numberOfPostsToTest = 40
    private static let networkOperationTimeout = TimeInterval(exactly: numberOfPostsToTest * 2)!

    private static let mutationQueue = DispatchQueue(label: "com.amazonaws.appsync.SubscriptionStressTestHelper.mutationQueue")
    private static let subscriptionQueue = DispatchQueue(label: "com.amazonaws.appsync.SubscriptionStressTestHelper.subscriptionQueue")

    private var appSyncClient: AWSAppSyncClient!

    // Hold onto this to retain references to the watchers during the test invocation
    private var subscriptionTestStateHolders = [GraphQLID: SubscriptionTestStateHolder]()

    // MARK: - Public test helper methods

    func stressTestSubscriptions(with appSyncClient: AWSAppSyncClient,
                                 delayBetweenSubscriptions delay: TimeInterval? = nil) {
        defer {
            subscriptionTestStateHolders.values.forEach { $0.watcher?.cancel() }
        }

        self.appSyncClient = appSyncClient

        createPostsAndPopulateTestStateHolders()

        XCTAssertEqual(subscriptionTestStateHolders.count, SubscriptionStressTestHelper.numberOfPostsToTest)

        // Add subscriptions for each of the created posts. The expectations will be fulfilled
        // after the mutations are generated below.
        subscribeToMutationsAndMakeExpectations(delayBetweenSubscriptions: delay)

        let allPostsUpvoted = subscriptionTestStateHolders.values.map { $0.postUpvoted! }
        let allSubscriptionsAcknowledged = subscriptionTestStateHolders.values.map { $0.subscriptionAcknowledged! }
        let allSubscriptionsTriggered = subscriptionTestStateHolders.values.map { $0.subscriptionTriggered! }

        let timeoutFactor: TimeInterval
        if let delay = delay, delay > 1.0 {
            timeoutFactor = delay * 2.0
        } else {
            timeoutFactor = 2.0
        }

        let allExpectations = allSubscriptionsAcknowledged + allPostsUpvoted + allSubscriptionsTriggered
        wait(for: allExpectations, timeout: SubscriptionStressTestHelper.networkOperationTimeout * timeoutFactor)
    }

    // MARK: - Private utility methods

    /// Asynchronously populate `subscriptionTestStateHolders` with new state holders
    private func createPostsAndPopulateTestStateHolders() {
        // Hold onto these expectations so we can create the mutations prior to returning
        var allPostsAreCreatedExpectations = [XCTestExpectation]()
        for i in 0 ..< SubscriptionStressTestHelper.numberOfPostsToTest {
            let testData = SubscriptionTestStateHolder(index: i)

            allPostsAreCreatedExpectations.append(testData.postCreated)

            appSyncClient.perform(mutation: DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation,
                                  queue: SubscriptionStressTestHelper.mutationQueue) { result, error in
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
                                    self.subscriptionTestStateHolders[id] = testData
                                    testData.postId = id
                                    testData.postCreated.fulfill()
                                    print("Post created \(i) (\(id))")
            }
        }

        wait(for: allPostsAreCreatedExpectations, timeout: SubscriptionStressTestHelper.networkOperationTimeout)
    }

    /// Schedule subscription and mutation flows for each subscriptionTestStateHolder, with `delay` seconds in between
    /// each subscription operation
    private func subscribeToMutationsAndMakeExpectations(delayBetweenSubscriptions delay: TimeInterval?) {
        let createSubscriptionsQueue = DispatchQueue(label: "subscribeToMutationsAndMakeExpectations")
        let subscriptionTestStateHolderValues = subscriptionTestStateHolders.values.map { $0 }
        createSubscriptionsQueue.async {
            for i in 0 ..< SubscriptionStressTestHelper.numberOfPostsToTest {
                let subscriptionTestStateHolder = subscriptionTestStateHolderValues[i]
                self.subscribeAcknowledgeAndMutate(subscriptionTestStateHolder: subscriptionTestStateHolder)
                if let delay = delay, delay > 0.0 {
                    Thread.sleep(forTimeInterval: delay)
                }
            }
        }
    }

    private func subscribeAcknowledgeAndMutate(subscriptionTestStateHolder: SubscriptionTestStateHolder) {
        let subscription: OnUpvotePostSubscription = OnUpvotePostSubscription(id: subscriptionTestStateHolder.postId)

        let statusChangeHandler: SubscriptionStatusChangeHandler = { status in
            if case .connected = status {
                print("Subscription acknowledged \(subscriptionTestStateHolder.index) (\(subscriptionTestStateHolder.postId!))")
                subscriptionTestStateHolder.subscriptionAcknowledged.fulfill()
                self.mutatePost(for: subscriptionTestStateHolder)
            }
        }

        print("Subscribing \(subscriptionTestStateHolder.index) (\(subscriptionTestStateHolder.postId!))")
        let optionalSubscriptionWatcher = try! appSyncClient.subscribe(
            subscription: subscription,
            queue: SubscriptionStressTestHelper.subscriptionQueue,
            statusChangeHandler: statusChangeHandler
        ) {
            result, _, error in
            XCTAssertNil(error, "Error should be nil")

            guard result?.data?.onUpvotePost != nil else {
                XCTFail("Result & payload should not be nil")
                return
            }

            subscriptionTestStateHolder.subscriptionTriggered.fulfill()
            print("Subscription triggered \(subscriptionTestStateHolder.index) (\(subscriptionTestStateHolder.postId!))")
        }

        guard let subscriptionWatcher = optionalSubscriptionWatcher else {
            XCTFail("Subscription watcher \(subscriptionTestStateHolder.index) (\(subscriptionTestStateHolder.postId!)) should not be nil")
            return
        }

        subscriptionTestStateHolder.watcher = subscriptionWatcher
    }

    /// Mutate the watched objects by upvoting them. This should fire each associated subscription
    /// We set up mutation expectations so that, if the test fails, we can tell whether it was the
    /// mutation that failed to complete, or the subscription that failed to trigger
    private func mutatePost(for subscriptionTestStateHolder: SubscriptionTestStateHolder) {
        let postId = subscriptionTestStateHolder.postId!
        let mutation = UpvotePostMutation(id: postId)

        appSyncClient.perform(mutation: mutation, queue: SubscriptionStressTestHelper.mutationQueue) { result, error in
            XCTAssertNil(error, "Error should be nil")

            guard
                let result = result,
                let _ = result.data?.upvotePost
                else {
                    XCTFail("Result & payload should not be nil")
                    return
            }
            print("Post upvoted \(subscriptionTestStateHolder.index) (\(subscriptionTestStateHolder.postId!))")
            subscriptionTestStateHolder.postUpvoted.fulfill()
        }

    }

}

// A state holder for the various stages of a subscription test, built up by each operation
private class SubscriptionTestStateHolder {
    let index: Int
    var postId: GraphQLID! {
        didSet {
            self.subscriptionAcknowledged = XCTestExpectation(description: "subscriptionAcknowledged for \(index) (\(postId!))")
            self.postUpvoted = XCTestExpectation(description: "postUpvoted for \(index) (\(postId!))")
            self.subscriptionTriggered = XCTestExpectation(description: "subscriptionTriggered for \(index) (\(postId!))")
        }
    }

    var watcher: AWSAppSyncSubscriptionWatcher<OnUpvotePostSubscription>!
    let postCreated: XCTestExpectation

    // These are created after the postId is set
    var subscriptionAcknowledged: XCTestExpectation!
    var postUpvoted: XCTestExpectation!
    var subscriptionTriggered: XCTestExpectation!

    init(index: Int) {
        self.index = index
        postCreated = XCTestExpectation(description: "postCreated for \(index)")
    }
}
