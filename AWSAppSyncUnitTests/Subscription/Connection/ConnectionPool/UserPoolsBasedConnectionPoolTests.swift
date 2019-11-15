//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import XCTest
@testable import AWSAppSync
@testable import AWSAppSyncTestCommon

class UserPoolsBasedConnectionPoolTests: XCTestCase {

    var connectionPool: UserPoolsBasedConnectionPool!

    let url = URL(string: "http://appsyncendpoint.com/graphql")!
    let url2 = URL(string: "http://appsyncendpoint-2.com/graphql")!

    override func setUp() {
       connectionPool = UserPoolsBasedConnectionPool(MockUserPoolsAuthProvider())
    }

    /// Test retrieve connection
    ///
    /// - Given: A connection pool
    /// - When:
    ///    - I call connection(for:connectionType:)
    /// - Then:
    ///    - I should get a non-nil connection
    ///
    func testRetrieveConnection() {
        let connection = connectionPool.connection(for: url, connectionType: .appSyncRealtime)
        XCTAssertNotNil(connection)
    }

    /// Test retrieving multiple connection using the same url
    ///
    /// - Given: A connection pool
    /// - When:
    ///    - I try to retrieve multiple connection with same url
    /// - Then:
    ///    - I should get non-nil connections for each request. And the internal count of provider should be 1.
    ///
    func testRetreiveMultipleConnectionSameUrl() {
        let connection1 = connectionPool.connection(for: url, connectionType: .appSyncRealtime)
        XCTAssertNotNil(connection1)
        XCTAssertEqual(connectionPool.endPointToProvider.count, 1, "Only one connection provider should be created")
        let provider1 = connectionPool.endPointToProvider[url.absoluteString]

        let connection2 = connectionPool.connection(for: url, connectionType: .appSyncRealtime)
        XCTAssertNotNil(connection2)
        XCTAssertEqual(connectionPool.endPointToProvider.count, 1, "Only one connection provider should be created")
        let provider2 = connectionPool.endPointToProvider[url.absoluteString]
        XCTAssertTrue(provider1 === provider2, "Internal connection provider should be same")
    }

    /// Test retrieving multiple connection using the different url
    ///
    /// - Given: A connection pool
    /// - When:
    ///    - I try to retrieve multiple connection with 2 different urls
    /// - Then:
    ///    - I should get non-nil connections for each request. And the internal count of provider should be 2.
    ///
    func testRetreiveMultipleConnectionDifferentUrl() {
        let connection1 = connectionPool.connection(for: url, connectionType: .appSyncRealtime)
        XCTAssertNotNil(connection1)
        XCTAssertEqual(connectionPool.endPointToProvider.count, 1, "Only one connection provider should be created")
        let provider1 = connectionPool.endPointToProvider[url.absoluteString]

        let connection2 = connectionPool.connection(for: url2, connectionType: .appSyncRealtime)
        XCTAssertNotNil(connection2)
        XCTAssertEqual(connectionPool.endPointToProvider.count, 2, "Second connection provider should be created")
        let provider2 = connectionPool.endPointToProvider[url2.absoluteString]
        XCTAssertFalse(provider1 === provider2, "Internal connection provider should not be same")
    }
}
