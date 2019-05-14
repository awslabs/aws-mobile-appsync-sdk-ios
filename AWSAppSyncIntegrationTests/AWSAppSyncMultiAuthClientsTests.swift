//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import XCTest
@testable import AWSAppSync
@testable import AWSAppSyncTestCommon
import AWSS3

class AWSAppSyncMultiAuthClientsTests: XCTestCase {
    /// Use this as our timeout value for any operation that hits the network. Note that this may need to be higher
    /// than you think, to account for CI systems running in shared environments
    private static let networkOperationTimeout = 180.0
    
    private static let mutationQueue = DispatchQueue(label: "com.amazonaws.appsync.AWSAppSyncMultiAuthClientsTests.mutationQueue")
    private static let subscriptionAndFetchQueue = DispatchQueue(label: "com.amazonaws.appsync.AWSAppSyncMultiAuthClientsTests.subscriptionAndFetchQueue")

    func testMultiClientMutation() throws {
        let testBundle = Bundle(for: AWSAppSyncCognitoAuthTests.self)

        // Create IAM based client
        let iamHelper = try AppSyncClientTestHelper(
            with: .cognitoIdentityPools,
            testBundle: testBundle
        )
        let iamAppSyncClient = iamHelper.appSyncClient

        // Create User Pools based client. This client waits 999 seconds before returning authorization.
        let userPoolsHelper = try AppSyncClientTestHelper(
            with: .delayedInvalidOIDC,
            testBundle: testBundle
        )
        let userPoolsAppSyncClient = userPoolsHelper.appSyncClient

        let postCreated = expectation(description: "Post created successfully.")
        let addPost = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation

        userPoolsAppSyncClient.perform(mutation: addPost, queue: AWSAppSyncMultiAuthClientsTests.mutationQueue) { result, error in
            // The result is disregarded.
            XCTFail("API Key based client should have finished first")
        }

        // Delay next call to exaggerate any
        sleep(2)

        iamAppSyncClient.perform(mutation: addPost, queue: AWSAppSyncMultiAuthClientsTests.mutationQueue) { result, error in
            // The result is disregarded.
            postCreated.fulfill()
        }

        wait(for: [postCreated], timeout: AWSAppSyncMultiAuthClientsTests.networkOperationTimeout)
    }

    func testMultiClientSubscriptions() throws {
        let testBundle = Bundle(for: AWSAppSyncCognitoAuthTests.self)

        // Create User Pools based client. This client waits 999 seconds before returning authorization.
        let userPoolsHelper = try AppSyncClientTestHelper(
            with: .delayedInvalidOIDC,
            testBundle: testBundle
        )
        let userPoolsAppSyncClient = userPoolsHelper.appSyncClient

        // Create IAM based client
        let iamHelper = try AppSyncClientTestHelper(
            with: .cognitoIdentityPools,
            testBundle: testBundle
        )
        let iamAppSyncClient = iamHelper.appSyncClient

        // Create a post to upvote
        let postCreated = expectation(description: "Post created successfully.")
        let addPost = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation

        var createdId: GraphQLID?
        iamAppSyncClient.perform(mutation: addPost, queue: AWSAppSyncMultiAuthClientsTests.mutationQueue) { result, error in
            XCTAssertNil(error)
            XCTAssertNotNil(result?.data?.createPostWithoutFileUsingParameters?.id)
            createdId = result!.data!.createPostWithoutFileUsingParameters!.id
            XCTAssertEqual(
                result!.data!.createPostWithoutFileUsingParameters?.author,
                DefaultTestPostData.author
            )
            postCreated.fulfill()
        }

        wait(for: [postCreated], timeout: AWSAppSyncMultiAuthClientsTests.networkOperationTimeout)

        // Start a failure subscription that blocks on credentials
        let blockingSubscriptionWatcher = try userPoolsAppSyncClient.subscribe(subscription: OnUpvotePostSubscription(id: createdId!))  { (result, transaction, error) in
            XCTFail("This client should be blocked until after test exits")
        }

        // Start listening for events
        let upVoteEventTriggered = expectation(description: "Up vote event triggered")
        let upVoteEventConnected = expectation(description: "Subscription active")

        let watcher = try iamAppSyncClient.subscribe(subscription: OnUpvotePostSubscription(id: createdId!), statusChangeHandler: { status in
            if case .connected = status {
                upVoteEventConnected.fulfill()
            }
        }) { (result, transaction, error) in
            XCTAssertNil(error)
            if (result?.data?.onUpvotePost?.id == createdId) {
                upVoteEventTriggered.fulfill()
            }
        }
        _ = [blockingSubscriptionWatcher, watcher] // Silence unused variable warning

        // Delay so that subscription setup is complete
        wait(for: [upVoteEventConnected], timeout: AWSAppSyncMultiAuthClientsTests.networkOperationTimeout)

        // Create an event that should trigger subscription
        let upVote = UpvotePostMutation(id: createdId!)
        let upVoted = expectation(description: "Post upvoted")

        iamAppSyncClient.perform(mutation: upVote, queue: AWSAppSyncMultiAuthClientsTests.mutationQueue) { result, error in
            XCTAssertNil(error)
            upVoted.fulfill()
        }

        wait(for: [upVoted], timeout: AWSAppSyncMultiAuthClientsTests.networkOperationTimeout)
        wait(for: [upVoteEventTriggered], timeout: AWSAppSyncMultiAuthClientsTests.networkOperationTimeout)
    }

    func testProtectedReadWithCachingSegregation() throws {
        let testBundle = Bundle(for: AWSAppSyncCognitoAuthTests.self)
        
        // Create IAM based client
        let iamHelper = try AppSyncClientTestHelper(
            with: .cognitoIdentityPools,
            testBundle: testBundle
        )
        let iamAppSyncClient = iamHelper.appSyncClient
        
        // Create API Key based client
        let apiKeyHelper = try AppSyncClientTestHelper(
            with: .apiKeyWithIAMEndpoint,
            testBundle: testBundle
        )
        let apiKeyAppSyncClient = apiKeyHelper.appSyncClient
        
        let postCreated = expectation(description: "Post created successfully.")
        
        let addPost = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation
        var createdId: GraphQLID?
        iamAppSyncClient.perform(mutation: addPost, queue: AWSAppSyncMultiAuthClientsTests.mutationQueue) { result, error in
            XCTAssertNil(error)
            XCTAssertNotNil(result?.data?.createPostWithoutFileUsingParameters?.id)
            createdId = result!.data!.createPostWithoutFileUsingParameters!.id
            XCTAssertEqual(
                result!.data!.createPostWithoutFileUsingParameters?.author,
                DefaultTestPostData.author
            )
            postCreated.fulfill()
        }
        
        wait(for: [postCreated], timeout: AWSAppSyncMultiAuthClientsTests.networkOperationTimeout)

        let getPostQuery = GetPostQuery(id: createdId!)

        let apiKeyGetPost = expectation(description: "Query done successfully.")

        apiKeyAppSyncClient.fetch(query: getPostQuery, cachePolicy: .fetchIgnoringCacheData, queue: AWSAppSyncMultiAuthClientsTests.subscriptionAndFetchQueue) { result, error in
            XCTAssertNil(error)
            XCTAssertNotNil(result?.data)
            XCTAssertNil(result?.data?.getPost?.url)
            XCTAssert((result?.errors![0].message.contains("Not Authorized to access url on type Post"))!)
            apiKeyGetPost.fulfill()
        }

        wait(for: [apiKeyGetPost], timeout: AWSAppSyncMultiAuthClientsTests.networkOperationTimeout)

        let iamGetPost = expectation(description: "Query done successfully.")

        iamAppSyncClient.fetch(query: getPostQuery, cachePolicy: .fetchIgnoringCacheData, queue: AWSAppSyncMultiAuthClientsTests.subscriptionAndFetchQueue) { result, error in
            XCTAssertNil(error)
            XCTAssertNotNil(result?.data)
            XCTAssertNotNil(result?.data?.getPost?.url)
            iamGetPost.fulfill()
        }

        wait(for: [iamGetPost], timeout: AWSAppSyncMultiAuthClientsTests.networkOperationTimeout)

        let apiKeyGetPostCached = expectation(description: "Query done successfully.")

        apiKeyAppSyncClient.fetch(query: getPostQuery, cachePolicy: .returnCacheDataDontFetch, queue: AWSAppSyncMultiAuthClientsTests.subscriptionAndFetchQueue) { result, error in
            XCTAssertNil(error)
            XCTAssertNotNil(result?.data)
            XCTAssertNil(result?.data?.getPost?.url)
            apiKeyGetPostCached.fulfill()
        }

        wait(for: [apiKeyGetPostCached], timeout: AWSAppSyncMultiAuthClientsTests.networkOperationTimeout)

        let iamGetPostCached = expectation(description: "Query done successfully.")

        iamAppSyncClient.fetch(query: getPostQuery, cachePolicy: .returnCacheDataDontFetch, queue: AWSAppSyncMultiAuthClientsTests.subscriptionAndFetchQueue) { result, error in
            XCTAssertNil(error)
            XCTAssertNotNil(result?.data)
            XCTAssertNotNil(result?.data?.getPost?.url)
            iamGetPostCached.fulfill()
        }

        wait(for: [iamGetPostCached], timeout: AWSAppSyncMultiAuthClientsTests.networkOperationTimeout)

        try apiKeyAppSyncClient.clearCaches()

        let apiKeyGetPostCachedAfterApiKeyClear = expectation(description: "Query done successfully.")

        apiKeyAppSyncClient.fetch(query: getPostQuery, cachePolicy: .returnCacheDataDontFetch, queue: AWSAppSyncMultiAuthClientsTests.subscriptionAndFetchQueue) { result, error in
            XCTAssertNil(error)
            XCTAssertNil(result?.data)
            apiKeyGetPostCachedAfterApiKeyClear.fulfill()
        }

        wait(for: [apiKeyGetPostCachedAfterApiKeyClear], timeout: AWSAppSyncMultiAuthClientsTests.networkOperationTimeout)

        let iamGetPostCachedAfterApiKeyClear = expectation(description: "Query done successfully.")

        iamAppSyncClient.fetch(query: getPostQuery, cachePolicy: .returnCacheDataDontFetch, queue: AWSAppSyncMultiAuthClientsTests.subscriptionAndFetchQueue) { result, error in
            XCTAssertNil(error)
            XCTAssertNotNil(result?.data)
            XCTAssertNotNil(result?.data?.getPost?.url)
            iamGetPostCachedAfterApiKeyClear.fulfill()
        }

        wait(for: [iamGetPostCachedAfterApiKeyClear], timeout: AWSAppSyncMultiAuthClientsTests.networkOperationTimeout)
    }

    func testDeltaSyncMetadataClear() throws {
        let testBundle = Bundle(for: AWSAppSyncCognitoAuthTests.self)

        // This tests needs a physical DB for the SubscriptionMetadataCache to properly return a "lastSynced" value.
        let rootDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("testDeltaSyncMetadataClear")
        try? FileManager.default.removeItem(at: rootDirectory)
        let cacheConfiguration = try AWSAppSyncCacheConfiguration(withRootDirectory: rootDirectory)

        // Create IAM based client
        let iamHelper = try AppSyncClientTestHelper(
            with: .cognitoIdentityPools,
            cacheConfiguration: cacheConfiguration,
            testBundle: testBundle
        )
        let iamAppSyncClient = iamHelper.appSyncClient
        _ = try iamAppSyncClient.clearCaches()

        let listPostQuery = ListPostsQuery()
        let listPostDeltaQuery = ListPostsDeltaQuery()
        let queryCallbackExpect = expectation(description: "Query callback")

        _ = iamAppSyncClient.sync(baseQuery: listPostQuery
        , baseQueryResultHandler: { (result, error) in
            if let _ = result,
                result!.source == .server {
                queryCallbackExpect.fulfill()
            }
        }, deltaQuery: listPostDeltaQuery, deltaQueryResultHandler: { (result, transaction, error) in
            XCTFail("Not expecting a delta query result")
        })

        wait(for: [queryCallbackExpect], timeout: AWSAppSyncMultiAuthClientsTests.networkOperationTimeout)

        sleep(1) // Database has eventually consistent read on the lastSyncTime

        // Phase 2

        let deltaQueryCallbackExpect = expectation(description: "Delta query callback")

        _ = iamAppSyncClient.sync(baseQuery: listPostQuery
        , baseQueryResultHandler: { (result, error) in
            if let result = result,
                result.source == .server {
                XCTFail("Not expecting a base query result")
            }
        }, deltaQuery: listPostDeltaQuery, deltaQueryResultHandler: { (result, transaction, error) in
            if let _ = result {
                deltaQueryCallbackExpect.fulfill()
            }
        })

        wait(for: [deltaQueryCallbackExpect], timeout: AWSAppSyncMultiAuthClientsTests.networkOperationTimeout)

        // Reset

        let _ = try iamAppSyncClient.clearCaches()

        let queryCallbackExpect2 = expectation(description: "Query callback 2")

        _ = iamAppSyncClient.sync(baseQuery: listPostQuery
        , baseQueryResultHandler: { (result, error) in
            if let result = result,
                result.source == .server {
                queryCallbackExpect2.fulfill()
            }
        }, deltaQuery: listPostDeltaQuery, deltaQueryResultHandler: { (result, transaction, error) in
            XCTFail("Not expecting a delta query result 2")
        })

        wait(for: [queryCallbackExpect2], timeout: AWSAppSyncMultiAuthClientsTests.networkOperationTimeout)
    }

}
