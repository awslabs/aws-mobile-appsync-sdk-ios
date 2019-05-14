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

    func testCacheConfigThrowsWithInvalidClientDatabasePrefix() throws {
        let serviceConfigWithEmptyPrefix = MockAWSAppSyncServiceConfig(
            endpoint: URL(string: "http://www.amazon.com/for_unit_testing")!,
            region: .USEast1,
            authType: .apiKey,
            apiKey: "THE_API_KEY",
            clientDatabasePrefix: ""
        )
        let serviceConfigWithNilPrefix = MockAWSAppSyncServiceConfig(
            endpoint: URL(string: "http://www.amazon.com/for_unit_testing")!,
            region: .USEast1,
            authType: .apiKey,
            apiKey: "THE_API_KEY",
            clientDatabasePrefix: nil
        )

        // When the flag is false it should not throw, it should be false by default
        _ = try AWSAppSyncCacheConfiguration(useClientDatabasePrefix: false, appSyncServiceConfig: serviceConfigWithEmptyPrefix)
        _ = try AWSAppSyncCacheConfiguration(appSyncServiceConfig: serviceConfigWithEmptyPrefix)

        // When the flag is true the prefix should be used and empty string is not acceptable
        do {
            _ = try AWSAppSyncCacheConfiguration(useClientDatabasePrefix: true, appSyncServiceConfig: serviceConfigWithEmptyPrefix)
            XCTFail("Expected error attempting to initialize AWSAppSyncCacheConfiguration with empty prefix")
        } catch AWSCacheConfigurationError.invalidClientDatabasePrefix {
            // Caught a specific error
        }


        // When the flag is true the prefix should be used and nil is not acceptable
        do {
            _ = try AWSAppSyncCacheConfiguration(useClientDatabasePrefix: true, appSyncServiceConfig: serviceConfigWithNilPrefix)
            XCTFail("Expected error attempting to initialize AWSAppSyncCacheConfiguration with nil prefix")
        } catch AWSCacheConfigurationError.missingClientDatabasePrefix {
            // Caught a specific error
        }

    }

    func testCachConfigWithValidClientDatabasePrefix() throws {
        let serviceConfigWithFooPrefix = MockAWSAppSyncServiceConfig(
            endpoint: URL(string: "http://www.amazon.com/for_unit_testing")!,
            region: .USEast1,
            authType: .apiKey,
            apiKey: "THE_API_KEY",
            clientDatabasePrefix: "foo"
        )

        // The database prefix should be honored during url construction
        let cacheConfig = try AWSAppSyncCacheConfiguration(useClientDatabasePrefix: true, appSyncServiceConfig: serviceConfigWithFooPrefix)
        XCTAssertTrue(cacheConfig.queries!.absoluteString.hasSuffix("/Caches/appsync/foo_queries.db"))
        XCTAssertTrue(cacheConfig.offlineMutations!.absoluteString.hasSuffix("/Caches/appsync/foo_offlineMutations.db"))
        XCTAssertTrue(cacheConfig.subscriptionMetadataCache!.absoluteString.hasSuffix("/Caches/appsync/foo_subscriptionMetadataCache.db"))

        // The database prefix is ignored, a warning should be logged
        let cacheConfigIgnoresPrefix = try AWSAppSyncCacheConfiguration(useClientDatabasePrefix: false, appSyncServiceConfig: serviceConfigWithFooPrefix)
        XCTAssertTrue(cacheConfigIgnoresPrefix.queries!.absoluteString.hasSuffix("/Caches/appsync/queries.db"))
        XCTAssertTrue(cacheConfigIgnoresPrefix.offlineMutations!.absoluteString.hasSuffix("/Caches/appsync/offlineMutations.db"))
        XCTAssertTrue(cacheConfigIgnoresPrefix.subscriptionMetadataCache!.absoluteString.hasSuffix("/Caches/appsync/subscriptionMetadataCache.db"))
    }

    func testMultiClientWithSameDatabasePrefix() throws {
        let serviceConfigWithFooPrefix = MockAWSAppSyncServiceConfig(
            endpoint: URL(string: "http://www.amazon.com/for_unit_testing")!,
            region: .USEast1,
            authType: .apiKey,
            apiKey: "THE_API_KEY",
            clientDatabasePrefix: "foo"
        )
        let serviceConfigWithFooPrefix2 = MockAWSAppSyncServiceConfig(
            endpoint: URL(string: "http://www.amazon.com/another_url")!,
            region: .USEast1,
            authType: .apiKey,
            apiKey: "THE_API_KEY",
            clientDatabasePrefix: "foo"
        )
        let cacheConfig = try AWSAppSyncCacheConfiguration(useClientDatabasePrefix: true, appSyncServiceConfig: serviceConfigWithFooPrefix)
        let clientConfig = try AWSAppSyncClientConfiguration(appSyncServiceConfig: serviceConfigWithFooPrefix, cacheConfiguration: cacheConfig)
        let clientA = try AWSAppSyncClient(appSyncConfig: clientConfig)
        let clientB = try AWSAppSyncClient(appSyncConfig: clientConfig)
        _ = [clientA, clientB] // Silence unused variable warning

        let cacheConfig2 = try AWSAppSyncCacheConfiguration(useClientDatabasePrefix: true, appSyncServiceConfig: serviceConfigWithFooPrefix2)
        let clientConfig2 = try AWSAppSyncClientConfiguration(appSyncServiceConfig: serviceConfigWithFooPrefix2, cacheConfiguration: cacheConfig2)

        do {
            _ = try AWSAppSyncClient(appSyncConfig: clientConfig2)
            XCTFail("Expected error attempting to initialize client with same prefix, different endpoint")
        } catch AWSAppSyncClientConfigurationError.cacheConfigurationAlreadyInUse(let error) {
            XCTAssertNotNil(error)
        }
    }

    func testClientDatabasePrefixRegex() throws {
        let bad1 = MockAWSAppSyncServiceConfig(
            endpoint: URL(string: "http://www.amazon.com/for_unit_testing")!,
            region: .USEast1,
            authType: .apiKey,
            apiKey: "THE_API_KEY",
            clientDatabasePrefix: "!@#"
        )

        do {
            _ = try AWSAppSyncCacheConfiguration(useClientDatabasePrefix: true, appSyncServiceConfig: bad1)
            XCTFail("Expected error because prefix does not match regex")
        } catch AWSCacheConfigurationError.invalidClientDatabasePrefix {
            // specifically catch this error
        }
    }

}
