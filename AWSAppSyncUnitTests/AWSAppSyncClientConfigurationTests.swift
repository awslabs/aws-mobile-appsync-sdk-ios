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

class AWSAppSyncClientConfigurationTests: XCTestCase {

    // MARK: - Test initializers that specify the network transport

    // This will directly test the convenience initializer, which delegates to the designated initializer. Since this has no
    // particularly interesting logic, one test will suffice to cover both initializers.
    func testInitializer_SpecifyingNetworkTransport_ClientInfo() {
        let serviceConfig = MockAWSAppSyncServiceConfig(
            endpoint: URL(string: "http://www.amazon.com/for_unit_testing")!,
            region: .USEast1,
            authType: .apiKey,
            apiKey: "THE_API_KEY"
        )

        let networkTransport = MockNetworkTransport()

        let _ = AWSAppSyncClientConfiguration(appSyncServiceConfig: serviceConfig, networkTransport: networkTransport)
    }

    // MARK: - Test convenience initializer that derives the authType from the incoming auth providers

    func testInitializer_DerivedAuthType_APIKey() throws {
        do {
            let _ = try AWSAppSyncClientConfiguration(url: URL(string: "http://www.amazon.com/for_unit_testing")!,
                                                      serviceRegion: "us-east-1".aws_regionTypeValue(),
                                                      apiKeyAuthProvider: MockAWSAPIKeyAuthProvider())
        } catch {
            XCTFail("Error thrown during initialization: \(error)")
        }
    }

    func testInitializer_DerivedAuthType_IAM() {
        do {
            let _ = try AWSAppSyncClientConfiguration(url: URL(string: "http://www.amazon.com/for_unit_testing")!,
                                                      serviceRegion: "us-east-1".aws_regionTypeValue(),
                                                      credentialsProvider: MockAWSCredentialsProvider())
        } catch {
            XCTFail("Error thrown during initialization: \(error)")
        }
    }

    func testInitializer_DerivedAuthType_OIDC() {
        do {
            let _ = try AWSAppSyncClientConfiguration(url: URL(string: "http://www.amazon.com/for_unit_testing")!,
                                                      serviceRegion: "us-east-1".aws_regionTypeValue(),
                                                      oidcAuthProvider: MockAWSOIDCAuthProvider())
        } catch {
            XCTFail("Error thrown during initialization: \(error)")
        }
    }

    func testInitializer_DerivedAuthType_UserPools() {
        do {
            let _ = try AWSAppSyncClientConfiguration(url: URL(string: "http://www.amazon.com/for_unit_testing")!,
                                                      serviceRegion: "us-east-1".aws_regionTypeValue(),
                                                      userPoolsAuthProvider: MockAWSCognitoUserPoolsAuthProvider())
        } catch {
            XCTFail("Error thrown during initialization: \(error)")
        }
    }

    func testInitializer_DerivedAuthType_RequiresAtLeastOneProvider() {
        do {
            let _ = try AWSAppSyncClientConfiguration(url: URL(string: "http://www.amazon.com/for_unit_testing")!,
                                                      serviceRegion: "us-east-1".aws_regionTypeValue())
            XCTFail("Expected validation to fail with no auth providers")
        } catch {
            guard let clientInfoError = error as? AWSAppSyncClientConfigurationError else {
                XCTFail("Expected validation to throw AWSAppSyncClientInfoError with no auth providers, but got \(type(of: error))")
                return
            }
            XCTAssert(clientInfoError.localizedDescription.starts(with: "Invalid Auth Configuration"), "Expected error to begin with 'Invalid Auth Configuration', but got '\(clientInfoError.localizedDescription)'")
        }
    }

    func testInitializer_DerivedAuthType_RequiresNoMoreThanOneProvider() {
        do {
            let _ = try AWSAppSyncClientConfiguration(url: URL(string: "http://www.amazon.com/for_unit_testing")!,
                                                      serviceRegion: "us-east-1".aws_regionTypeValue(),
                                                      apiKeyAuthProvider: MockAWSAPIKeyAuthProvider(),
                                                      credentialsProvider: MockAWSCredentialsProvider())
            XCTFail("Expected validation to fail with multiple auth providers")
        } catch {
            guard let clientInfoError = error as? AWSAppSyncClientConfigurationError else {
                XCTFail("Expected validation to throw AWSAppSyncClientInfoError with multiple auth providers, but got \(type(of: error))")
                return
            }
            XCTAssert(clientInfoError.localizedDescription.starts(with: "Invalid Auth Configuration"), "Expected error to begin with 'Invalid Auth Configuration', but got '\(clientInfoError.localizedDescription)'")
        }
    }

    // MARK: - Test initializers that derive the network transport from auth provider configuration

    func testInitializer_ClientInfoAuthType_SpecifiedAPIKeyButNoProvider() {
        let serviceConfig = MockAWSAppSyncServiceConfig(
            endpoint: URL(string: "http://www.amazon.com/for_unit_testing")!,
            region: .USEast1,
            authType: .apiKey,
            apiKey: "THE_API_KEY"
        )

        do {
            let _ = try AWSAppSyncClientConfiguration(appSyncServiceConfig: serviceConfig)
        } catch {
            XCTFail("Error thrown during initialization: \(error.localizedDescription)")
        }
    }

    func testInitializer_ClientInfoAuthType_SpecifiedAPIKeyAndProvider() {
        let serviceConfig = MockAWSAppSyncServiceConfig(
            endpoint: URL(string: "http://www.amazon.com/for_unit_testing")!,
            region: .USEast1,
            authType: .apiKey,
            apiKey: "THE_UNUSED_API_KEY"
        )

        do {
            let _ = try AWSAppSyncClientConfiguration(appSyncServiceConfig: serviceConfig,
                                                      apiKeyAuthProvider: MockAWSAPIKeyAuthProvider())
        } catch {
            XCTFail("Error thrown during initialization: \(error.localizedDescription)")
        }
    }

    func testInitializer_ClientInfoAuthType_SpecifiedIAMAndProvider() {
        let serviceConfig = MockAWSAppSyncServiceConfig(
            endpoint: URL(string: "http://www.amazon.com/for_unit_testing")!,
            region: .USEast1,
            authType: .awsIAM
        )

        do {
            let _ = try AWSAppSyncClientConfiguration(appSyncServiceConfig: serviceConfig,
                                                      credentialsProvider: MockAWSCredentialsProvider())
        } catch {
            XCTFail("Error thrown during initialization: \(error.localizedDescription)")
        }
    }

    func testInitializer_ClientInfoAuthType_SpecifiedIAMButNoProvider() {
        let serviceConfig = MockAWSAppSyncServiceConfig(
            endpoint: URL(string: "http://www.amazon.com/for_unit_testing")!,
            region: .USEast1,
            authType: .awsIAM
        )

        do {
            let _ = try AWSAppSyncClientConfiguration(appSyncServiceConfig: serviceConfig)
        } catch {
            XCTFail("Error thrown during initialization: \(error.localizedDescription)")
        }
    }

    func testInitializer_ClientInfoAuthType_SpecifiedOIDCAndProvider() {
        let serviceConfig = MockAWSAppSyncServiceConfig(
            endpoint: URL(string: "http://www.amazon.com/for_unit_testing")!,
            region: .USEast1,
            authType: .oidcToken
        )

        do {
            let _ = try AWSAppSyncClientConfiguration(appSyncServiceConfig: serviceConfig,
                                                      oidcAuthProvider: MockAWSOIDCAuthProvider())
        } catch {
            XCTFail("Error thrown during initialization: \(error.localizedDescription)")
        }
    }

    func testInitializer_ClientInfoAuthType_SpecifiedOIDCButNoProviderFails() {
        let serviceConfig = MockAWSAppSyncServiceConfig(
            endpoint: URL(string: "http://www.amazon.com/for_unit_testing")!,
            region: .USEast1,
            authType: .oidcToken
        )

        do {
            let _ = try AWSAppSyncClientConfiguration(appSyncServiceConfig: serviceConfig)
            XCTFail("Expected validation to fail if not specifying OIDC provider")
        } catch {
            guard let clientInfoError = error as? AWSAppSyncClientConfigurationError else {
                XCTFail("Expected validation to throw AWSAppSyncClientInfoError if not specifying OIDC provider, but got \(type(of: error))")
                return
            }
            XCTAssert(clientInfoError.localizedDescription.starts(with: "Invalid Auth Configuration"), "Expected error to begin with 'Invalid Auth Configuration', but got '\(clientInfoError.localizedDescription)'")
        }
    }

    func testInitializer_ClientInfoAuthType_SpecifiedUserPoolsAndProvider() {
        let serviceConfig = MockAWSAppSyncServiceConfig(
            endpoint: URL(string: "http://www.amazon.com/for_unit_testing")!,
            region: .USEast1,
            authType: .amazonCognitoUserPools
        )

        do {
            let _ = try AWSAppSyncClientConfiguration(appSyncServiceConfig: serviceConfig,
                                                      userPoolsAuthProvider: MockAWSCognitoUserPoolsAuthProvider())
        } catch {
            XCTFail("Error thrown during initialization: \(error.localizedDescription)")
        }
    }

    func testInitializer_ClientInfoAuthType_SpecifiedUserPoolsButNoProviderFails() {
        let serviceConfig = MockAWSAppSyncServiceConfig(
            endpoint: URL(string: "http://www.amazon.com/for_unit_testing")!,
            region: .USEast1,
            authType: .amazonCognitoUserPools
        )

        do {
            let _ = try AWSAppSyncClientConfiguration(appSyncServiceConfig: serviceConfig)
            XCTFail("Expected validation to fail if not specifying OIDC provider")
        } catch {
            guard let clientInfoError = error as? AWSAppSyncClientConfigurationError else {
                XCTFail("Expected validation to throw AWSAppSyncClientInfoError if not specifying user pools provider, but got \(type(of: error))")
                return
            }
            XCTAssert(clientInfoError.localizedDescription.starts(with: "Invalid Auth Configuration"), "Expected error to begin with 'Invalid Auth Configuration', but got '\(clientInfoError.localizedDescription)'")
        }
    }

    // MARK: - Test mismatched authType to provider list validation

    func testInitializer_MismatchedAuthTypeAndProvider_APIKey() {
        let serviceConfig = MockAWSAppSyncServiceConfig(
            endpoint: URL(string: "http://www.amazon.com/for_unit_testing")!,
            region: .USEast1,
            authType: .apiKey,
            apiKey: "THE_API_KEY"
        )

        do {
            let _ = try AWSAppSyncClientConfiguration(appSyncServiceConfig: serviceConfig,
                                                      credentialsProvider: MockAWSCredentialsProvider())
        } catch {
            guard let clientInfoError = error as? AWSAppSyncClientConfigurationError else {
                XCTFail("Expected validation to throw AWSAppSyncClientInfoError if specifying mismatched provider, but got \(type(of: error))")
                return
            }
            XCTAssert(clientInfoError.localizedDescription.starts(with: "Invalid Auth Configuration"), "Expected error to begin with 'Invalid Auth Configuration', but got '\(clientInfoError.localizedDescription)'")
        }
    }

    func testInitializer_MismatchedAuthTypeAndProvider_IAM() {
        let serviceConfig = MockAWSAppSyncServiceConfig(
            endpoint: URL(string: "http://www.amazon.com/for_unit_testing")!,
            region: .USEast1,
            authType: .awsIAM
        )

        do {
            let _ = try AWSAppSyncClientConfiguration(appSyncServiceConfig: serviceConfig,
                                                      apiKeyAuthProvider: MockAWSAPIKeyAuthProvider())
        } catch {
            guard let clientInfoError = error as? AWSAppSyncClientConfigurationError else {
                XCTFail("Expected validation to throw AWSAppSyncClientInfoError if specifying mismatched provider, but got \(type(of: error))")
                return
            }
            XCTAssert(clientInfoError.localizedDescription.starts(with: "Invalid Auth Configuration"), "Expected error to begin with 'Invalid Auth Configuration', but got '\(clientInfoError.localizedDescription)'")
        }
    }

    // MARK: - Test multiple provider validation

    func testInitializer_MultipleProviders_APIKey() {
        let serviceConfig = MockAWSAppSyncServiceConfig(
            endpoint: URL(string: "http://www.amazon.com/for_unit_testing")!,
            region: .USEast1,
            authType: .apiKey
        )

        do {
            let _ = try AWSAppSyncClientConfiguration(appSyncServiceConfig: serviceConfig,
                                                      apiKeyAuthProvider: MockAWSAPIKeyAuthProvider(),
                                                      credentialsProvider: MockAWSCredentialsProvider())
            XCTFail("Expected validation to fail with multiple auth providers")
        } catch {
            guard let clientInfoError = error as? AWSAppSyncClientConfigurationError else {
                XCTFail("Expected validation to throw AWSAppSyncClientInfoError if specifying multiple providers, but got \(type(of: error))")
                return
            }
            XCTAssert(clientInfoError.localizedDescription.starts(with: "Invalid Auth Configuration"), "Expected error to begin with 'Invalid Auth Configuration', but got '\(clientInfoError.localizedDescription)'")
        }
    }

    func testInitializer_MultipleProviders_IAM() {
        let serviceConfig = MockAWSAppSyncServiceConfig(
            endpoint: URL(string: "http://www.amazon.com/for_unit_testing")!,
            region: .USEast1,
            authType: .awsIAM
        )

        do {
            let _ = try AWSAppSyncClientConfiguration(appSyncServiceConfig: serviceConfig,
                                                      apiKeyAuthProvider: MockAWSAPIKeyAuthProvider(),
                                                      credentialsProvider: MockAWSCredentialsProvider())
            XCTFail("Expected validation to fail with multiple auth providers")
        } catch {
            guard let clientInfoError = error as? AWSAppSyncClientConfigurationError else {
                XCTFail("Expected validation to throw AWSAppSyncClientInfoError if specifying multiple providers, but got \(type(of: error))")
                return
            }
            XCTAssert(clientInfoError.localizedDescription.starts(with: "Invalid Auth Configuration"), "Expected error to begin with 'Invalid Auth Configuration', but got '\(clientInfoError.localizedDescription)'")
        }
    }

    func testInitializer_MultipleProviders_OIDC() {
        let serviceConfig = MockAWSAppSyncServiceConfig(
            endpoint: URL(string: "http://www.amazon.com/for_unit_testing")!,
            region: .USEast1,
            authType: .oidcToken
        )

        do {
            let _ = try AWSAppSyncClientConfiguration(appSyncServiceConfig: serviceConfig,
                                                      apiKeyAuthProvider: MockAWSAPIKeyAuthProvider(),
                                                      oidcAuthProvider: MockAWSOIDCAuthProvider())
            XCTFail("Expected validation to fail with multiple auth providers")
        } catch {
            guard let clientInfoError = error as? AWSAppSyncClientConfigurationError else {
                XCTFail("Expected validation to throw AWSAppSyncClientInfoError if specifying multiple providers, but got \(type(of: error))")
                return
            }
            XCTAssert(clientInfoError.localizedDescription.starts(with: "Invalid Auth Configuration"), "Expected error to begin with 'Invalid Auth Configuration', but got '\(clientInfoError.localizedDescription)'")
        }
    }

    func testInitializer_MultipleProviders_UserPools() {
        let serviceConfig = MockAWSAppSyncServiceConfig(
            endpoint: URL(string: "http://www.amazon.com/for_unit_testing")!,
            region: .USEast1,
            authType: .amazonCognitoUserPools
        )

        do {
            let _ = try AWSAppSyncClientConfiguration(appSyncServiceConfig: serviceConfig,
                                                      apiKeyAuthProvider: MockAWSAPIKeyAuthProvider(),
                                                      userPoolsAuthProvider: MockAWSCognitoUserPoolsAuthProvider())
            XCTFail("Expected validation to fail with multiple auth providers")
        } catch {
            guard let clientInfoError = error as? AWSAppSyncClientConfigurationError else {
                XCTFail("Expected validation to throw AWSAppSyncClientInfoError if specifying multiple providers, but got \(type(of: error))")
                return
            }
            XCTAssert(clientInfoError.localizedDescription.starts(with: "Invalid Auth Configuration"), "Expected error to begin with 'Invalid Auth Configuration', but got '\(clientInfoError.localizedDescription)'")
        }
    }

    // MARK: - Test other derived properties

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

        let uuid = UUID().uuidString
        let databaseURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(uuid).db")

        do {
            try FileManager.default.removeItem(at: databaseURL)
        } catch {
            // Expected error -- we don't actually expect a random DB name to exist
        }

        let configuration: AWSAppSyncClientConfiguration
        do {
            configuration = try AWSAppSyncClientConfiguration(appSyncServiceConfig: serviceConfig)
        } catch {
            XCTFail("Unexpected error initializing client config: \(error)")
            return
        }

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
