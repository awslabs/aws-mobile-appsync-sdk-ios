//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import XCTest
@testable import AWSAppSync

class AWSAppSyncCacheConfigurationTests: XCTestCase {

    func testCacheConfigDefaultsToCachePath() throws {
        let expectedPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.path
        let config = try AWSAppSyncCacheConfiguration()
        XCTAssert(config.offlineMutations!.path.starts(with: expectedPath))
        XCTAssert(config.queries!.path.starts(with: expectedPath))
        XCTAssert(config.subscriptionMetadataCache!.path.starts(with: expectedPath))
    }

    func testInMemoryConvenienceMember() {
        XCTAssertNil(AWSAppSyncCacheConfiguration.inMemory.offlineMutations)
        XCTAssertNil(AWSAppSyncCacheConfiguration.inMemory.queries)
        XCTAssertNil(AWSAppSyncCacheConfiguration.inMemory.subscriptionMetadataCache)
    }

    func testCacheConfigThrowsWithInvalidRootDirectory() throws {
        let pathCannotBeCreated = URL(fileURLWithPath: "/Paths/From/Root/Cannot/Be/Created")

        do {
            let _ = try AWSAppSyncCacheConfiguration(withRootDirectory: pathCannotBeCreated)
        } catch {
            XCTAssertNotNil(error)
            return
        }

        XCTFail("Expected error attempting to initialize AWSAppSyncCacheConfiguration at \(pathCannotBeCreated.path)")
    }

}
