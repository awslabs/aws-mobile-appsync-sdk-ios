//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import XCTest
@testable import AWSAppSync
@testable import AWSAppSyncTestCommon

/// The AppSync client decomposes nested objects according to their path components, and joins them into a composite
/// key joined by a dot (`"."`). In the past, this has caused issues with keys that natively contain ".", such as
/// floating-point numbers or email addresses (#110, #165).
class CacheKeyTests: XCTestCase {
    static let fetchQueue = DispatchQueue(label: "CacheKeyTests.fetch")
    static let mutationQueue = DispatchQueue(label: "CacheKeyTests.mutations")

    var cacheConfiguration: AWSAppSyncCacheConfiguration!
    let mockHTTPTransport = MockAWSNetworkTransport()

    // Set up a new DB for each test
    override func setUp() {
        let tempDir = FileManager.default.temporaryDirectory
        let rootDirectory = tempDir.appendingPathComponent("CacheKeyTests-\(UUID().uuidString)")
        cacheConfiguration = try! AWSAppSyncCacheConfiguration(withRootDirectory: rootDirectory)
    }

    override func tearDown() {
        MockReachabilityProvidingFactory.clearShared()
        NetworkReachabilityNotifier.clearShared()
    }

    func testCacheKeyForObject_withKeyOfType_stringWithoutDots_withBackingDatabase() throws {
        let postId = "part1-part2"
        try doCacheKeyTest(with: postId, usingBackingDatabase: true)
    }

    func testCacheKeyForObject_withKeyOfType_emailAddress_withBackingDatabase() throws {
        let postId = "test.email@amazon.com"
        try doCacheKeyTest(with: postId, usingBackingDatabase: true)
    }

    func testCacheKeyForObject_withKeyOfType_stringWithoutDots_withoutBackingDatabase() throws {
        let postId = "TEMP-\(UUID().uuidString)"
        try doCacheKeyTest(with: postId, usingBackingDatabase: false)
    }

    func testCacheKeyForObject_withKeyOfType_emailAddress_withoutBackingDatabase() throws {
        let postId = "test.email@amazon.com"
        try doCacheKeyTest(with: postId, usingBackingDatabase: false)
    }

    // MARK: - Utilities

    /// Tests that a record retrieved from the service is retrievable from the cache using the same ID.
    ///
    /// Test methodology:
    /// 1. Query only the service to ensure we populate the cache via the AppSync/Apollo update mechanism
    /// 2. Query only the cache to ensure we get the expected result
    func doCacheKeyTest(with postId: GraphQLID, usingBackingDatabase: Bool) throws {

        let result = UnitTestHelpers.makeGetPostResponseBody(with: postId)

        let mockHTTPTransport = MockAWSNetworkTransport()
        mockHTTPTransport.sendOperationHandlerResponseBody = result

        let resolvedCacheConfiguration = usingBackingDatabase ? cacheConfiguration : nil

        // Default cacheKeyForObject is set to extract `id`
        let appSyncClient = try UnitTestHelpers.makeAppSyncClient(using: mockHTTPTransport,
                                                                  cacheConfiguration: resolvedCacheConfiguration)

        let fetchFromServiceComplete = expectation(description: "Fetch from service complete")
        appSyncClient.fetch(query: GetPostQuery(id: postId),
                            cachePolicy: .fetchIgnoringCacheData,
                            queue: CacheKeyTests.fetchQueue) { _, _ in
                                fetchFromServiceComplete.fulfill()
        }

        wait(for: [fetchFromServiceComplete], timeout: 1.0)

        let fetchFromCacheComplete = expectation(description: "Query from cache is complete")
        appSyncClient.fetch(query: GetPostQuery(id: postId),
                            cachePolicy: .returnCacheDataDontFetch,
                            queue: CacheKeyTests.fetchQueue) { result, error in
                                defer {
                                    fetchFromCacheComplete.fulfill()
                                }

                                guard error == nil else {
                                    XCTFail("Error fetching from cache: \(String(describing: error))")
                                    return
                                }

                                guard let result = result else {
                                    XCTFail("Result unexpectedly nil fetching postId \(postId) from cache")
                                    return
                                }

                                XCTAssertEqual(result.data?.getPost?.id, postId)
        }

        wait(for: [fetchFromCacheComplete], timeout: 1.0)
    }
}
