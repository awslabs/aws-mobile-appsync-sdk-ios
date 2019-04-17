//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import XCTest
@testable import AWSAppSync
@testable import AWSAppSyncTestCommon
import SQLite

// This class only tests a few high-level operations like database setup. For more
// detailed behavior tests, see appropriate tests in the ApolloTests suites.
class AWSSQLiteNormalizedCacheTests: XCTestCase {
    static let fetchQueue = DispatchQueue(label: "AWSSQLiteNormalizedCacheTests.fetch")
    static let mutationQueue = DispatchQueue(label: "AWSSQLiteNormalizedCacheTests.mutations")

    var cacheConfiguration: AWSAppSyncCacheConfiguration!
    let mockHTTPTransport = MockAWSNetworkTransport()

    // Set up a new DB for each test
    override func setUp() {
        let tempDir = FileManager.default.temporaryDirectory
        let rootDirectory = tempDir.appendingPathComponent("AWSSQLiteNormalizedCacheTests-\(UUID().uuidString)")
        cacheConfiguration = try! AWSAppSyncCacheConfiguration(withRootDirectory: rootDirectory)
    }

    /// Xcode 10.2 introduced a behavior change in the #function expression that broke SQLite.swift. That
    /// manifested as a break in the caching behavior. This test simply asserts that our creation routine
    /// properly populates an initial QUERY_ROOT record as expected. This isn't technically testing the
    /// public API, but it's the simplest test that asserts the correct SQLite.swift behavior.
    /// See [Issue #211](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/issues/211)
    func testInitializedDatabaseHasQueryRoot() throws {
        _ = try UnitTestHelpers.makeAppSyncClient(using: mockHTTPTransport,
                                                  cacheConfiguration: cacheConfiguration)

        let queriesDB = try Connection(.uri(cacheConfiguration.queries!.absoluteString),
                                       readonly: false)

        let queryRootCount = try queriesDB.scalar("SELECT count(*) FROM records WHERE key='QUERY_ROOT'") as! Int64
        XCTAssertEqual(queryRootCount, 1)
    }
}
