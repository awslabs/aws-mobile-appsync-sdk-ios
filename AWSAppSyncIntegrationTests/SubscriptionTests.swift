//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import XCTest
@testable import AWSAppSync
@testable import AWSCore
@testable import AWSAppSyncTestCommon

class SubscriptionTests: XCTestCase {

    // MARK: - Properties

    /// Use this as our timeout value for any operation that hits the network. Note that this may need to be higher
    /// than you think, to account for CI systems running in shared environments
    private static let networkOperationTimeout = 60.0

    private static let mutationQueue = DispatchQueue(label: "com.amazonaws.appsync.SubscriptionTests.mutationQueue")
    private static let subscriptionAndFetchQueue = DispatchQueue(label: "com.amazonaws.appsync.SubscriptionTests.subscriptionAndFetchQueue")

    /// This will be automatically instantiated in `performDefaultSetUpSteps`
    var appSyncClient: AWSAppSyncClient?

    let authType = AppSyncClientTestHelper.AuthenticationType.apiKey

    override func setUp() {
        super.setUp()

        AWSDDLog.sharedInstance.logLevel = .warning
        AWSDDTTYLogger.sharedInstance.logFormatter = AWSAppSyncClientLogFormatter()
        AWSDDLog.sharedInstance.add(AWSDDTTYLogger.sharedInstance)

        do {
            appSyncClient = try SubscriptionTests.makeAppSyncClient(authType: authType)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // MARK: - Tests

    // Tests subscription system by registering subscriptions as fast as possible
    func testSubscription_Stress() {
        guard let appSyncClient = appSyncClient else {
            XCTFail("appSyncClient should not be nil")
            return
        }
        let subscriptionStressTestHelper = SubscriptionStressTestHelper()
        subscriptionStressTestHelper.stressTestSubscriptions(with: appSyncClient)
    }

    // Tests subscription system by registering many subscriptions but interleaving them with a delay, to
    // ensure that some connections are being started while others are being dropped
    func testSubscription_StressWithInterleavedConnections() {
        guard let appSyncClient = appSyncClient else {
            XCTFail("appSyncClient should not be nil")
            return
        }
        let subscriptionStressTestHelper = SubscriptionStressTestHelper()
        subscriptionStressTestHelper.stressTestSubscriptions(with: appSyncClient, delayBetweenSubscriptions: 1.0)
    }

    func testSubscription() throws {
        let postCreated = expectation(description: "Post created successfully.")
        let addPost = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation

        var idHolder: GraphQLID?
        appSyncClient?.perform(mutation: addPost, queue: SubscriptionTests.mutationQueue) { result, error in
            print("CreatePost result handler invoked")
            XCTAssertNil(error)
            XCTAssertNotNil(result?.data?.createPostWithoutFileUsingParameters?.id)
            XCTAssertEqual(result!.data!.createPostWithoutFileUsingParameters?.author, DefaultTestPostData.author)
            idHolder = result?.data?.createPostWithoutFileUsingParameters?.id
            postCreated.fulfill()
        }
        wait(for: [postCreated], timeout: SubscriptionTests.networkOperationTimeout)

        guard let id = idHolder else {
            XCTFail("Expected ID from addPost mutation")
            return
        }

        // This handler will be invoked if an error occurs during the setup, or if we receive a successful mutation response.
        let subscriptionResultHandlerInvoked = expectation(description: "Subscription received successfully.")
        let subscriptionIsActive = expectation(description: "Upvote subscription should be connected")

        let statusChangeHandler: SubscriptionStatusChangeHandler = { status in
            if case .connected = status {
                subscriptionIsActive.fulfill()
            }
        }

        let subscription = try self.appSyncClient?.subscribe(subscription: OnUpvotePostSubscription(id: id),
                                                             queue: SubscriptionTests.subscriptionAndFetchQueue,
                                                             statusChangeHandler: statusChangeHandler) { result, _, error in
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

        defer {
            subscription?.cancel()
        }

        wait(for: [subscriptionIsActive], timeout: SubscriptionTests.networkOperationTimeout)

        let upvotePerformed = expectation(description: "Upvote mutation performed")
        let upvoteMutation = UpvotePostMutation(id: id)
        self.appSyncClient?.perform(mutation: upvoteMutation, queue: SubscriptionTests.mutationQueue) {
            result, error in
            print("Received upvote mutation response.")
            XCTAssertNil(error)
            XCTAssertNotNil(result?.data?.upvotePost?.id)
            upvotePerformed.fulfill()
        }

        wait(for: [upvotePerformed, subscriptionResultHandlerInvoked], timeout: SubscriptionTests.networkOperationTimeout)
    }

    func testSubscriptionReceivesConnectedMessage() throws {
        AWSDDLog.sharedInstance.logLevel = .verbose
        AWSDDTTYLogger.sharedInstance.logFormatter = AWSAppSyncClientLogFormatter()
        AWSDDLog.sharedInstance.add(AWSDDTTYLogger.sharedInstance)

        let statusChangedToConnected = expectation(description: "Subscription received status change notification to 'connected'")

        let statusChangeHandler: SubscriptionStatusChangeHandler = { status in
            if case .connected = status {
                statusChangedToConnected.fulfill()
            }
        }
        let subscription = try self.appSyncClient?.subscribe(subscription: OnUpvotePostSubscription(id: "123"),
                                                             queue: SubscriptionTests.subscriptionAndFetchQueue,
                                                             statusChangeHandler: statusChangeHandler) { _, _, _ in }

        defer {
            subscription?.cancel()
        }

        wait(for: [statusChangedToConnected], timeout: SubscriptionTests.networkOperationTimeout)
    }

    func testSubscriptionIsInvokedOnProvidedQueue() throws {
        let label = "testSyncOperationAtSetupAndReconnect.syncWatcherCallbackQueue"
        let syncWatcherCallbackQueue = DispatchQueue(label: label)
        let queueIdentityKey = DispatchSpecificKey<String>()
        let queueIdentityValue = label
        syncWatcherCallbackQueue.setSpecific(key: queueIdentityKey, value: queueIdentityValue)

        let appSyncClient = try SubscriptionTests.makeAppSyncClient(authType: self.authType)

        let postCreated = expectation(description: "Post created successfully.")
        let addPost = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation
        var idHolder: GraphQLID?
        appSyncClient.perform(mutation: addPost, queue: SubscriptionTests.mutationQueue) { result, error in
            print("CreatePost result handler invoked")
            idHolder = result?.data?.createPostWithoutFileUsingParameters?.id
            postCreated.fulfill()
        }
        wait(for: [postCreated], timeout: SubscriptionTests.networkOperationTimeout)

        guard let id = idHolder else {
            XCTFail("Expected ID from addPost mutation")
            return
        }

        // We use the base query result handler to know that the subscription is active. Delta Sync does not attempt to
        // perform a server query until the subscription is established, to ensure that no data is lost between the time
        // we begin establishing a sync connection and the time we finish the base query
        let baseQueryFetchFromServerComplete = expectation(description: "BaseQuery fetch from server complete")
        let baseQueryResultHandler: (GraphQLResult<ListPostsQuery.Data>?, Error?) -> Void = { result, _ in
            guard let result = result else {
                return
            }
            if result.source == .server {
                baseQueryFetchFromServerComplete.fulfill()
            }
        }

        let deltaQueryResultHandler: (GraphQLResult<ListPostsQuery.Data>?, ApolloStore.ReadWriteTransaction?, Error?) -> Void = { _, _, _ in }

        let subscriptionResultHandlerInvoked = expectation(description: "Subscription result handler invoked")
        let subscriptionResultHandler: (GraphQLResult<OnUpvotePostSubscription.Data>?, ApolloStore.ReadWriteTransaction?, Error?) -> Void = { _, _, _ in
            subscriptionResultHandlerInvoked.fulfill()
            let dispatchQueueValue = DispatchQueue.getSpecific(key: queueIdentityKey)
            XCTAssertEqual(dispatchQueueValue, queueIdentityValue, "Expected callback to be invoked on provided queue")
        }

        let listPostsQuery = ListPostsQuery()
        let subscription = OnUpvotePostSubscription(id: id)

        let syncWatcher = appSyncClient.sync(
            baseQuery: listPostsQuery,
            baseQueryResultHandler: baseQueryResultHandler,
            subscription: subscription,
            subscriptionResultHandler: subscriptionResultHandler,
            deltaQuery: listPostsQuery,
            deltaQueryResultHandler: deltaQueryResultHandler,
            callbackQueue: syncWatcherCallbackQueue,
            syncConfiguration: SyncConfiguration()
        )

        defer {
            syncWatcher.cancel()
        }

        wait(for: [baseQueryFetchFromServerComplete], timeout: SubscriptionTests.networkOperationTimeout)

        let upvote = UpvotePostMutation(id: id)
        let upvoteComplete = expectation(description: "Upvote mutation completed")

        self.appSyncClient?.perform(mutation: upvote,
                                    queue: SubscriptionTests.mutationQueue) { _, _ in
                                        upvoteComplete.fulfill()
        }

        wait(
            for: [
                upvoteComplete,
                subscriptionResultHandlerInvoked,
                ],
            timeout: SubscriptionTests.networkOperationTimeout
        )
    }

    func testSubscriptionResultHandlerCanOperateOnEmptyCacheWithBackingDatabase() throws {
        let rootDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("emptyCacheTest-\(UUID().uuidString)")
        let cacheConfiguration = try AWSAppSyncCacheConfiguration(withRootDirectory: rootDirectory)
        try doSubscriptionResultHandlerTesting(withCacheConfiguration: cacheConfiguration)
    }

    func testSubscriptionResultHandlerCanOperateOnEmptyCacheWithoutBackingDatabase() throws {
        try doSubscriptionResultHandlerTesting(withCacheConfiguration: nil)
    }

    // MARK: - Utilities

    func doSubscriptionResultHandlerTesting(withCacheConfiguration cacheConfiguration: AWSAppSyncCacheConfiguration?) throws {
        let appSyncClient = try SubscriptionTests.makeAppSyncClient(authType: self.authType, cacheConfiguration: cacheConfiguration)

        // OnDeltaPostSubscription requires no knowledge of prior state, so we can use it to test operations on an
        // empty cache
        let subscriptionWatcherTriggered = expectation(description: "Subscription watcher was triggered")
        // We don't care if this gets triggered multiple times
        subscriptionWatcherTriggered.assertForOverFulfill = false

        let subscriptionIsActive = expectation(description: "Subscription should be active")
        let statusChangeHandler: SubscriptionStatusChangeHandler = { status in
            if case .connected = status {
                subscriptionIsActive.fulfill()
            }
        }

        let subscription = try appSyncClient.subscribe(subscription: OnDeltaPostSubscription(),
                                                       queue: SubscriptionTests.subscriptionAndFetchQueue,
                                                       statusChangeHandler: statusChangeHandler) { result, transaction, error in
            defer {
                subscriptionWatcherTriggered.fulfill()
            }

            guard let transaction = transaction else {
                XCTFail("Transaction unexpectedly nil in subscription watcher")
                return
            }

            guard error == nil else {
                XCTFail("Unexpected error in subscription watcher: \(error!.localizedDescription)")
                return
            }

            guard
                let result = result,
                let onDeltaPostGraphQLResult = result.data?.onDeltaPost
                else {
                    XCTFail("Result onDeltaPost unexpectedly empty in subscription watcher")
                    return
            }

            let newPost = ListPostsQuery.Data.ListPost(id: onDeltaPostGraphQLResult.id,
                                                       author: onDeltaPostGraphQLResult.author,
                                                       title: onDeltaPostGraphQLResult.title,
                                                       content: onDeltaPostGraphQLResult.content,
                                                       url: onDeltaPostGraphQLResult.url,
                                                       ups: onDeltaPostGraphQLResult.ups,
                                                       downs: onDeltaPostGraphQLResult.downs,
                                                       file: nil,
                                                       createdDate: onDeltaPostGraphQLResult.createdDate,
                                                       awsDs: onDeltaPostGraphQLResult.awsDs)

            do {
                try transaction.update(query: ListPostsQuery()) { (data: inout ListPostsQuery.Data) in
                    XCTAssertNil(data.listPosts)
                    data.listPosts = [newPost]
                }
            } catch {
                XCTFail("Unexpected error updating local cache in subscription watcher: \(error.localizedDescription)")
                return
            }
        }

        defer {
            subscription?.cancel()
        }

        wait(for: [subscriptionIsActive], timeout: SubscriptionTests.networkOperationTimeout)

        let newPost = CreatePostWithoutFileUsingParametersMutation(author: "Test author",
                                                                   title: "Test Title",
                                                                   content: "Test content",
                                                                   url: "http://www.amazon.com/",
                                                                   ups: 0,
                                                                   downs: 0)

        let newPostCreated = expectation(description: "New post created")
        self.appSyncClient?.perform(mutation: newPost,
                                    queue: SubscriptionTests.mutationQueue) { _, _ in
                                        newPostCreated.fulfill()
        }

        wait(for: [newPostCreated, subscriptionWatcherTriggered], timeout: SubscriptionTests.networkOperationTimeout)
    }

    static func makeAppSyncClient(authType: AppSyncClientTestHelper.AuthenticationType,
                                  cacheConfiguration: AWSAppSyncCacheConfiguration? = nil) throws -> DeinitNotifiableAppSyncClient {

        let testBundle = Bundle(for: SubscriptionTests.self)
        let helper = try AppSyncClientTestHelper(
            with: authType,
            cacheConfiguration: cacheConfiguration,
            testBundle: testBundle
        )
        return helper.appSyncClient
    }

}
