//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import XCTest
@testable import AWSAppSync
@testable import AWSAppSyncTestCommon

class IAMAuthInterceptorTests: XCTestCase {

    var authInterceptor: IAMAuthInterceptor!

    override func setUp() {
        authInterceptor = IAMAuthInterceptor(MockIAMAuthProvider(), region: .USWest2)
    }

    func testInterceptRequest() {
        let url = URL(string: "http://xxxc.appsync-api.ap-southeast-2.amazonaws.com/sd")!
        let request = AppSyncConnectionRequest(url: url)
        let signedRequest = authInterceptor.interceptConnection(request, for: url)

        guard let queries = URLComponents(url: signedRequest.url, resolvingAgainstBaseURL: true)?.queryItems else {
            assertionFailure("Query parameters should not be nil")
            return
        }
        XCTAssertTrue(queries.contains{ $0.name == "header"}, "Should contain the header query")
        XCTAssertTrue(queries.contains{ $0.name == "payload"}, "Should contain the payload query")
    }

    func testInterceptMessage() {
        let message = AppSyncMessage(type: .subscribe("start"))
        let url = URL(string: "http://xxxc.appsync-api.ap-southeast-2.amazonaws.com/sd")!
        let signedMessage = authInterceptor.interceptMessage(message, for: url)
        XCTAssertNotNil(signedMessage.payload?.authHeader)

    }
}
