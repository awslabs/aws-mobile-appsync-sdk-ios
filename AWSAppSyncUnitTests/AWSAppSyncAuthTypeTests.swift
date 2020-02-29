//
// Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import XCTest
import AWSAppSync

class AWSAppSyncAuthTypeTests: XCTestCase {
    
    // MARK: - Utility: Test Harnesses
    
    /// Perform a expectant success Decodable test.
    /// - Parameters:
    ///   - inputString: String to be input and decoded into a `AWSAppSyncAuthType`.
    ///   - expectedOutput: The expected `AWSAppSyncAuthType` output.
    func performSuccessDecodableTest(
        inputString: String,
        expectedOutput: AWSAppSyncAuthType,
        file: StaticString = #file,
        line: UInt = #line) throws {
        let inputData = try JSONSerialization.data(withJSONObject: inputString, options: .fragmentsAllowed)
        let decoded = try JSONDecoder().decode(AWSAppSyncAuthType.self, from: inputData)
        XCTAssertEqual(decoded, expectedOutput)
    }
    
    /// Perform a expectant success Encodable test.
    /// - Parameters:
    ///   - inputType: The `AWSAppSyncAuthType` that is input and attempted to be encoded.
    ///   - expectedString: The expected raw output string of the encoded `inputType`.
    func performSuccessEncodableTest(
        inputType: AWSAppSyncAuthType,
        expectedString: String,
        file: StaticString = #file,
        line: UInt = #line) throws {
        let data = try JSONEncoder().encode(inputType)
        guard let string = String(data: data, encoding: .utf8) else {
            return XCTFail("Failed to decode string", file: file, line: line)
        }
        // Encoder wraps output with double quotes, so this matches that.
        XCTAssertEqual(string, "\"\(expectedString)\"", file: file, line: line)
    }
    
    // MARK: - Tests: Decodable

    func test_SuccessfulDecodable_AwsIAM() throws {
        try performSuccessDecodableTest(inputString: "AWS_IAM", expectedOutput: .awsIAM)
    }
    
    func test_SuccessfulDecodable_ApiKey() throws {
        try performSuccessDecodableTest(inputString: "API_KEY", expectedOutput: .apiKey)
    }
    
    func test_SuccessfulDecodable_OidcToken() throws {
        try performSuccessDecodableTest(inputString: "OPENID_CONNECT", expectedOutput: .oidcToken)
    }
    
    func test_SuccessfulDecodable_AmazonCognitoUserPools() throws {
        try performSuccessDecodableTest(inputString: "AMAZON_COGNITO_USER_POOLS", expectedOutput: .amazonCognitoUserPools)
    }
    
    func test_FailureDecodable_BadData() throws {
        let inputData = try JSONSerialization.data(withJSONObject: "INVALID_DATA", options: .fragmentsAllowed)
        XCTAssertThrowsError(try JSONDecoder().decode(AWSAppSyncAuthType.self, from: inputData))
    }
    
    // MARK: - Tests: Encodable
    
    func test_SuccessfulEncodable_AwsIAM() throws {
        try performSuccessEncodableTest(inputType: .awsIAM, expectedString: "AWS_IAM")
    }
    
    func test_SuccessfulEncodable_ApiKey() throws {
        try performSuccessEncodableTest(inputType: .apiKey, expectedString: "API_KEY")
    }
    
    func test_SuccessfulEncodable_OidcToken() throws {
        try performSuccessEncodableTest(inputType: .oidcToken, expectedString: "OPENID_CONNECT")
    }
    
    func test_SuccessfulEncodable_AmazonCognitoUserPools() throws {
        try performSuccessEncodableTest(inputType: .amazonCognitoUserPools, expectedString: "AMAZON_COGNITO_USER_POOLS")
    }
    
    // MARK: - Tests: Hashable
    
    func test_Hashable_AwsIAM() {
        let awsIAM = AWSAppSyncAuthType.awsIAM
        XCTAssertEqual(awsIAM, .awsIAM)
        XCTAssertNotEqual(awsIAM, .apiKey)
        XCTAssertNotEqual(awsIAM, .oidcToken)
        XCTAssertNotEqual(awsIAM, .amazonCognitoUserPools)
    }
    
    func test_Hashable_ApiKey() {
        let apiKey = AWSAppSyncAuthType.apiKey
        XCTAssertEqual(apiKey.hashValue, AWSAppSyncAuthType.apiKey.hashValue)
        XCTAssertNotEqual(apiKey.hashValue, AWSAppSyncAuthType.awsIAM.hashValue)
        XCTAssertNotEqual(apiKey.hashValue, AWSAppSyncAuthType.oidcToken.hashValue)
        XCTAssertNotEqual(apiKey.hashValue, AWSAppSyncAuthType.amazonCognitoUserPools.hashValue)
    }
    
    func test_Hashable_OidcToken() {
        let oidcToken = AWSAppSyncAuthType.oidcToken
        XCTAssertEqual(oidcToken.hashValue, AWSAppSyncAuthType.oidcToken.hashValue)
        XCTAssertNotEqual(oidcToken.hashValue, AWSAppSyncAuthType.awsIAM.hashValue)
        XCTAssertNotEqual(oidcToken.hashValue, AWSAppSyncAuthType.apiKey.hashValue)
        XCTAssertNotEqual(oidcToken.hashValue, AWSAppSyncAuthType.amazonCognitoUserPools.hashValue)
    }
    
    func test_Hashable_AmazonCognitoUserPools() {
        let amazonCognitoUserPools = AWSAppSyncAuthType.amazonCognitoUserPools
        XCTAssertEqual(amazonCognitoUserPools.hashValue, AWSAppSyncAuthType.amazonCognitoUserPools.hashValue)
        XCTAssertNotEqual(amazonCognitoUserPools.hashValue, AWSAppSyncAuthType.awsIAM.hashValue)
        XCTAssertNotEqual(amazonCognitoUserPools.hashValue, AWSAppSyncAuthType.apiKey.hashValue)
        XCTAssertNotEqual(amazonCognitoUserPools.hashValue, AWSAppSyncAuthType.oidcToken.hashValue)
    }

}
