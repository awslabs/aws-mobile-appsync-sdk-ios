//
// Copyright 2010-2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
