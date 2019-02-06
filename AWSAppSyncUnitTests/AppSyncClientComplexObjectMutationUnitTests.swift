//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import XCTest
@testable import AWSAppSync
@testable import AWSAppSyncTestCommon
@testable import AWSS3

class AppSyncClientComplexObjectMutationUnitTests: XCTestCase {

    func test_s3UploaderIsInvoked_WhenS3ObjectIsPartOfInputType() throws {
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
        let mockHTTPTransport = MockAWSNetworkTransport()

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
            testConfiguration: AppSyncClientTestConfiguration.forUnitTests,
            httpTransport: mockHTTPTransport,
            s3ObjectManager: mockS3ObjectManager,
            reachabilityFactory: MockReachabilityProvidingFactory.self
        )

        let appSyncClient = helper.appSyncClient

        appSyncClient.perform(mutation: addPostWithFile)

        wait(for: [s3ObjectManagerUploadWasInvoked], timeout: 1.0)
    }

    func test_s3UploaderIsInvoked_WhenS3ObjectIsParameterOfMutation() throws {
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
        let mockHTTPTransport = MockAWSNetworkTransport()

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
            testConfiguration: AppSyncClientTestConfiguration.forUnitTests,
            httpTransport: mockHTTPTransport,
            s3ObjectManager: mockS3ObjectManager,
            reachabilityFactory: MockReachabilityProvidingFactory.self
        )

        let appSyncClient = helper.appSyncClient

        appSyncClient.perform(mutation: addPostWithFile)

        wait(for: [s3ObjectManagerUploadWasInvoked], timeout: 1.0)
    }

    func test_s3UploaderIsNotInvoked_WhenNoS3ObjectIsPresent() throws {
        // Use a mock transport so we don't send any network traffic during this test
        let mockHTTPTransport = MockAWSNetworkTransport()

        let s3ObjectManagerUploadWasNotInvoked = expectation(description: "s3ObjectManager.upload() was not invoked")
        s3ObjectManagerUploadWasNotInvoked.isInverted = true

        let mockS3ObjectManager = MockS3ObjectManager()
        mockS3ObjectManager.uploadHandler = { (object, completionBlock) in
            print("Upload incorrectly invoked result: \(object)")
            s3ObjectManagerUploadWasNotInvoked.fulfill()
        }

        let helper = try AppSyncClientTestHelper(
            with: .apiKey,
            testConfiguration: AppSyncClientTestConfiguration.forUnitTests,
            httpTransport: mockHTTPTransport,
            s3ObjectManager: mockS3ObjectManager,
            reachabilityFactory: MockReachabilityProvidingFactory.self
        )

        let appSyncClient = helper.appSyncClient

        let addPostWithNoFile = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation
        appSyncClient.perform(mutation: addPostWithNoFile)

        wait(for: [s3ObjectManagerUploadWasNotInvoked], timeout: 1.0)
    }

}
