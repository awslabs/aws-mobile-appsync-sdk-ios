//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
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
        try? FileManager.default.removeItem(at: databaseURL)

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
        try? FileManager.default.removeItem(at: databaseURL)

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
