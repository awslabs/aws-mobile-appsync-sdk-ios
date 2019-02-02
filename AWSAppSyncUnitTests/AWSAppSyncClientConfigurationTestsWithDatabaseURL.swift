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
@testable import AWSAppSyncTestCommon
@testable import AWSAppSync

@available(*, deprecated, message: "Will be removed when we remove the databaseURL initializers")
class AWSAppSyncClientConfigurationTestsWithDatabaseURL: XCTestCase {

    func testStoreAndSubscriptionCacheWithValidDatabaseURL() {
        let serviceConfig = MockAWSAppSyncServiceConfig(
            endpoint: URL(string: "http://www.amazon.com/for_unit_testing")!,
            region: .USEast1,
            authType: .apiKey,
            apiKey: "THE_API_KEY"
        )

        let uuid = UUID().uuidString
        let databaseURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(uuid).db")

        do {
            try FileManager.default.removeItem(at: databaseURL)
        } catch {
            // Expected error -- we don't actually expect a random DB name to exist
        }

        let configuration: AWSAppSyncClientConfiguration
        do {
            configuration = try AWSAppSyncClientConfiguration(appSyncServiceConfig: serviceConfig,
                                                              databaseURL: databaseURL)
        } catch {
            XCTFail("Unexpected error initializing client config: \(error)")
            return
        }

        XCTAssertNotNil(configuration.store)
        XCTAssertNotNil(configuration.subscriptionMetadataCache)
        XCTAssert(FileManager.default.fileExists(atPath: databaseURL.path))

        do {
            try FileManager.default.removeItem(at: databaseURL)
        } catch {
            XCTFail("Unexpected error removing database during cleanup: \(error)")
            return
        }
    }

    func testStoreAndSubscriptionCacheWithEmptyDatabaseURL() {
        let serviceConfig = MockAWSAppSyncServiceConfig(
            endpoint: URL(string: "http://www.amazon.com/for_unit_testing")!,
            region: .USEast1,
            authType: .apiKey,
            apiKey: "THE_API_KEY"
        )

        let configuration: AWSAppSyncClientConfiguration
        do {
            configuration = try AWSAppSyncClientConfiguration(appSyncServiceConfig: serviceConfig)
        } catch {
            XCTFail("Unexpected error initializing client config: \(error)")
            return
        }

        // Assert that the setup has created cache objects even without a URL
        XCTAssertNotNil(configuration.store)
        XCTAssertNil(configuration.subscriptionMetadataCache)
    }

    func testStoreAndSubscriptionCacheWithInvalidDatabaseURL() {
        let serviceConfig = MockAWSAppSyncServiceConfig(
            endpoint: URL(string: "http://www.amazon.com/for_unit_testing")!,
            region: .USEast1,
            authType: .apiKey,
            apiKey: "THE_API_KEY"
        )

        let uuid = UUID().uuidString
        let databaseURL = URL(fileURLWithPath: "/This/Path/Definitely/Does/Not/Exist/\(uuid)/failure.db")

        do {
            try FileManager.default.removeItem(at: databaseURL)
        } catch {
            // Expected error -- we don't actually expect a random DB name to exist
        }

        let configuration: AWSAppSyncClientConfiguration
        do {
            configuration = try AWSAppSyncClientConfiguration(appSyncServiceConfig: serviceConfig,
                                                              databaseURL: databaseURL)
        } catch {
            XCTFail("Unexpected error initializing client config: \(error)")
            return
        }

        XCTAssertNotNil(configuration.store)
        XCTAssertNil(configuration.subscriptionMetadataCache)
        XCTAssertFalse(FileManager.default.fileExists(atPath: databaseURL.path))
    }
}

private struct MockAWSAppSyncServiceConfig: AWSAppSyncServiceConfigProvider {
    let endpoint: URL
    let region: AWSRegionType
    let authType: AWSAppSyncAuthType
    let apiKey: String?

    init(endpoint: URL,
         region: AWSRegionType,
         authType: AWSAppSyncAuthType,
         apiKey: String? = nil) {
        self.endpoint = endpoint
        self.region = region
        self.authType = authType
        self.apiKey = apiKey
    }
}
