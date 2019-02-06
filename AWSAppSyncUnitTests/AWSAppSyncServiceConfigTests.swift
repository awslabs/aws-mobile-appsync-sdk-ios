//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import XCTest
@testable import AWSAppSync

class AWSAppSyncServiceConfigTests: XCTestCase {

    func testCanLoadFromDefaultConfigSection() {
        do {
            let config = try AWSAppSyncServiceConfig()
            XCTAssert(config.endpoint.absoluteString.starts(with: "https://default.appsync-api"))
        } catch {
            XCTFail("Can't load from default config section: \(error.localizedDescription)")
        }
    }

    func testCanLoadFromSpecifiedConfigSection() {
        do {
            let config = try AWSAppSyncServiceConfig(forKey: "UnitTests_GoodAPIKeyConfiguration")
            XCTAssert(config.endpoint.absoluteString.starts(with: "https://good-api-key.appsync-api"))
        } catch {
            XCTFail("Can't load from good-api-key config section: \(error.localizedDescription)")
        }
    }

    func testCanLoadValidAPIConfiguration() {
        do {
            let config = try AWSAppSyncServiceConfig(forKey: "UnitTests_GoodAPIKeyConfiguration")
            XCTAssertEqual(config.apiKey, "THE_API_KEY")
        } catch {
            XCTFail("Can't load from good-api-key config section: \(error.localizedDescription)")
        }
    }

    func testThrowsOnEmptyAPIKey() {
        do {
            let _ = try AWSAppSyncServiceConfig(forKey: "UnitTests_EmptyAPIKeyConfiguration")
            XCTFail("Expected validation to fail with empty API Key")
        } catch {
            guard case AWSAppSyncServiceConfigError.invalidAPIKey = error else {
                XCTFail("Expected validation to throw AWSAppSyncServiceConfigError.invalidAPIKey for empty API key, but got \(type(of: error))")
                return
            }
        }
    }

    func testThrowsOnMissingAPIKey() {
        do {
            let _ = try AWSAppSyncServiceConfig(forKey: "UnitTests_MissingAPIKeyConfiguration")
            XCTFail("Expected validation to fail with missing API Key")
        } catch {
            guard case AWSAppSyncServiceConfigError.invalidAPIKey = error else {
                XCTFail("Expected validation to throw AWSAppSyncServiceConfigError.invalidAPIKey for missing API key, but got \(type(of: error))")
                return
            }
        }
    }

}
