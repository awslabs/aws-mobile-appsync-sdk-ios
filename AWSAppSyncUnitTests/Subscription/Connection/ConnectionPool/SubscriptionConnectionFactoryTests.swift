//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import XCTest
@testable import AWSAppSync
@testable import AWSAppSyncTestCommon

class SubscriptionConnectionFactoryTests: XCTestCase {

    let url = URL(string: "http://appsyncendpoint.com/graphql")!

    /// Test the initial state of the factory
    ///
    /// - Given: An initiated factory object
    /// - When:
    ///    - I check the internal state
    /// - Then:
    ///    - States should be consistent
    ///
    func testInitialState() {
        let connectionFactory = BasicSubscriptionConnectionFactory(url: url,
                                                                   authType: .apiKey,
                                                                   retryStrategy: .aggressive,
                                                                   region: .USWest2,
                                                                   apiKeyProvider: MockAPIKeyAuthProvider(),
                                                                   cognitoUserPoolProvider: MockUserPoolsAuthProvider(),
                                                                   oidcAuthProvider: MockUserPoolsAuthProvider(),
                                                                   iamAuthProvider: MockIAMAuthProvider())
        XCTAssertNotNil(connectionFactory.authInterceptor)
    }
    
    /// Test succesfull retrieval of IAM subscription connections
    ///
    /// - Given: A connection factory
    /// - When:
    ///    - Invoke connection(for:, authType:, connectionType:)
    /// - Then:
    ///    - I should get a non-nil connection
    ///
    func testRetrieveIAMConnection() {
        let connectionFactory = BasicSubscriptionConnectionFactory(url: url,
                                                                   authType: .apiKey,
                                                                   retryStrategy: .aggressive,
                                                                   region: .USWest2,
                                                                   apiKeyProvider: nil,
                                                                   cognitoUserPoolProvider: nil,
                                                                   oidcAuthProvider: nil,
                                                                   iamAuthProvider: MockIAMAuthProvider())
        let connection = connectionFactory.connection(for: url,
                                                      authType: .awsIAM,
                                                      connectionType: .appSyncRealtime)
        XCTAssertNotNil(connection)
    }
    
    /// Test succesfull retrieval of UserPools subscription connections
    ///
    /// - Given: A connection factory
    /// - When:
    ///    - Invoke connection(for:, authType:, connectionType:)
    /// - Then:
    ///    - I should get a non-nil connection
    ///
    func testRetrieveUserPoolConnection() {
        let connectionFactory = BasicSubscriptionConnectionFactory(url: url,
                                                                   authType: .apiKey,
                                                                   retryStrategy: .aggressive,
                                                                   region: .USWest2,
                                                                   apiKeyProvider: nil,
                                                                   cognitoUserPoolProvider: nil,
                                                                   oidcAuthProvider: nil,
                                                                   iamAuthProvider: MockIAMAuthProvider())
        let connection = connectionFactory.connection(for: url,
                                                      authType: .amazonCognitoUserPools,
                                                      connectionType: .appSyncRealtime)
        XCTAssertNotNil(connection)
    }
    
    /// Test succesfull retrieval of Apikey subscription connections
    ///
    /// - Given: A connection factory
    /// - When:
    ///    - Invoke connection(for:, authType:, connectionType:)
    /// - Then:
    ///    - I should get a non-nil connection
    ///
    func testRetrieveAPIKeyConnection() {
        let connectionFactory = BasicSubscriptionConnectionFactory(url: url,
        authType: .apiKey,
        retryStrategy: .aggressive,
        region: .USWest2,
        apiKeyProvider: MockAPIKeyAuthProvider(),
        cognitoUserPoolProvider: MockUserPoolsAuthProvider(),
        oidcAuthProvider: MockUserPoolsAuthProvider(),
        iamAuthProvider: MockIAMAuthProvider())
        let connection = connectionFactory.connection(for: url,
                                                      authType: .apiKey,
                                                      connectionType: .appSyncRealtime)
        XCTAssertNotNil(connection)
    }
    
    /// Test succesfull retrieval of OIDC subscription connections
    ///
    /// - Given: A connection factory
    /// - When:
    ///    - Invoke connection(for:, authType:, connectionType:)
    /// - Then:
    ///    - I should get a non-nil connection
    ///
    func testRetrieveOIDCConnection() {
        let connectionFactory = BasicSubscriptionConnectionFactory(url: url,
        authType: .apiKey,
        retryStrategy: .aggressive,
        region: .USWest2,
        apiKeyProvider: MockAPIKeyAuthProvider(),
        cognitoUserPoolProvider: MockUserPoolsAuthProvider(),
        oidcAuthProvider: MockUserPoolsAuthProvider(),
        iamAuthProvider: MockIAMAuthProvider())
        let connection = connectionFactory.connection(for: url,
                                                      authType: .oidcToken,
                                                      connectionType: .appSyncRealtime)
        XCTAssertNotNil(connection)
    }
    
    /// Test succesfull retrieval of multiple subscription connections together
    ///
    /// - Given: A connection factory
    /// - When:
    ///    - Invoke connection(for:, authType:, connectionType:) multiple times
    /// - Then:
    ///    - I should get a non-nil connections for each invocation
    ///
    func testRetrieveMultipleConnections() {
        let connectionFactory = BasicSubscriptionConnectionFactory(url: url,
                                                                   authType: .apiKey,
                                                                   retryStrategy: .aggressive,
                                                                   region: .USWest2,
                                                                   apiKeyProvider: MockAPIKeyAuthProvider(),
                                                                   cognitoUserPoolProvider: MockUserPoolsAuthProvider(),
                                                                   oidcAuthProvider: MockUserPoolsAuthProvider(),
                                                                   iamAuthProvider: MockIAMAuthProvider())
        let iamConnection = connectionFactory.connection(for: url,
                                                         authType: .awsIAM,
                                                         connectionType: .appSyncRealtime)
        let apiKeyConnection = connectionFactory.connection(for: url,
                                                            authType: .apiKey,
                                                            connectionType: .appSyncRealtime)
        let oidcConnection = connectionFactory.connection(for: url,
                                                          authType: .oidcToken,
                                                          connectionType: .appSyncRealtime)
        let userPoolConnection = connectionFactory.connection(for: url,
                                                              authType: .amazonCognitoUserPools,
                                                              connectionType: .appSyncRealtime)
        XCTAssertNotNil(iamConnection)
        XCTAssertNotNil(apiKeyConnection)
        XCTAssertNotNil(oidcConnection)
        XCTAssertNotNil(userPoolConnection)
    }
}
