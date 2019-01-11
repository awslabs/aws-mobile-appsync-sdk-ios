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
@testable import AWSCore
@testable import AWSAppSyncTestCommon

/// Uses API_KEY for auth
class AWSAppSyncAPIKeyAuthTests: XCTestCase {
    private static let mutationQueue = DispatchQueue(label: "com.amazonaws.appsync.AWSAppSyncAPIKeyAuthTests.mutationQueue")
    private static let subscriptionAndFetchQueue = DispatchQueue(label: "com.amazonaws.appsync.AWSAppSyncAPIKeyAuthTests.subscriptionAndFetchQueue")

    /// This will be automatically instantiated in `performDefaultSetUpSteps`
    var appSyncClient: AWSAppSyncClient?

    let authType = AppSyncClientTestHelper.AuthenticationType.apiKey

    static func makeAppSyncClient(authType: AppSyncClientTestHelper.AuthenticationType,
                                  databaseURL: URL? = nil) throws -> DeinitNotifiableAppSyncClient {
        let testBundle = Bundle(for: AWSAppSyncAPIKeyAuthTests.self)
        let helper = try AppSyncClientTestHelper(
            with: authType,
            databaseURL: databaseURL,
            testBundle: testBundle
        )
        return helper.appSyncClient
    }

    override func setUp() {
        super.setUp()
        do {
            appSyncClient = try AWSAppSyncAPIKeyAuthTests.makeAppSyncClient(authType: authType)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testClientDeinit() throws {
        let e = expectation(description: "AWSAppSyncClient deinitialized")
        var deinitNotifiableAppSyncClient: DeinitNotifiableAppSyncClient? =
            try AWSAppSyncAPIKeyAuthTests.makeAppSyncClient(authType: .apiKey)

        deinitNotifiableAppSyncClient!.deinitCalled = { e.fulfill() }

        DispatchQueue.global(qos: .background).async { deinitNotifiableAppSyncClient = nil }

        waitForExpectations(timeout: 5)
    }

    func testMutation() {
        let postCreated = expectation(description: "Post created successfully.")
        let addPost = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation

        appSyncClient?.perform(mutation: addPost, queue: AWSAppSyncAPIKeyAuthTests.mutationQueue) { result, error in
            XCTAssertNil(error)
            XCTAssertNotNil(result?.data?.createPostWithoutFileUsingParameters?.id)
            XCTAssertEqual(
                result!.data!.createPostWithoutFileUsingParameters?.author,
                DefaultTestPostData.author
            )
            print("Created post \(result?.data?.createPostWithoutFileUsingParameters?.id ?? "(ID unexpectedly nil)")")
            postCreated.fulfill()
        }

        wait(for: [postCreated], timeout: 5.0)
    }

    func testQuery() {
        let postCreated = expectation(description: "Post created successfully.")
        let addPost = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation

        appSyncClient?.perform(mutation: addPost, queue: AWSAppSyncAPIKeyAuthTests.mutationQueue) { result, error in
            XCTAssertNil(error)
            XCTAssertNotNil(result?.data?.createPostWithoutFileUsingParameters?.id)
            XCTAssertEqual(
                result!.data!.createPostWithoutFileUsingParameters?.author,
                DefaultTestPostData.author
            )
            postCreated.fulfill()
        }

        wait(for: [postCreated], timeout: 10.0)

        let query = ListPostsQuery()

        let listPostsCompleted = expectation(description: "Query done successfully.")

        appSyncClient?.fetch(query: query, cachePolicy: .fetchIgnoringCacheData, queue: AWSAppSyncAPIKeyAuthTests.subscriptionAndFetchQueue) { result, error in
            XCTAssertNil(error)
            XCTAssertNotNil(result?.data?.listPosts)
            XCTAssertGreaterThan(result!.data!.listPosts!.count, 0, "Expected service to return at least 1 post.")
            listPostsCompleted.fulfill()
        }

        wait(for: [listPostsCompleted], timeout: 10.0)
    }

    func testClearCache() {
        let postCreated = expectation(description: "Post created successfully.")
        let addPost = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation

        appSyncClient?.perform(mutation: addPost) { result, error in
            XCTAssertNil(error)
            XCTAssertNotNil(result?.data?.createPostWithoutFileUsingParameters?.id)
            XCTAssertEqual(
                result!.data!.createPostWithoutFileUsingParameters?.author,
                DefaultTestPostData.author
            )
            postCreated.fulfill()
        }

        wait(for: [postCreated], timeout: 5.0)

        let query = ListPostsQuery()

        let listPostsCompleted = expectation(description: "Fetch query ignoring cache")

        appSyncClient?.fetch(query: query, cachePolicy: .fetchIgnoringCacheData) { result, error in
            defer { listPostsCompleted.fulfill() }

            XCTAssertNil(error)
            XCTAssertNotNil(result?.data?.listPosts)
            XCTAssertGreaterThan(result!.data!.listPosts!.count, 0, "Expected service to return at least 1 post.")
        }

        wait(for: [listPostsCompleted], timeout: 5.0)

        do {
            try appSyncClient?.clearCache().await()
        } catch {
            XCTFail()
        }

        let emptyCacheCompleted = expectation(description: "Fetch query from empty cache")

        appSyncClient?.fetch(query: query, cachePolicy: .returnCacheDataDontFetch) { (result, error) in
            defer { emptyCacheCompleted.fulfill() }

            XCTAssertNil(result, "Expected empty cache")
            XCTAssertNil(error, "Expected no error")
        }

        wait(for: [emptyCacheCompleted], timeout: 5.0)
    }

    func testSubscription_Stress() {
        guard let appSyncClient = appSyncClient else {
            XCTFail("appSyncClient should not be nil")
            return
        }
        let subscriptionStressTestHelper = SubscriptionStressTestHelper()
        subscriptionStressTestHelper.stressTestSubscriptions(with: appSyncClient)
    }

    func testSubscription() throws {
        let postCreated = expectation(description: "Post created successfully.")
        let addPost = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation

        var idHolder: GraphQLID?
        appSyncClient?.perform(mutation: addPost, queue: AWSAppSyncAPIKeyAuthTests.mutationQueue) { result, error in
            print("CreatePost result handler invoked")
            XCTAssertNil(error)
            XCTAssertNotNil(result?.data?.createPostWithoutFileUsingParameters?.id)
            XCTAssertEqual(result!.data!.createPostWithoutFileUsingParameters?.author, DefaultTestPostData.author)
            idHolder = result?.data?.createPostWithoutFileUsingParameters?.id
            postCreated.fulfill()
        }
        wait(for: [postCreated], timeout: 10.0)

        guard let id = idHolder else {
            XCTFail("Expected ID from addPost mutation")
            return
        }

        // This handler will be invoked if an error occurs during the setup, or if we receive a successful mutation response.
        let subscriptionResultHandlerInvoked = expectation(description: "Subscription received successfully.")
        var subscription: AWSAppSyncSubscriptionWatcher<OnUpvotePostSubscription>?
        defer {
            subscription?.cancel()
        }

        subscription = try self.appSyncClient?.subscribe(subscription: OnUpvotePostSubscription(id: id),
                                                         queue: AWSAppSyncAPIKeyAuthTests.subscriptionAndFetchQueue) { result, _, error in
                                                            print("Subscription result handler invoked")
                                                            guard error == nil else {
                                                                XCTAssertNil(error)
                                                                return
                                                            }

                                                            guard result != nil else {
                                                                XCTFail("Result was unexpectedly nil")
                                                                return
                                                            }
                                                            subscriptionResultHandlerInvoked.fulfill()
        }
        XCTAssertNotNil(subscription, "Subscription expected to be non nil.")

        // Currently, subscriptions don't have a good way to inspect that they have been registered on the service.
        // We'll check for `getTopics` returning a non-empty value to stand in for a completion handler
        let subscriptionIsRegisteredExpectation = expectation(description: "Upvote subscription should have a non-empty topics list")
        let subscriptionGetTopicsTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) {
            _ in
            guard let subscription = subscription else {
                return
            }

            let topics = subscription.getTopics()

            guard !topics.isEmpty else {
                return
            }

            subscriptionIsRegisteredExpectation.fulfill()
        }
        wait(for: [subscriptionIsRegisteredExpectation], timeout: 10.0)
        subscriptionGetTopicsTimer.invalidate()

        print("Sleeping a few seconds to wait for server to begin delivering subscriptions")
        sleep(5)

        let upvotePerformed = expectation(description: "Upvote mutation performed")
        let upvoteMutation = UpvotePostMutation(id: id)
        self.appSyncClient?.perform(mutation: upvoteMutation, queue: AWSAppSyncAPIKeyAuthTests.mutationQueue) {
            result, error in
            print("Received upvote mutation response.")
            XCTAssertNil(error)
            XCTAssertNotNil(result?.data?.upvotePost?.id)
            upvotePerformed.fulfill()
        }

        wait(for: [upvotePerformed, subscriptionResultHandlerInvoked], timeout: 10.0)
    }

    func testOptimisticWriteWithQueryParameter() {
        let postCreated = expectation(description: "Post created successfully.")
        let successfulMutationEvent2Expectation = expectation(description: "Mutation done successfully.")
        let successfulOptimisticWriteExpectation = expectation(description: "Optimisitc write done successfully.")
        let successfulQueryFetchExpectation = expectation(description: "Query fetch should success.")
        let successfulLocalQueryFetchExpectation = expectation(description: "Local query fetch should success.")

        let addPost = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation

        appSyncClient?.perform(mutation: addPost, queue: AWSAppSyncAPIKeyAuthTests.mutationQueue) { result, error in
            print("CreatePost result handler invoked")
            XCTAssertNil(error)
            XCTAssertNotNil(result?.data?.createPostWithoutFileUsingParameters?.id)
            XCTAssertEqual(result!.data!.createPostWithoutFileUsingParameters?.author, DefaultTestPostData.author)
            postCreated.fulfill()
        }
        wait(for: [postCreated], timeout: 10.0)

        let fetchQuery = ListPostsQuery()

        var cacheCount = 0

        appSyncClient?.fetch(query: fetchQuery,
                             cachePolicy: .fetchIgnoringCacheData,
                             queue: AWSAppSyncAPIKeyAuthTests.subscriptionAndFetchQueue) { result, error in
                                XCTAssertNil(error)
                                XCTAssertNotNil(result?.data?.listPosts)
                                XCTAssertGreaterThan(result?.data?.listPosts?.count ?? 0, 0, "Expected service to return at least 1 event.")
                                cacheCount = result?.data?.listPosts?.count ?? 0
                                successfulQueryFetchExpectation.fulfill()
        }

        wait(for: [successfulQueryFetchExpectation], timeout: 10.0)

        appSyncClient?.perform(mutation: addPost,
                               queue: AWSAppSyncAPIKeyAuthTests.mutationQueue,
                               optimisticUpdate: { transaction in
                                do {
                                    try transaction?.update(query: fetchQuery) { data in
                                        let item = ListPostsQuery.Data.ListPost(
                                            id: "TestItemId",
                                            author: DefaultTestPostData.author,
                                            title: DefaultTestPostData.title,
                                            content: DefaultTestPostData.content,
                                            ups: 0,
                                            downs: 0
                                        )
                                        data.listPosts?.append(item)
                                    }
                                    successfulOptimisticWriteExpectation.fulfill()
                                } catch {
                                    XCTFail("Failed to perform optimistic update: \(error)")
                                }
        },
                               resultHandler: { result, error in
                                XCTAssertNil(error)
                                XCTAssertNotNil(result?.data?.createPostWithoutFileUsingParameters?.id)
                                XCTAssertEqual(result?.data?.createPostWithoutFileUsingParameters?.author, DefaultTestPostData.author)
                                successfulMutationEvent2Expectation.fulfill()
        })

        wait(for: [successfulOptimisticWriteExpectation, successfulMutationEvent2Expectation], timeout: 5.0)

        appSyncClient?.fetch(query: fetchQuery,
                             cachePolicy: .returnCacheDataDontFetch,
                             queue: AWSAppSyncAPIKeyAuthTests.subscriptionAndFetchQueue) { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result?.data?.listPosts)
            XCTAssertGreaterThan(result?.data?.listPosts?.count ?? 0, 0, "Expected cache to return at least 1 event.")
            XCTAssertEqual(result?.data?.listPosts?.count ?? 0, cacheCount + 1)
            successfulLocalQueryFetchExpectation.fulfill()
        }

        wait(for: [successfulLocalQueryFetchExpectation], timeout: 10.0)
    }

    // Validates that queries are invoked and returned as expected during initial setup and
    // reconnection flows
    func testSyncOperationAtSetupAndReconnect() throws {
        // Let result handlers inspect the current phase of the sync watcher's "lifecycle" so they can properly fulfill
        // expectations
        var _currentSyncWatcherLifecyclePhase = SyncWatcherLifecyclePhase.setUp
        func currentSyncWatcherLifecyclePhase() -> SyncWatcherLifecyclePhase {
            return _currentSyncWatcherLifecyclePhase
        }

        // This tests needs a physical DB for the SubscriptionMetadataCache to properly return a "lastSynced" value.
        let databaseURL = URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent("testSyncOperationAtSetupAndReconnect-appsync-local-db")
        try? FileManager.default.removeItem(at: databaseURL)

        let appSyncClient = try AWSAppSyncAPIKeyAuthTests.makeAppSyncClient(
            authType: self.authType,
            databaseURL: databaseURL
        )

        var syncWatcher: Cancellable?
        defer {
            syncWatcher?.cancel()
        }

        let baseRefreshIntervalInSeconds = 86_400

        let postCreated = expectation(description: "Post created successfully.")
        let addPost = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation

        var idHolder: GraphQLID?
        appSyncClient.perform(mutation: addPost) { result, error in
            print("CreatePost result handler invoked")
            XCTAssertNil(error)
            XCTAssertNotNil(result?.data?.createPostWithoutFileUsingParameters?.id)
            XCTAssertEqual(result!.data!.createPostWithoutFileUsingParameters?.author, DefaultTestPostData.author)
            idHolder = result?.data?.createPostWithoutFileUsingParameters?.id
            postCreated.fulfill()
        }
        wait(for: [postCreated], timeout: 10.0)

        guard let id = idHolder else {
            XCTFail("Expected ID from addPost mutation")
            return
        }

        // Set up the expectations for the initial connection (simulates the first time the app was launched)
        let initialBaseQueryHandlerShouldBeInvokedToHydrateFromCache =
            expectation(description: "Initial base query result handler should be invoked to hydrate subscription from cache")

        let initialBaseQueryShouldBeInvokedToPopulateFromService =
            expectation(description: "Initial base query result handler should be invoked to populate subscription from service")

        let initialBaseQueryShouldNotBeInvokedDuringMonitoring =
            expectation(description: "Initial base query result handler should not be invoked during monitoring")
        initialBaseQueryShouldNotBeInvokedDuringMonitoring.isInverted = true

        let initialSubscriptionHandlerShouldNotBeInvokedDuringSetup =
            expectation(description: "Initial subscription query result handler should not be invoked during setup")
        initialSubscriptionHandlerShouldNotBeInvokedDuringSetup.isInverted = true

        let initialSubscriptionHandlerShouldBeInvokedDuringMonitoring =
            expectation(description: "Initial subscription query result handler should be invoked during monitoring")

        let initialDeltaHandlerShouldNotBeInvokedDuringSetup =
            expectation(description: "Initial delta query result handler should not be invoked during setup")
        initialDeltaHandlerShouldNotBeInvokedDuringSetup.isInverted = true

        let initialDeltaHandlerShouldNotBeInvokedDuringMonitoring =
            expectation(description: "Initial delta query result handler should not be invoked during monitoring")
        initialDeltaHandlerShouldNotBeInvokedDuringMonitoring.isInverted = true

        var initialBaseQueryResultHandlerInvocationCount = 0

        let initialBaseQueryResultHandler: (GraphQLResult<ListPostsQuery.Data>?, Error?) -> Void = {
            result, error in
            print("Initial base query result handler invoked during phase \(currentSyncWatcherLifecyclePhase())")
            XCTAssertNil(error)
            initialBaseQueryResultHandlerInvocationCount += 1

            switch currentSyncWatcherLifecyclePhase() {
            case .setUp:
                if (initialBaseQueryResultHandlerInvocationCount == 1) {
                    initialBaseQueryHandlerShouldBeInvokedToHydrateFromCache.fulfill()
                    XCTAssertNil(result)
                } else if initialBaseQueryResultHandlerInvocationCount == 2 {
                    XCTAssertNotNil(result)
                    initialBaseQueryShouldBeInvokedToPopulateFromService.fulfill()
                } else {
                    XCTFail("Expecting only 2 invocations of base query result operation, but got \(initialBaseQueryResultHandlerInvocationCount).")
                }
            case .monitoring:
                initialBaseQueryShouldNotBeInvokedDuringMonitoring.fulfill()
            }
        }

        let initialSubscriptionResultHandler: (GraphQLResult<OnUpvotePostSubscription.Data>?, ApolloStore.ReadWriteTransaction?, Error?) -> Void = {
            result, transaction, error in
            print("Initial subscription result handler invoked")
            XCTAssertNotNil(result)
            XCTAssertNotNil(transaction)
            XCTAssertNil(error)
            switch currentSyncWatcherLifecyclePhase() {
            case .setUp:
                initialSubscriptionHandlerShouldNotBeInvokedDuringSetup.fulfill()
            case .monitoring:
                initialSubscriptionHandlerShouldBeInvokedDuringMonitoring.fulfill()
            }
        }

        let initialDeltaQueryResultHandler: (GraphQLResult<ListPostsQuery.Data>?, ApolloStore.ReadWriteTransaction?, Error?) -> Void = {
            _, _, _ in
            print("Initial delta query result handler invoked unexpectedly")
            switch currentSyncWatcherLifecyclePhase() {
            case .setUp:
                initialDeltaHandlerShouldNotBeInvokedDuringSetup.fulfill()
            case .monitoring:
                initialDeltaHandlerShouldNotBeInvokedDuringMonitoring.fulfill()
            }
        }

        // Refresh interval defaults to one day, but we'll make it explicit here in case that changes in the future
        let syncConfiguration = SyncConfiguration(baseRefreshIntervalInSeconds: baseRefreshIntervalInSeconds)

        let listPostsQuery = ListPostsQuery()
        let subscription = OnUpvotePostSubscription(id: id)

        syncWatcher = appSyncClient.sync(
            baseQuery: listPostsQuery,
            baseQueryResultHandler: initialBaseQueryResultHandler,
            subscription: subscription,
            subscriptionResultHandler: initialSubscriptionResultHandler,
            deltaQuery: listPostsQuery,
            deltaQueryResultHandler: initialDeltaQueryResultHandler,
            syncConfiguration: syncConfiguration
        )

        XCTAssertNotNil(syncWatcher, "Initial subscription sync watcher expected to be non nil.")

        // Wait to ensure the new watcher is properly initialized. We don't expect the delta query expectation to be fulfilled
        // during either initialization or subsequent subscription. However, we're only allowed to `wait` on an expectation one
        // time, so we'll wait on the "setup" expectation here, and the "monitoring" expectation below
        wait(
            for: [
                initialBaseQueryHandlerShouldBeInvokedToHydrateFromCache,
                initialBaseQueryShouldBeInvokedToPopulateFromService,
                initialSubscriptionHandlerShouldNotBeInvokedDuringSetup,
                initialDeltaHandlerShouldNotBeInvokedDuringSetup
            ],
            timeout: 10.0
        )

        // Now that we've subscribed, mutate the post to trigger the subscription
        _currentSyncWatcherLifecyclePhase = .monitoring
        let firstUpvoteMutation = UpvotePostMutation(id: id)
        let firstUpvoteComplete = expectation(description: "First upvote should be completed on service")

        // Wait 3 seconds to ensure sync/subscription is active, then trigger the mutation
        DispatchQueue.global().async {
            sleep(3)
            self.appSyncClient?.perform(mutation: firstUpvoteMutation,
                                        queue: AWSAppSyncAPIKeyAuthTests.mutationQueue) { result, error in
                print("Received first upvote mutation response")
                XCTAssertNil(error)
                XCTAssertNotNil(result?.data?.upvotePost?.id)
                firstUpvoteComplete.fulfill()
            }
        }

        wait(
            for: [
                firstUpvoteComplete,
                initialBaseQueryShouldNotBeInvokedDuringMonitoring,
                initialSubscriptionHandlerShouldBeInvokedDuringMonitoring,
                initialDeltaHandlerShouldNotBeInvokedDuringMonitoring
            ],
            timeout: 10.0
        )

        // Cancel the syncWatcher to simulate an app restart
        syncWatcher?.cancel()
        _currentSyncWatcherLifecyclePhase = .setUp

        // Now set up the expectations for the "restarted" app
        let restartedBaseQueryHandlerShouldBeInvokedToHydrateFromCache =
            expectation(description: "Restarted base query result handler should be invoked to hydrate subscription from cache")

        let restartedBaseQueryShouldNotBeInvokedToPopulateFromService =
            expectation(description: "Restarted base query result handler should not be invoked to populate subscription from service since it is within deltaSync refresh time")
        restartedBaseQueryShouldNotBeInvokedToPopulateFromService.isInverted = true

        let restartedBaseQueryShouldNotBeInvokedDuringMonitoring =
            expectation(description: "Restarted base query result handler should not be invoked during monitoring")
        restartedBaseQueryShouldNotBeInvokedDuringMonitoring.isInverted = true

        let restartedSubscriptionHandlerShouldNotBeInvokedDuringSetup =
            expectation(description: "Restarted subscription query result handler should not be invoked during setup")
        restartedSubscriptionHandlerShouldNotBeInvokedDuringSetup.isInverted = true

        let restartedSubscriptionHandlerShouldBeInvokedDuringMonitoring =
            expectation(description: "Restarted subscription query result handler should be invoked during monitoring")

        let restartedDeltaHandlerShouldBeInvokedDuringSetup =
            expectation(description: "Restarted delta query result handler should not be invoked during setup")

        let restartedDeltaHandlerShouldNotBeInvokedDuringMonitoring =
            expectation(description: "Restarted delta query result handler should not be invoked during monitoring")
        restartedDeltaHandlerShouldNotBeInvokedDuringMonitoring.isInverted = true

        var restartedBaseQueryResultHandlerInvocationCount = 0

        let restartedBaseQueryResultHandler: (GraphQLResult<ListPostsQuery.Data>?, Error?) -> Void = {
            result, error in
            print("Restarted base query result handler invoked")
            XCTAssertNotNil(result)
            XCTAssertNil(error)

            switch currentSyncWatcherLifecyclePhase() {
            case .setUp:
                restartedBaseQueryResultHandlerInvocationCount += 1
                if (restartedBaseQueryResultHandlerInvocationCount == 1) {
                    restartedBaseQueryHandlerShouldBeInvokedToHydrateFromCache.fulfill()
                } else if restartedBaseQueryResultHandlerInvocationCount == 2 {
                    restartedBaseQueryShouldNotBeInvokedToPopulateFromService.fulfill()
                } else {
                    XCTFail("Expecting only 2 invocations of base query result operation, but got \(restartedBaseQueryResultHandlerInvocationCount).")
                }
            case .monitoring:
                restartedBaseQueryShouldNotBeInvokedDuringMonitoring.fulfill()
            }
        }

        let restartedSubscriptionResultHandler: (GraphQLResult<OnUpvotePostSubscription.Data>?, ApolloStore.ReadWriteTransaction?, Error?) -> Void = {
            result, transaction, error in
            print("Restarted subscription result handler invoked")
            XCTAssertNotNil(result)
            XCTAssertNotNil(transaction)
            XCTAssertNil(error)
            switch currentSyncWatcherLifecyclePhase() {
            case .setUp:
                restartedSubscriptionHandlerShouldNotBeInvokedDuringSetup.fulfill()
            case .monitoring:
                restartedSubscriptionHandlerShouldBeInvokedDuringMonitoring.fulfill()
            }
        }

        let restartedDeltaQueryResultHandler: (GraphQLResult<ListPostsQuery.Data>?, ApolloStore.ReadWriteTransaction?, Error?) -> Void = {
            result, transaction, error in
            print("Restarted delta query result handler invoked")
            XCTAssertNotNil(result)
            XCTAssertNotNil(transaction)
            XCTAssertNil(error)
            switch currentSyncWatcherLifecyclePhase() {
            case .setUp:
                restartedDeltaHandlerShouldBeInvokedDuringSetup.fulfill()
            case .monitoring:
                restartedDeltaHandlerShouldNotBeInvokedDuringMonitoring.fulfill()
            }
        }

        syncWatcher = appSyncClient.sync(
            baseQuery: listPostsQuery,
            baseQueryResultHandler: restartedBaseQueryResultHandler,
            subscription: subscription,
            subscriptionResultHandler: restartedSubscriptionResultHandler,
            deltaQuery: listPostsQuery,
            deltaQueryResultHandler: restartedDeltaQueryResultHandler,
            syncConfiguration: syncConfiguration
        )

        XCTAssertNotNil(syncWatcher, "Restart sync watcher expected to be non nil")

        // Wait to ensure the new watcher is properly initialized
        wait(
            for: [
                restartedBaseQueryHandlerShouldBeInvokedToHydrateFromCache,
                restartedBaseQueryShouldNotBeInvokedToPopulateFromService,
                restartedSubscriptionHandlerShouldNotBeInvokedDuringSetup,
                restartedDeltaHandlerShouldBeInvokedDuringSetup
            ],
            timeout: 10.0
        )

        // Trigger the restarted watcher's subscription
        _currentSyncWatcherLifecyclePhase = .monitoring
        let secondUpvoteMutation = UpvotePostMutation(id: id)
        let secondUpvoteComplete = expectation(description: "Second upvote should be completed on service")

        // Wait 3 seconds to ensure sync/subscription is active, then trigger the mutation
        DispatchQueue.global().async {
            sleep(3)
            self.appSyncClient?.perform(mutation: secondUpvoteMutation,
                                        queue: AWSAppSyncAPIKeyAuthTests.mutationQueue) { result, error in
                print("Received second upvote mutation response")
                XCTAssertNil(error)
                XCTAssertNotNil(result?.data?.upvotePost?.id)
                secondUpvoteComplete.fulfill()
            }
        }

        wait(
            for: [
                secondUpvoteComplete,
                restartedBaseQueryShouldNotBeInvokedDuringMonitoring,
                restartedSubscriptionHandlerShouldBeInvokedDuringMonitoring,
                restartedDeltaHandlerShouldNotBeInvokedDuringMonitoring
            ],
            timeout: 10.0
        )

    }

}

private enum SyncWatcherLifecyclePhase {
    case setUp
    case monitoring
}
