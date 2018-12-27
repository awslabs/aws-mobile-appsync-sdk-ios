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

/// Perform a single mutation test to ensure AWS_IAM for auth connection succeeds
class AWSAppSyncCognitoAuthTests: XCTestCase {
    func testIAMAuthCanPerformMutation() throws {
        let testBundle = Bundle(for: AWSAppSyncAPIKeyAuthTests.self)
        let helper = try AppSyncClientTestHelper(
            with: .cognitoIdentityPools,
            testBundle: testBundle
        )
        let appSyncClient = helper.appSyncClient

        let postCreated = expectation(description: "Post created successfully.")
        let addPost = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation

        appSyncClient.perform(mutation: addPost) { result, error in
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
