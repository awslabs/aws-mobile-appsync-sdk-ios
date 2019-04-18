//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import XCTest
@testable import AWSAppSync
@testable import AWSCore
@testable import AWSAppSyncTestCommon

/// Uses API_KEY for auth
class AWSAppSyncAPIKeyAuthTests: XCTestCase {

    // MARK: - Properties

    /// Use this as our timeout value for any operation that hits the network. Note that this may need to be higher
    /// than you think, to account for CI systems running in shared environments
    private static let networkOperationTimeout = 180.0

    private static let mutationQueue = DispatchQueue(label: "com.amazonaws.appsync.AWSAppSyncAPIKeyAuthTests.mutationQueue")
    private static let subscriptionAndFetchQueue = DispatchQueue(label: "com.amazonaws.appsync.AWSAppSyncAPIKeyAuthTests.subscriptionAndFetchQueue")

    /// This will be automatically instantiated in `performDefaultSetUpSteps`
    var appSyncClient: AWSAppSyncClient?

    let authType = AppSyncClientTestHelper.AuthenticationType.apiKey

    override func setUp() {
        super.setUp()
        do {
            appSyncClient = try AWSAppSyncAPIKeyAuthTests.makeAppSyncClient(authType: authType)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // MARK: - Tests

    func testClientDeinit() throws {
        let deinitCalled = expectation(description: "AWSAppSyncClient deinitialized")
        var deinitNotifiableAppSyncClient: DeinitNotifiableAppSyncClient? =
            try AWSAppSyncAPIKeyAuthTests.makeAppSyncClient(authType: .apiKey)

        deinitNotifiableAppSyncClient!.deinitCalled = { deinitCalled.fulfill() }

        DispatchQueue.global(qos: .background).async { deinitNotifiableAppSyncClient = nil }

        waitForExpectations(timeout: 5.0)
    }

    func testClientDeinitAfterMutation() throws {
        let deinitCalled = expectation(description: "AWSAppSyncClient deinitialized")
        var deinitNotifiableAppSyncClient: DeinitNotifiableAppSyncClient? =
            try AWSAppSyncAPIKeyAuthTests.makeAppSyncClient(authType: .apiKey)

        deinitNotifiableAppSyncClient!.deinitCalled = { deinitCalled.fulfill() }

        let postCreated = expectation(description: "Post created successfully.")
        let addPost = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation

        deinitNotifiableAppSyncClient?.perform(mutation: addPost, queue: AWSAppSyncAPIKeyAuthTests.mutationQueue) { result, error in
            postCreated.fulfill()
        }

        // Wait for mutation to return before releasing client
        wait(for: [postCreated], timeout: AWSAppSyncAPIKeyAuthTests.networkOperationTimeout)

        deinitNotifiableAppSyncClient = nil
        wait(for: [deinitCalled], timeout: 5.0)
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

        wait(for: [postCreated], timeout: AWSAppSyncAPIKeyAuthTests.networkOperationTimeout)
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

        wait(for: [postCreated], timeout: AWSAppSyncAPIKeyAuthTests.networkOperationTimeout)

        let query = ListPostsQuery()

        let listPostsCompleted = expectation(description: "Query done successfully.")

        appSyncClient?.fetch(query: query, cachePolicy: .fetchIgnoringCacheData, queue: AWSAppSyncAPIKeyAuthTests.subscriptionAndFetchQueue) { result, error in
            XCTAssertNil(error)
            XCTAssertNotNil(result?.data?.listPosts)
            XCTAssertGreaterThan(result!.data!.listPosts!.count, 0, "Expected service to return at least 1 post.")
            listPostsCompleted.fulfill()
        }

        wait(for: [listPostsCompleted], timeout: AWSAppSyncAPIKeyAuthTests.networkOperationTimeout)
    }

    func testClearCache() {
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

        wait(for: [postCreated], timeout: AWSAppSyncAPIKeyAuthTests.networkOperationTimeout)

        let query = ListPostsQuery()

        let listPostsCompleted = expectation(description: "Fetch query ignoring cache")

        appSyncClient?.fetch(query: query,
                             cachePolicy: .fetchIgnoringCacheData,
                             queue: AWSAppSyncAPIKeyAuthTests.subscriptionAndFetchQueue) { result, error in
            defer { listPostsCompleted.fulfill() }

            XCTAssertNil(error)
            XCTAssertNotNil(result?.data?.listPosts)
            XCTAssertGreaterThan(result!.data!.listPosts!.count, 0, "Expected service to return at least 1 post.")
        }

        wait(for: [listPostsCompleted], timeout: AWSAppSyncAPIKeyAuthTests.networkOperationTimeout)

        do {
            try appSyncClient?.clearCache().await()
        } catch {
            XCTFail()
        }

        let emptyCacheCompleted = expectation(description: "Fetch query from empty cache")

        appSyncClient?.fetch(query: query,
                             cachePolicy: .returnCacheDataDontFetch,
                             queue: AWSAppSyncAPIKeyAuthTests.subscriptionAndFetchQueue) { (result, error) in
            defer { emptyCacheCompleted.fulfill() }

            XCTAssertNil(result, "Expected empty cache")
            XCTAssertNil(error, "Expected no error")
        }

        wait(for: [emptyCacheCompleted], timeout: AWSAppSyncAPIKeyAuthTests.networkOperationTimeout)
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
        wait(for: [postCreated], timeout: AWSAppSyncAPIKeyAuthTests.networkOperationTimeout)

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

        wait(for: [successfulQueryFetchExpectation], timeout: AWSAppSyncAPIKeyAuthTests.networkOperationTimeout)

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

        wait(for: [successfulOptimisticWriteExpectation, successfulMutationEvent2Expectation], timeout: AWSAppSyncAPIKeyAuthTests.networkOperationTimeout)

        appSyncClient?.fetch(query: fetchQuery,
                             cachePolicy: .returnCacheDataDontFetch,
                             queue: AWSAppSyncAPIKeyAuthTests.subscriptionAndFetchQueue) { (result, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(result?.data?.listPosts)
            XCTAssertGreaterThan(result?.data?.listPosts?.count ?? 0, 0, "Expected cache to return at least 1 event.")
            XCTAssertEqual(result?.data?.listPosts?.count ?? 0, cacheCount + 1)
            successfulLocalQueryFetchExpectation.fulfill()
        }

        wait(for: [successfulLocalQueryFetchExpectation], timeout: 5.0)
    }

    // Validates that queries are invoked and returned as expected during initial setup and
    // reconnection flows
    func testSyncOperationAtSetupAndReconnect() throws {
        // Let result handlers inspect the current phase of the sync watcher's "lifecycle" so they can properly fulfill
        // expectations
        var _currentSyncWatcherLifecyclePhase = SyncWatcherLifecyclePhase.baseQueryNotYetComplete
        func currentSyncWatcherLifecyclePhase() -> SyncWatcherLifecyclePhase {
            return _currentSyncWatcherLifecyclePhase
        }

        // This tests needs a physical DB for the SubscriptionMetadataCache to properly return a "lastSynced" value.
        let rootDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("testSyncOperationAtSetupAndReconnect")
        try? FileManager.default.removeItem(at: rootDirectory)
        let cacheConfiguration = try AWSAppSyncCacheConfiguration(withRootDirectory: rootDirectory)

        let appSyncClient = try AWSAppSyncAPIKeyAuthTests.makeAppSyncClient(
            authType: self.authType,
            cacheConfiguration: cacheConfiguration
        )

        var syncWatcher: Cancellable?
        defer {
            syncWatcher?.cancel()
        }

        let baseRefreshIntervalInSeconds = 86_400

        let postCreated = expectation(description: "Post created successfully.")
        let addPost = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation

        var idHolder: GraphQLID?
        appSyncClient.perform(mutation: addPost, queue: AWSAppSyncAPIKeyAuthTests.mutationQueue) { result, error in
            print("CreatePost result handler invoked")
            XCTAssertNil(error)
            XCTAssertNotNil(result?.data?.createPostWithoutFileUsingParameters?.id)
            XCTAssertEqual(result!.data!.createPostWithoutFileUsingParameters?.author, DefaultTestPostData.author)
            idHolder = result?.data?.createPostWithoutFileUsingParameters?.id
            postCreated.fulfill()
        }
        wait(for: [postCreated], timeout: AWSAppSyncAPIKeyAuthTests.networkOperationTimeout)

        guard let id = idHolder else {
            XCTFail("Expected ID from addPost mutation")
            return
        }

        // Set up the expectations for the initial connection (simulates the first time the app was launched)
        let initialBaseQueryHandlerShouldBeInvokedToHydrateFromCache =
            expectation(description: "Initial base query result handler should be invoked to hydrate subscription from cache")

        let initialBaseQueryShouldBeInvokedToPopulateFromService =
            expectation(description: "Initial base query result handler should be invoked to populate subscription from service")

        let initialBaseQueryShouldNotBeInvokedAgainAfterCompleted =
            expectation(description: "Initial base query result handler should not be invoked after it has successfully completed")
        initialBaseQueryShouldNotBeInvokedAgainAfterCompleted.isInverted = true

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

        let initialBaseQueryResultHandler: (GraphQLResult<ListPostsQuery.Data>?, Error?) -> Void = {
            result, error in
            print("Initial base query result handler invoked during phase \(currentSyncWatcherLifecyclePhase())")
            XCTAssertNil(error)

            switch currentSyncWatcherLifecyclePhase() {
            case .baseQueryNotYetComplete:
                switch result?.source {
                case .none:
                    // We get a .none source hydrating from an empty cache
                    initialBaseQueryHandlerShouldBeInvokedToHydrateFromCache.fulfill()
                    XCTAssertNil(result)
                case .some(let source):
                    switch source {
                    case .cache:
                        // This would be unexpected for an empty cache, but we will include the case here in case
                        // we change that behavior in future
                        initialBaseQueryHandlerShouldBeInvokedToHydrateFromCache.fulfill()
                        XCTAssertNotNil(result)
                    case .server:
                        initialBaseQueryShouldBeInvokedToPopulateFromService.fulfill()
                        _currentSyncWatcherLifecyclePhase = .baseQueryComplete
                        XCTAssertNotNil(result)
                    }
                }
            case .baseQueryComplete:
                initialBaseQueryShouldNotBeInvokedAgainAfterCompleted.fulfill()
            case .monitoringSubscriptions:
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
            case .baseQueryNotYetComplete:
                initialSubscriptionHandlerShouldNotBeInvokedDuringSetup.fulfill()
            case .baseQueryComplete:
                initialSubscriptionHandlerShouldNotBeInvokedDuringSetup.fulfill()
            case .monitoringSubscriptions:
                initialSubscriptionHandlerShouldBeInvokedDuringMonitoring.fulfill()
            }
        }

        let initialDeltaQueryResultHandler: (GraphQLResult<ListPostsQuery.Data>?, ApolloStore.ReadWriteTransaction?, Error?) -> Void = {
            _, _, _ in
            print("Initial delta query result handler invoked unexpectedly")
            switch currentSyncWatcherLifecyclePhase() {
            case .baseQueryNotYetComplete:
                initialDeltaHandlerShouldNotBeInvokedDuringSetup.fulfill()
            case .baseQueryComplete:
                // This case is allowable--if the test environment fails and retries the base query (e.g., due to a
                // transient network error), the delta query would be invoked. We will leave the
                // "baseQueryNotYetComplete" case above though, since we want to ensure that the delta query always
                // returns after the base query
                break
            case .monitoringSubscriptions:
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
                initialBaseQueryShouldBeInvokedToPopulateFromService
            ],
            timeout: AWSAppSyncAPIKeyAuthTests.networkOperationTimeout
        )

        // We aren't going to sit and wait for the other handlers *not* to be invoked. As long as they aren't invoked
        // before the initial base queries are done, we're comfortable that the correct order of operations is being
        // preserved. Use this to simply assert that they weren't invoked while waiting for the initial setup to
        // complete
        wait(
            for: [
                initialBaseQueryShouldNotBeInvokedAgainAfterCompleted,
                initialSubscriptionHandlerShouldNotBeInvokedDuringSetup,
                initialDeltaHandlerShouldNotBeInvokedDuringSetup
            ],
            timeout: 0.1
        )

        // Now that we've subscribed, mutate the post to trigger the subscription
        _currentSyncWatcherLifecyclePhase = .monitoringSubscriptions
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
                initialSubscriptionHandlerShouldBeInvokedDuringMonitoring,
            ],
            timeout: AWSAppSyncAPIKeyAuthTests.networkOperationTimeout
        )
        wait(
            for: [
                initialBaseQueryShouldNotBeInvokedDuringMonitoring,
                initialDeltaHandlerShouldNotBeInvokedDuringMonitoring
            ],
            timeout: 0.1
        )

        // Cancel the syncWatcher to simulate an app restart
        syncWatcher?.cancel()
        _currentSyncWatcherLifecyclePhase = .baseQueryNotYetComplete

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
            expectation(description: "Restarted delta query result handler should be invoked during setup")

        let restartedDeltaHandlerShouldNotBeInvokedDuringMonitoring =
            expectation(description: "Restarted delta query result handler should not be invoked during monitoring")
        restartedDeltaHandlerShouldNotBeInvokedDuringMonitoring.isInverted = true

        let restartedBaseQueryResultHandler: (GraphQLResult<ListPostsQuery.Data>?, Error?) -> Void = {
            result, error in
            print("Restarted base query result handler invoked")
            guard let result = result else {
                XCTFail("result unexpectedly nil in restartedBaseQueryResultHandler")
                return
            }
            XCTAssertNil(error)

            switch currentSyncWatcherLifecyclePhase() {
            case .baseQueryNotYetComplete:
                switch result.source {
                case .cache:
                    restartedBaseQueryHandlerShouldBeInvokedToHydrateFromCache.fulfill()
                case .server:
                    restartedBaseQueryShouldNotBeInvokedToPopulateFromService.fulfill()
                }
            case .baseQueryComplete:
                restartedBaseQueryShouldNotBeInvokedToPopulateFromService.fulfill()
            case .monitoringSubscriptions:
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
            case .baseQueryNotYetComplete:
                restartedSubscriptionHandlerShouldNotBeInvokedDuringSetup.fulfill()
            case .baseQueryComplete:
                restartedSubscriptionHandlerShouldNotBeInvokedDuringSetup.fulfill()
            case .monitoringSubscriptions:
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
            case .baseQueryNotYetComplete:
                restartedDeltaHandlerShouldBeInvokedDuringSetup.fulfill()
            case .baseQueryComplete:
                restartedDeltaHandlerShouldBeInvokedDuringSetup.fulfill()
            case .monitoringSubscriptions:
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
                restartedDeltaHandlerShouldBeInvokedDuringSetup
            ],
            timeout: AWSAppSyncAPIKeyAuthTests.networkOperationTimeout
        )
        wait(
            for: [
                restartedBaseQueryShouldNotBeInvokedToPopulateFromService,
                restartedSubscriptionHandlerShouldNotBeInvokedDuringSetup
            ],
            timeout: 0.1
        )

        // Trigger the restarted watcher's subscription
        _currentSyncWatcherLifecyclePhase = .monitoringSubscriptions
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
                restartedSubscriptionHandlerShouldBeInvokedDuringMonitoring
            ],
            timeout: AWSAppSyncAPIKeyAuthTests.networkOperationTimeout
        )
        wait(
            for: [
                restartedBaseQueryShouldNotBeInvokedDuringMonitoring,
                restartedDeltaHandlerShouldNotBeInvokedDuringMonitoring
            ],
            timeout: 0.1
        )

    }

    // MARK: - Utilities

    static func makeAppSyncClient(authType: AppSyncClientTestHelper.AuthenticationType,
                                  cacheConfiguration: AWSAppSyncCacheConfiguration? = nil) throws -> DeinitNotifiableAppSyncClient {

        let testBundle = Bundle(for: AWSAppSyncAPIKeyAuthTests.self)
        let helper = try AppSyncClientTestHelper(
            with: authType,
            cacheConfiguration: cacheConfiguration,
            testBundle: testBundle
        )
        return helper.appSyncClient
    }

}

private enum SyncWatcherLifecyclePhase {
    case baseQueryNotYetComplete
    case baseQueryComplete
    case monitoringSubscriptions
}
