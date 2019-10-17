//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import XCTest
@testable import AWSAppSync
@testable import AWSAppSyncTestCommon

class AppSyncJSONHelperTests: XCTestCase {

    /// Test if we get the right base 64 value
    ///
    /// - Given: A valid auth header
    /// - When:
    ///    - I invoke the method `base64AuthenticationBlob`
    /// - Then:
    ///    - I should get a valid base64 value
    ///
    func testJSONParsing() {
        let authHeader = AuthenticationHeader(host: "http://asd.com")
        let result = AppSyncJSONHelper.base64AuthenticationBlob(authHeader)
        XCTAssertNotNil(result, "Result should not be nil")
        XCTAssertEqual(result, "eyJob3N0IjoiaHR0cDpcL1wvYXNkLmNvbSJ9", "Base 64 encoded result should match")
    }

    /// Test to check invalid json returns empty string
    ///
    /// - Given: An invalid auth header
    /// - When:
    ///    - I invoke the method `base64AuthenticationBlob`
    /// - Then:
    ///    - I should get back an empty string
    ///
    func testInValidJSONParsing() {
        let authHeader = MockInvalidHeader(host: "http://asd.com")
        let result = AppSyncJSONHelper.base64AuthenticationBlob(authHeader)
        XCTAssertNotNil(result, "Result should not be nil")
        XCTAssertEqual(result, "", "Base 64 encoded result should be empty")
    }
}


private class MockInvalidHeader: AuthenticationHeader {

    private enum CodingKeys: String, CodingKey {
        case apiKey = "x-api-key"
    }

    override func encode(to encoder: Encoder) throws {
        throw EncodingError.invalidValue("Error", EncodingError.Context(codingPath: [], debugDescription: ""))
    }
}
