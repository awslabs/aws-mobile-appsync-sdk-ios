//
// Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import XCTest
@testable import AWSAppSync
@testable import AWSCore
@testable import AWSAppSyncTestCommon

class AWSAppSyncLambdaAuthTests: XCTestCase {

    var appSyncClient: AWSAppSyncClient?

    /// Use this as our timeout value for any operation that hits the network. Note that this may need to be higher
    /// than you think, to account for CI systems running in shared environments
    private static let networkOperationTimeout = 180.0

    private static let mutationQueue = DispatchQueue(label: "com.amazonaws.appsync.AWSAppSyncLambdaAuthTests.mutationQueue")
    private static let subscriptionAndFetchQueue = DispatchQueue(label: "com.amazonaws.appsync.AWSAppSyncLambdaAuthTests.subscriptionAndFetchQueue")

    
    override func setUp() {
        super.setUp()
        let authType = AppSyncClientTestHelper.AuthenticationType.lambda
        do {
            appSyncClient = try AWSAppSyncLambdaAuthTests.makeAppSyncClient(authType: authType)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testMutation() {
        let postCreated = expectation(description: "Post created successfully.")
        let addPost = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation

        appSyncClient?.perform(mutation: addPost, queue: AWSAppSyncLambdaAuthTests.mutationQueue, resultHandler:  { result, error in
            XCTAssertNil(error)
            XCTAssertNotNil(result?.data?.createPostWithoutFileUsingParameters?.id)
            XCTAssertEqual(
                result!.data!.createPostWithoutFileUsingParameters?.author,
                DefaultTestPostData.author
            )
            print("Created post \(result?.data?.createPostWithoutFileUsingParameters?.id ?? "(ID unexpectedly nil)")")
            postCreated.fulfill()
        })

        wait(for: [postCreated], timeout: AWSAppSyncLambdaAuthTests.networkOperationTimeout)
    }

    func testQuery() {
        let postCreated = expectation(description: "Post created successfully.")
        let addPost = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation

        appSyncClient?.perform(mutation: addPost, queue: AWSAppSyncLambdaAuthTests.mutationQueue, resultHandler:  { result, error in
            XCTAssertNil(error)
            XCTAssertNotNil(result?.data?.createPostWithoutFileUsingParameters?.id)
            XCTAssertEqual(
                result!.data!.createPostWithoutFileUsingParameters?.author,
                DefaultTestPostData.author
            )
            postCreated.fulfill()
        })

        wait(for: [postCreated], timeout: AWSAppSyncLambdaAuthTests.networkOperationTimeout)

        let query = ListPostsQuery()

        let listPostsCompleted = expectation(description: "Query done successfully.")

        appSyncClient?.fetch(query: query, cachePolicy: .fetchIgnoringCacheData, queue: AWSAppSyncLambdaAuthTests.subscriptionAndFetchQueue) { result, error in
            XCTAssertNil(error)
            XCTAssertNotNil(result?.data?.listPosts)
            XCTAssertGreaterThan(result!.data!.listPosts!.count, 0, "Expected service to return at least 1 post.")
            listPostsCompleted.fulfill()
        }

        wait(for: [listPostsCompleted], timeout: AWSAppSyncLambdaAuthTests.networkOperationTimeout)
    }
    
    func testSubscriptionWithAsyncAuthProvider() throws {
        let authType = AppSyncClientTestHelper.AuthenticationType.asyncLambda
        let appSyncClient = try AWSAppSyncLambdaAuthTests.makeAppSyncClient(authType: authType)
        try testSubscription(withClient: appSyncClient)
    }
    
    func testSubscriptionWithSyncAuthProvider() throws {
        let authType = AppSyncClientTestHelper.AuthenticationType.lambda
        let appSyncClient = try AWSAppSyncLambdaAuthTests.makeAppSyncClient(authType: authType)
        try testSubscription(withClient: appSyncClient)
    }
    
    
    // MARK: - Utilities
    
    func testSubscription(withClient client: AWSAppSyncClient?) throws {
        let postCreated = expectation(description: "Post created successfully.")
        let addPost = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation

        var idHolder: GraphQLID?
        client?.perform(mutation: addPost, queue: Self.subscriptionAndFetchQueue, resultHandler:  { result, error in
            print("CreatePost result handler invoked")
            XCTAssertNil(error)
            XCTAssertNotNil(result?.data?.createPostWithoutFileUsingParameters?.id)
            XCTAssertEqual(result!.data!.createPostWithoutFileUsingParameters?.author, DefaultTestPostData.author)
            idHolder = result?.data?.createPostWithoutFileUsingParameters?.id
            postCreated.fulfill()
        })
        wait(for: [postCreated], timeout: Self.networkOperationTimeout)

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

        let subscription = try client?.subscribe(subscription: OnUpvotePostSubscription(id: id),
                                                             queue: Self.subscriptionAndFetchQueue,
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

        wait(for: [subscriptionIsActive], timeout: Self.networkOperationTimeout)

        let upvotePerformed = expectation(description: "Upvote mutation performed")
        let upvoteMutation = UpvotePostMutation(id: id)
        client?.perform(mutation: upvoteMutation, queue: Self.mutationQueue, resultHandler:  {
            result, error in
            print("Received upvote mutation response.")
            XCTAssertNil(error)
            XCTAssertNotNil(result?.data?.upvotePost?.id)
            upvotePerformed.fulfill()
        })

        wait(for: [upvotePerformed, subscriptionResultHandlerInvoked], timeout: Self.networkOperationTimeout)
    }

    static func makeAppSyncClient(authType: AppSyncClientTestHelper.AuthenticationType,
                                  cacheConfiguration: AWSAppSyncCacheConfiguration? = nil) throws -> DeinitNotifiableAppSyncClient {

        let testBundle = Bundle(for: AWSAppSyncLambdaAuthTests.self)
        let helper = try AppSyncClientTestHelper(
            with: authType,
            cacheConfiguration: cacheConfiguration,
            testBundle: testBundle
        )
        return helper.appSyncClient
    }
}

