//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import XCTest
@testable import AWSAppSync
@testable import AWSAppSyncTestCommon
import SQLite

class AWSSQLiteNormalizedCacheTests: XCTestCase {

    var dbUri: URL!
    var cache: AWSSQLiteNormalizedCache!

    let records: RecordSet = [
        "QUERY_ROOT": ["hero": Reference(key: "hero")],
        "hero": [
            "name": "R2-D2",
        ]
    ]

    override func setUp() {
        let tempDir = FileManager.default.temporaryDirectory
        dbUri = tempDir.appendingPathComponent("AWSSQLiteNormalizedCacheTests-\(UUID().uuidString)")
        cache = try! AWSSQLiteNormalizedCache(fileURL: dbUri)
    }

    /// Xcode 10.2 introduced a behavior change in the #function expression that broke SQLite.swift. That
    /// manifested as a break in the caching behavior. This test simply asserts that our creation routine
    /// properly populates an initial QUERY_ROOT record as expected. This isn't technically testing the
    /// public API, but it's the simplest test that asserts the correct SQLite.swift behavior.
    /// See [Issue #211](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/issues/211)
    func testInitializedDatabaseHasQueryRoot() throws {
        let queriesDB = try Connection(.uri(dbUri.absoluteString), readonly: false)

        let queryRootCount = try queriesDB.scalar("SELECT count(*) FROM records WHERE key='QUERY_ROOT'") as! Int64
        XCTAssertEqual(queryRootCount, 1)
    }


    func testMergeRecordsReturnsCacheKeys() {
        let cacheKeys = try! cache.merge(records: records).await()
        XCTAssertEqual(cacheKeys, ["hero.name", "QUERY_ROOT.hero"])
    }

    func testMergeRecordsSavesThem() {
        _ = try! cache.merge(records: records).await()
        let loadedRecords = try! cache.loadRecords(forKeys: ["QUERY_ROOT", "hero"]).await()
        XCTAssertEqual(loadedRecords.count, 2)
        XCTAssertEqual(loadedRecords[0]?.key, "QUERY_ROOT")
        XCTAssertEqual(loadedRecords[1]?.key, "hero")
        XCTAssertEqual(loadedRecords[1]?.fields["name"] as? String, "R2-D2")
    }

    func testMergeRecordsPerformance() {
        var lotsOfRecords : RecordSet = [:]
        for index in (0...1000) {
            let record = Record(key: "\(index)", ["x": 1])
            lotsOfRecords.merge(record: record)
        }
        measure { _ = try! cache.merge(records: lotsOfRecords).await() }
    }
}
