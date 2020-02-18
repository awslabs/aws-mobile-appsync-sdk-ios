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
    let url2 = URL(string: "http://appsyncendpoint-2.com/graphql")!

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
        let interceptor = connectionFactory.authTypeToInterceptor[.awsIAM]
        let connection = connectionFactory.connection(for: url,
                                                      authType: .awsIAM,
                                                      connectionType: .appSyncRealtime)
        let provider = connectionFactory.endPointToProvider[url.absoluteString]
        XCTAssertNotNil(provider)
        XCTAssertNotNil(interceptor)
        XCTAssertNotNil(connection)
        XCTAssertEqual(connectionFactory.endPointToProvider.count, 1)

        let connection2 = connectionFactory.connection(for: url2, authType: .awsIAM, connectionType: .appSyncRealtime)
        let provider2 = connectionFactory.endPointToProvider[url2.absoluteString]
        XCTAssertNotNil(connection2)
        XCTAssertNotNil(provider2)
        XCTAssertEqual(connectionFactory.endPointToProvider.count, 2)
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
                                                                   authType: .amazonCognitoUserPools,
                                                                   retryStrategy: .aggressive,
                                                                   region: .USWest2,
                                                                   apiKeyProvider: nil,
                                                                   cognitoUserPoolProvider: MockUserPoolsAuthProvider(),
                                                                   oidcAuthProvider: nil,
                                                                   iamAuthProvider: nil)
        let interceptor = connectionFactory.authTypeToInterceptor[.amazonCognitoUserPools]
        let connection = connectionFactory.connection(for: url,
                                                      authType: .amazonCognitoUserPools,
                                                      connectionType: .appSyncRealtime)
        let provider = connectionFactory.endPointToProvider[url.absoluteString]
        XCTAssertNotNil(provider)
        XCTAssertNotNil(interceptor)
        XCTAssertNotNil(connection)
        XCTAssertEqual(connectionFactory.endPointToProvider.count, 1)

        let connection2 = connectionFactory.connection(for: url2, authType: .amazonCognitoUserPools, connectionType: .appSyncRealtime)
        let provider2 = connectionFactory.endPointToProvider[url2.absoluteString]
        XCTAssertNotNil(connection2)
        XCTAssertNotNil(provider2)
        XCTAssertEqual(connectionFactory.endPointToProvider.count, 2)
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
                                                                   region: nil,
                                                                   apiKeyProvider: MockAPIKeyAuthProvider(),
                                                                   cognitoUserPoolProvider: nil,
                                                                   oidcAuthProvider: nil,
                                                                   iamAuthProvider: nil)
        let interceptor = connectionFactory.authTypeToInterceptor[.apiKey]
        let connection = connectionFactory.connection(for: url,
                                                      authType: .apiKey,
                                                      connectionType: .appSyncRealtime)
        let provider = connectionFactory.endPointToProvider[url.absoluteString]
        XCTAssertNotNil(provider)
        XCTAssertNotNil(interceptor)
        XCTAssertNotNil(connection)
        XCTAssertEqual(connectionFactory.endPointToProvider.count, 1)

        let connection2 = connectionFactory.connection(for: url2, authType: .apiKey, connectionType: .appSyncRealtime)
        let provider2 = connectionFactory.endPointToProvider[url2.absoluteString]
        XCTAssertNotNil(connection2)
        XCTAssertNotNil(provider2)
        XCTAssertEqual(connectionFactory.endPointToProvider.count, 2)
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
                                                                   authType: .oidcToken,
                                                                   retryStrategy: .aggressive,
                                                                   region: nil,
                                                                   apiKeyProvider: nil,
                                                                   cognitoUserPoolProvider: nil,
                                                                   oidcAuthProvider: MockUserPoolsAuthProvider(),
                                                                   iamAuthProvider: nil)
        let interceptor = connectionFactory.authTypeToInterceptor[.oidcToken]
        let connection = connectionFactory.connection(for: url,
                                                      authType: .oidcToken,
                                                      connectionType: .appSyncRealtime)
        let provider = connectionFactory.endPointToProvider[url.absoluteString]
        XCTAssertNotNil(provider)
        XCTAssertNotNil(interceptor)
        XCTAssertNotNil(connection)
        XCTAssertEqual(connectionFactory.endPointToProvider.count, 1)

        let connection2 = connectionFactory.connection(for: url2, authType: .oidcToken, connectionType: .appSyncRealtime)
        let provider2 = connectionFactory.endPointToProvider[url2.absoluteString]
        XCTAssertNotNil(connection2)
        XCTAssertNotNil(provider2)
        XCTAssertEqual(connectionFactory.endPointToProvider.count, 2)
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

        XCTAssertEqual(connectionFactory.endPointToProvider.count, 1)
        XCTAssertEqual(connectionFactory.authTypeToInterceptor.count, 4)
    }
}
