//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import XCTest
@testable import AWSAppSync
@testable import AWSAppSyncTestCommon

/// Perform a single mutation test to ensure AWS_IAM for auth connection succeeds
class AWSAppSyncCognitoAuthTests: XCTestCase {
    private static let mutationQueue = DispatchQueue(label: "com.amazonaws.appsync.AWSAppSyncCognitoAuthTests.mutationQueue")
    func testIAMAuthCanPerformMutation() throws {
        let testBundle = Bundle(for: AWSAppSyncAPIKeyAuthTests.self)
        let helper = try AppSyncClientTestHelper(
            with: .cognitoIdentityPools,
            testBundle: testBundle
        )
        let appSyncClient = helper.appSyncClient

        let postCreated = expectation(description: "Post created successfully.")
        let addPost = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation

        appSyncClient.perform(mutation: addPost, queue: AWSAppSyncCognitoAuthTests.mutationQueue) { result, error in
            XCTAssertNil(error)
            XCTAssertNotNil(result?.data?.createPostWithoutFileUsingParameters?.id)
            XCTAssertEqual(
                result!.data!.createPostWithoutFileUsingParameters?.author,
                DefaultTestPostData.author
            )
            postCreated.fulfill()
        }

        wait(for: [postCreated], timeout: 5.0)

    }
}
