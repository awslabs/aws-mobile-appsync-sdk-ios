//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import XCTest
@testable import AWSAppSync
@testable import AWSAppSyncTestCommon
import AWSS3

/// Tests only valid for IAM auth type. In addition to the obvious one that tests a simple mutation to ensure that IAM
/// clients can connect, the S3 tests are only able to be performed with Cognito authentication. The S3 bucket policies
/// set up in the test fixtures rely on identity IDs to properly scope "private" and "protected" access. See
/// https://aws-amplify.github.io/docs/js/storage#file-access-levels
class AWSAppSyncCognitoAuthTests: XCTestCase {
    /// Use this as our timeout value for any operation that hits the network. Note that this may need to be higher
    /// than you think, to account for CI systems running in shared environments
    private static let networkOperationTimeout = 180.0

    private static let s3TransferUtilityKey = "AWSAppSyncCognitoAuthTestsTransferUtility"

    private static let mutationQueue = DispatchQueue(label: "com.amazonaws.appsync.AWSAppSyncCognitoAuthTests.mutationQueue")

    override func tearDown() {
        AWSS3TransferUtility.remove(forKey: AWSAppSyncCognitoAuthTests.s3TransferUtilityKey)
    }

    func testIAMAuthCanPerformMutation() throws {
        let testBundle = Bundle(for: AWSAppSyncCognitoAuthTests.self)
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

        wait(for: [postCreated], timeout: AWSAppSyncCognitoAuthTests.networkOperationTimeout)
    }

    // Uploads a local file as part of a mutation, then downloads it using the data retrieved from the AppSync query
    func testS3UploadUsingParameters() throws {
        let testBundle = Bundle(for: AWSAppSyncCognitoAuthTests.self)
        let testConfiguration = AppSyncClientTestConfiguration(with: testBundle)!
        let appSyncClient = try makeS3EnabledAppSyncClient(testConfiguration: testConfiguration, testBundle: testBundle)

        // Note "public" prefix. See https://aws-amplify.github.io/docs/js/storage#using-amazon-s3
        let objectKey = "public/testS3Object-\(UUID().uuidString).jpg"
        let localURL = testBundle.url(forResource: "testS3Object", withExtension: ".jpg")!

        // TODO: Replace the hardcoded line below once AWSCore 2.9.1 is released
        // let region = AWSEndpoint.regionName(from: testConfiguration.bucketRegion)!
        let region = "eu-central-2"

        let postCreated = expectation(description: "Post created successfully.")

        let s3ObjectInput = S3ObjectInput(
            bucket: testConfiguration.bucketName,
            key: objectKey,
            region: region,
            localUri: localURL.path,
            mimeType: "image/jpeg")

        let createPostWithFile = CreatePostWithFileUsingParametersMutation(
            author: "Test S3 Object Author",
            title: "Test S3 Object Upload",
            content: "Testing S3 object upload",
            url: "http://www.example.testing.com",
            ups: 0,
            downs: 0,
            file: s3ObjectInput)

        var mutationResult: GraphQLResult<CreatePostWithFileUsingParametersMutation.Data>? = nil
        appSyncClient.perform(mutation: createPostWithFile,
                              queue: AWSAppSyncCognitoAuthTests.mutationQueue) { result, error in
            XCTAssertNil(error)
            mutationResult = result
            postCreated.fulfill()
        }

        wait(for: [postCreated], timeout: AWSAppSyncCognitoAuthTests.networkOperationTimeout)

        guard let postId = mutationResult?.data?.createPostWithFileUsingParameters?.id else {
            XCTFail("Mutation result unexpectedly has nil ID")
            return
        }

        let destinationURL: URL
        do {
            destinationURL = try downloadFile(from: postId, with: appSyncClient)
        } catch {
            XCTFail("Error downloading file from \(postId): \(error.localizedDescription)")
            return
        }

        let file1Data = try Data(contentsOf: destinationURL)
        let file2Data = try Data(contentsOf: localURL)
        XCTAssertEqual(file1Data, file2Data)
    }

    // Uploads a local file as part of a mutation, then downloads it using the data retrieved from the AppSync query
    func testS3UploadUsingFileInput() throws {
        let testBundle = Bundle(for: AWSAppSyncCognitoAuthTests.self)
        let testConfiguration = AppSyncClientTestConfiguration(with: testBundle)!
        let appSyncClient = try makeS3EnabledAppSyncClient(testConfiguration: testConfiguration, testBundle: testBundle)

        // Note "public" prefix. See https://aws-amplify.github.io/docs/js/storage#using-amazon-s3
        let objectKey = "public/testS3Object-\(UUID().uuidString).jpg"
        let localURL = testBundle.url(forResource: "testS3Object", withExtension: ".jpg")!

        // TODO: Replace the hardcoded line below once AWSCore 2.9.1 is released
        // let region = AWSEndpoint.regionName(from: testConfiguration.bucketRegion)!
        let region = "eu-central-2"

        let postCreated = expectation(description: "Post created successfully.")

        let s3ObjectInput = S3ObjectInput(
            bucket: testConfiguration.bucketName,
            key: objectKey,
            region: region,
            localUri: localURL.path,
            mimeType: "image/jpeg")

        let addPostWithFileInput = CreatePostWithFileInput(
            author: "Test S3 Object Author",
            title: "Test S3 Object Upload",
            content: "Testing S3 object upload",
            ups: 0,
            downs: 0,
            file: s3ObjectInput)

        let createPostWithFile = CreatePostWithFileUsingInputTypeMutation(input: addPostWithFileInput)

        var mutationResult: GraphQLResult<CreatePostWithFileUsingInputTypeMutation.Data>? = nil
        appSyncClient.perform(mutation: createPostWithFile,
                              queue: AWSAppSyncCognitoAuthTests.mutationQueue) { result, error in
            XCTAssertNil(error)
            mutationResult = result
            postCreated.fulfill()
        }

        wait(for: [postCreated], timeout: AWSAppSyncCognitoAuthTests.networkOperationTimeout)

        guard let postId = mutationResult?.data?.createPostWithFileUsingInputType?.id else {
            XCTFail("Mutation result unexpectedly has nil ID")
            return
        }

        let destinationURL: URL
        do {
            destinationURL = try downloadFile(from: postId, with: appSyncClient)
        } catch {
            XCTFail("Error downloading file from \(postId): \(error.localizedDescription)")
            return
        }

        let file1Data = try Data(contentsOf: destinationURL)
        let file2Data = try Data(contentsOf: localURL)
        XCTAssertEqual(file1Data, file2Data)
    }

    // MARK: - Utilities

    func makeS3EnabledAppSyncClient(testConfiguration: AppSyncClientTestConfiguration,
                                    testBundle: Bundle) throws -> AWSAppSyncClient {
        let credentialsProvider = BasicAWSCognitoCredentialsProviderFactory.makeCredentialsProvider(with: testConfiguration)

        let serviceConfiguration = AWSServiceConfiguration(
            region: testConfiguration.bucketRegion,
            credentialsProvider: credentialsProvider)!

        AWSS3TransferUtility.register(with: serviceConfiguration, forKey: AWSAppSyncCognitoAuthTests.s3TransferUtilityKey)
        let transferUtility = AWSS3TransferUtility.s3TransferUtility(forKey: AWSAppSyncCognitoAuthTests.s3TransferUtilityKey)

        let helper = try AppSyncClientTestHelper(
            with: .cognitoIdentityPools,
            testConfiguration: testConfiguration,
            s3ObjectManager: transferUtility,
            testBundle: testBundle)

        let appSyncClient = helper.appSyncClient

        return appSyncClient
    }

    // Retrieves `postId` from service and downloads that post's file from S3 and returns the URL to which the file
    // was downloaded
    func downloadFile(from postId: GraphQLID, with appSyncClient: AWSAppSyncClient) throws -> URL {
        guard let s3ObjectManager = appSyncClient.s3ObjectManager else {
            throw "No S3ObjectManager for appSyncClient"
        }

        // Get post from server; we'll only use that data to download the file
        let postRetrieved = expectation(description: "Post retrieved from AppSync")
        var getPostResult: GetPostQuery.Data.GetPost? = nil

        appSyncClient.fetch(query: GetPostQuery(id: postId), cachePolicy: .fetchIgnoringCacheData) { (result, error) in
            defer {
                postRetrieved.fulfill()
            }
            guard let result = result else {
                XCTFail("Result unexpectedly nil retrieving post from AppSync")
                return
            }

            getPostResult = result.data?.getPost
        }

        wait(for: [postRetrieved], timeout: AWSAppSyncCognitoAuthTests.networkOperationTimeout)

        guard let resolvedPostResult = getPostResult else {
            throw "getPostResult unexpectedly nil after retrieve from AppSync"
        }

        let downloadComplete = expectation(description: "Download complete")
        let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent("downloadedFile-\(UUID().uuidString).jpg")

        guard let file = resolvedPostResult.file else {
            throw "file field was unexpectedly nil retrieving from AppSync"
        }

        s3ObjectManager.download(s3Object: file, toURL: destinationURL) { (result, error) in
            defer {
                downloadComplete.fulfill()
            }

            guard error == nil else {
                XCTFail("Error downloading from S3: \(error!.localizedDescription)")
                return
            }

            XCTAssert(result, "Download was not successful")
        }

        wait(for: [downloadComplete], timeout: AWSAppSyncCognitoAuthTests.networkOperationTimeout)
        print("Successfully downloaded to \(destinationURL)")
        return destinationURL
    }

}
