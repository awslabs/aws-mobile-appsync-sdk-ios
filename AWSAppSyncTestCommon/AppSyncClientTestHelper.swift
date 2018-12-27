//
//  AppSyncClientTestHelper.swift
//  AWSAppSyncTests
//
//  Created by Schmelter, Tim on 12/5/18.
//  Copyright © 2018 Amazon Web Services. All rights reserved.
//

import Foundation

@testable import AWSAppSync
@testable import AWSCore

internal class DeinitNotifiableAppSyncClient: AWSAppSyncClient {
    var deinitCalled: (() -> Void)?

    deinit {
        deinitCalled?()
    }
}

public class AppSyncClientTestHelper: NSObject {
    public enum TestHelperError: Error, LocalizedError {
        case apolloError(String)
        case invalidAuthenticationType
        case setupError(String)

        public var errorDescription: String? {
            return localizedDescription
        }

        public var localizedDescription: String {
            switch self {
            case .apolloError(let message):
                return message
            case .invalidAuthenticationType:
                return "Invalid authentication type"
            case .setupError(let message):
                return message
            }
        }
    }

    public enum AuthenticationType {
        case apiKey
        case cognitoIdentityPools
        case invalidAPIKey
        case invalidOIDC
        case invalidStaticCredentials
    }

    static let testSetupErrorMessage = """
    Could not load appsync_test_credentials.json which is required to run the tests in this class.\n
    To run this test class, please add a file named appsync_test_credentials.json in AWSAppSyncTests folder of this project. You can alternatively update `AppSyncEndpointURL` and `CognitoIdentityPoolId` values to use inline values. \n\n
    Format of the config file:
    {
       "AppSyncEndpoint": "https://abc2131absc.appsync-api.us-east-1.amazonaws.com/graphql",
       "AppSyncRegion": "us-east-1",
       "CognitoIdentityPoolId": "us-east-1:abc123-1234-123a-a123-12345fe123",
       "CognitoIdentityPoolRegion": "us-east-1",
       "AppSyncEndpointAPIKey": "https://apikeybasedendpoint.appsync-api.us-east-1.amazonaws.com/graphql",
       "AppSyncEndpointAPIKeyRegion": "us-east-1",
       "AppSyncAPIKey": "da2-sad3lkh23422"
    }

    The test uses 2 different backend setups (one for IAM (Cognito Identity) auth, and one for API Key
    auth) for tests, which are created by importing the CloudFormation template
    `ConsoleResources/appsync-functionaltests-cloudformation.yaml` into the AWS CloudFormation Console.
    """

    let appSyncClient: DeinitNotifiableAppSyncClient

    /// Creates a test helper that vends a `DeinitNotifiableAppSyncClient`
    ///
    /// - Parameters:
    ///   - authenticationType: an `AuthenticationType` to use for authenticating the client.
    ///     For tests where there are no network calls, use `.apiKey`
    ///   - testConfiguration: an optional test configuration to use for setting up the client. If the test helper is being
    ///     created for unit testing, use AppSyncClientTestConfiguration.UnitTestConfiguration. If nil, init will attempt to
    ///     create a configuration using the `appsync_test_credentials.json` file in the `testBundle`. If that file is not
    ///     present, it will use the values stored in `AppSyncClientTestConfigurationDefaults`, which must be updated to have
    ///     valid values.
    ///   - databaseURL: a URL to store the cache database, nor `nil` if the database should be in memory
    ///   - httpTransport: an override for the default AWSNetworkTransport, e.g., `MockNetworkTransport` to allow
    ///     inspection of network calls
    /// - Throws:
    ///    - `TestHelperError.setupError` if the test credentials aren't properly set up in either
    ///      `AppSyncClientTestConfigurationDefaults` or `appsync_test_credentials.json`
    ///    - Any errors received during configuration setup
    init(with authenticationType: AuthenticationType,
         testConfiguration: AppSyncClientTestConfiguration? = nil,
         databaseURL: URL? = nil,
         httpTransport: AWSNetworkTransport? = nil,
         s3ObjectManager: AWSS3ObjectManager? = nil,
         testBundle: Bundle = Bundle(for: AppSyncClientTestHelper.self)) throws {

        // Read credentials from appsync_test_credentials.json or hardcoded values
        let resolvedTestConfiguration = testConfiguration ?? AppSyncClientTestConfiguration(with: testBundle) ?? AppSyncClientTestConfiguration()
        guard resolvedTestConfiguration.isValid else {
            throw TestHelperError.setupError(AppSyncClientTestHelper.testSetupErrorMessage)
        }

        AWSDDLog.sharedInstance.logLevel = .error
        AWSDDLog.add(AWSDDTTYLogger.sharedInstance)

        let appSyncConfig = try AppSyncClientTestHelper.makeAppSyncConfiguration(
            for: authenticationType,
            testConfiguration: resolvedTestConfiguration,
            databaseURL: databaseURL,
            httpTransport: httpTransport,
            s3ObjectManager: s3ObjectManager
        )

        appSyncClient = try DeinitNotifiableAppSyncClient(appSyncConfig: appSyncConfig)

        // Set id as the cache key for objects
        guard let apolloClient = appSyncClient.apolloClient else {
            throw TestHelperError.apolloError("Unable to retrieve Apollo client from appSyncClient")
        }

        apolloClient.cacheKeyForObject = { $0["id"] }
    }

    static func makeAppSyncConfiguration(
        for authenticationType: AuthenticationType,
        testConfiguration: AppSyncClientTestConfiguration,
        databaseURL: URL?,
        httpTransport: AWSNetworkTransport?,
        s3ObjectManager: AWSS3ObjectManager?
    ) throws -> AWSAppSyncClientConfiguration {

        var appSyncConfig: AWSAppSyncClientConfiguration
        switch authenticationType {
        case .apiKey:
            let apiKeyAuthProvider = MockAWSAPIKeyAuthProvider(with: testConfiguration)
            appSyncConfig = try AWSAppSyncClientConfiguration(
                url: testConfiguration.apiKeyEndpointURL,
                serviceRegion: testConfiguration.apiKeyEndpointRegion,
                apiKeyAuthProvider: apiKeyAuthProvider,
                databaseURL: databaseURL,
                s3ObjectManager: s3ObjectManager
            )

        case .cognitoIdentityPools:
            let credentialsProvider = BasicAWSCognitoCredentialsProviderFactory.makeCredentialsProvider(with: testConfiguration)
            appSyncConfig = try AWSAppSyncClientConfiguration(
                url: testConfiguration.cognitoPoolEndpointURL,
                serviceRegion: testConfiguration.cognitoPoolEndpointRegion,
                credentialsProvider: credentialsProvider,
                databaseURL: databaseURL,
                s3ObjectManager: s3ObjectManager
            )

        case .invalidAPIKey:
            let apiKeyAuthProvider = MockAWSAPIKeyAuthProvider(with: "INVALID_API_KEY")
            appSyncConfig = try AWSAppSyncClientConfiguration(
                url: testConfiguration.apiKeyEndpointURL,
                serviceRegion: testConfiguration.apiKeyEndpointRegion,
                apiKeyAuthProvider: apiKeyAuthProvider,
                databaseURL: databaseURL,
                s3ObjectManager: s3ObjectManager
            )

        case .invalidOIDC:
            let oidcAuthProvider = MockAWSOIDCAuthProvider()
            appSyncConfig = try AWSAppSyncClientConfiguration(
                url: testConfiguration.apiKeyEndpointURL,
                serviceRegion: testConfiguration.apiKeyEndpointRegion,
                oidcAuthProvider: oidcAuthProvider,
                databaseURL: databaseURL,
                s3ObjectManager: s3ObjectManager
            )

        case .invalidStaticCredentials:
            let credentialsProvider = AWSStaticCredentialsProvider(accessKey: "INVALID_ACCESS_KEY", secretKey: "INVALID_SECRET_KEY")
            appSyncConfig = try AWSAppSyncClientConfiguration(
                url: testConfiguration.apiKeyEndpointURL,
                serviceRegion: testConfiguration.apiKeyEndpointRegion,
                credentialsProvider: credentialsProvider,
                databaseURL: databaseURL,
                s3ObjectManager: s3ObjectManager
            )

        }

        return appSyncConfig
    }

//    func deleteAll() {
//        let query = ListEventsQuery(limit: 99)
//        let listEventsExpectation = expectation(description: "Fetch done successfully.")
//
//        var events: [ListEventsQuery.Data.ListEvent.Item?]?
//
//        appSyncClient.fetch(query: query, cachePolicy: .fetchIgnoringCacheData) { (result, error) in
//            XCTAssertNil(error, "Error expected to be nil, but is not.")
//            XCTAssertNotNil(result?.data?.listEvents?.items, "Items array should not be nil.")
//            events = result?.data?.listEvents?.items
//            listEventsExpectation.fulfill()
//        }
//
//        // Wait for the list to complete
//        wait(for: [listEventsExpectation], timeout: 5.0)
//
//        guard let eventsToDelete = events else {
//            return
//        }
//
//        var deleteExpectations = [XCTestExpectation]()
//        for event in eventsToDelete {
//            guard let event = event else {
//                continue
//            }
//
//            let deleteExpectation = expectation(description: "Delete event \(event.id)")
//            deleteExpectations.append(deleteExpectation)
//
//            appSyncClient.perform(
//                mutation: DeleteEventMutation(id: event.id),
//                queue: DispatchQueue.main,
//                optimisticUpdate: nil,
//                conflictResolutionBlock: nil,
//                resultHandler: {
//                    (result, error) in
//                    guard let _ = result else {
//                        if let error = error {
//                            XCTFail(error.localizedDescription)
//                        } else {
//                            XCTFail("Error deleting \(event.id)")
//                        }
//                        return
//                    }
//                    deleteExpectation.fulfill()
//            }
//            )
//        }
//
//        wait(for: deleteExpectations, timeout: 5.0)
//    }

}

private struct BasicAWSCognitoCredentialsProviderFactory {
    static func makeCredentialsProvider(with configuration: AppSyncClientTestConfiguration) -> AWSCognitoCredentialsProvider {
        let credentialsProvider = AWSCognitoCredentialsProvider(
            regionType: configuration.cognitoPoolEndpointRegion,
            identityPoolId: configuration.cognitoPoolId
        )
        credentialsProvider.clearCredentials()
        credentialsProvider.clearKeychain()
        return credentialsProvider
    }
}
