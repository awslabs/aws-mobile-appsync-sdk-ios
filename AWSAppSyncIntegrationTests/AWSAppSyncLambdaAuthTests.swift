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
    
    
    // MARK: - Utilities

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

