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
@testable import AWSS3

class AppSyncClientComplexObjectMutationUnitTests: XCTestCase {

    func test_clientQueuesMutationOfCorrectType_WhenS3ObjectIsPartOfInput() throws {
        let fileInput = S3ObjectInput(
            bucket: "the-bucket",
            key: "the-key.jpg",
            region: "us-east-1",
            localUri: "/path/to/file.jpg",
            mimeType: "image/jpeg"
        )

        // Create an object with a complex object field
        let input = CreatePostWithFileInput(
            author: DefaultTestPostData.author,
            title: DefaultTestPostData.title,
            content: DefaultTestPostData.content,
            file: fileInput
        )
        let addPostWithFile = CreatePostWithFileUsingInputTypeMutation(input: input)

        // Use a mock transport so we don't send any network traffic during this test
        let mockHTTPTransport = MockNetworkTransport()

        let s3ObjectManagerUploadWasInvoked = expectation(description: "s3ObjectManager.upload() was invoked")

        let mockS3ObjectManager = MockS3ObjectManager()
        mockS3ObjectManager.uploadHandler = { (object, completionBlock) in
            print("Upload result: \(object)")
            s3ObjectManagerUploadWasInvoked.fulfill()

            XCTAssertEqual(object.getBucketName(), fileInput.bucket)
            XCTAssertEqual(object.getKeyName(), fileInput.key)
            XCTAssertEqual(object.getRegion(), fileInput.region)
            XCTAssertEqual(object.getLocalSourceFileURL()?.absoluteString, fileInput.localUri)
            XCTAssertEqual(object.getMimeType(), fileInput.mimeType)
        }

        let helper = try AppSyncClientTestHelper(
            with: .apiKey,
            testConfiguration: AppSyncClientTestConfiguration.UnitTestingConfiguration,
            httpTransport: mockHTTPTransport,
            s3ObjectManager: mockS3ObjectManager
        )

        let appSyncClient = helper.appSyncClient

        appSyncClient.perform(mutation: addPostWithFile)

        wait(for: [s3ObjectManagerUploadWasInvoked], timeout: 2.0)
    }

    // TODO: Test in progress
    func test_clientQueuesMutationOfCorrectType_WhenS3ObjectIsParameterOfMutation() throws {
        let fileInput = S3ObjectInput(
            bucket: "the-bucket",
            key: "the-key.jpg",
            region: "us-east-1",
            localUri: "/path/to/file.jpg",
            mimeType: "image/jpeg"
        )

        // Create an object with a complex object field
        let addPostWithFile = CreatePostWithFileUsingParametersMutation(
            author: DefaultTestPostData.author,
            title: DefaultTestPostData.title,
            content: DefaultTestPostData.content,
            file: fileInput)

        // Use a mock transport so we don't send any network traffic during this test
        let mockHTTPTransport = MockNetworkTransport()

        let s3ObjectManagerUploadWasInvoked = expectation(description: "s3ObjectManager.upload() was invoked")

        let mockS3ObjectManager = MockS3ObjectManager()
        mockS3ObjectManager.uploadHandler = { (object, completionBlock) in
            print("Upload result: \(object)")
            s3ObjectManagerUploadWasInvoked.fulfill()

            XCTAssertEqual(object.getBucketName(), fileInput.bucket)
            XCTAssertEqual(object.getKeyName(), fileInput.key)
            XCTAssertEqual(object.getRegion(), fileInput.region)
            XCTAssertEqual(object.getLocalSourceFileURL()?.absoluteString, fileInput.localUri)
            XCTAssertEqual(object.getMimeType(), fileInput.mimeType)
        }

        let helper = try AppSyncClientTestHelper(
            with: .apiKey,
            testConfiguration: AppSyncClientTestConfiguration.UnitTestingConfiguration,
            httpTransport: mockHTTPTransport,
            s3ObjectManager: mockS3ObjectManager
        )

        let appSyncClient = helper.appSyncClient

        appSyncClient.perform(mutation: addPostWithFile)

        wait(for: [s3ObjectManagerUploadWasInvoked], timeout: 2.0)
    }

}
