//
// Copyright 2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

import Foundation
import XCTest
@testable import AWSAppSync
@testable import AWSCore
@testable import AWSAppSyncTestCommon

// These tests validate authentication using OIDC, API Key, and Cognito User Pools.
// For both OIDC and Cognito User pools, tokens can be fetched either synchronously
// or via a callback.

class AuthProviderTestError: Error {}

class AuthProviderTests: XCTestCase {
    static let testBundle = Bundle(for: AuthProviderTests.self)

    class OIDCAuthProviderAsync: AWSOIDCAuthProviderAsync {
        var expectation: XCTestExpectation?
        var forceError: Bool = false
        init(_ expectation: XCTestExpectation, forceError: Bool = false){
            self.expectation = expectation;
            self.forceError = forceError
        }
        
        public func getLatestAuthToken() -> String {
            expectation?.fulfill()
            return "OIDCAuthProviderAsync"
        }

        func getLatestAuthToken(_ callback: @escaping (String?, Error?) -> Void) {
            if forceError {
                callback(nil, AuthProviderTestError())
            }
            else {
                callback("OIDCAuthProviderAsync", nil)
            }
            self.expectation?.fulfill()
        }
    }
    
    class OIDCAuthProvider: AWSOIDCAuthProvider {
        var expectation: XCTestExpectation?
        init(_ expectation: XCTestExpectation){
            self.expectation = expectation;
        }
        func getLatestAuthToken() -> String {
            self.expectation?.fulfill()
            return "OIDCAuthProvider"
        }
    }
    
    class CognitoUserPoolsAuthProviderAsync: AWSCognitoUserPoolsAuthProviderAsync {
        var expectation: XCTestExpectation?
        init(_ expectation: XCTestExpectation){
            self.expectation = expectation;
        }

        public func getLatestAuthToken() -> String {
            expectation?.fulfill()
            return "CognitoUserPoolsAuthProviderAsync"
        }

        func getLatestAuthToken(_ callback: @escaping (String?, Error?) -> Void) {
            callback("CognitoUserPoolsAuthProviderAsync", nil)
            expectation?.fulfill()
        }
    }

    class CognitoUserPoolsAuthProvider: AWSCognitoUserPoolsAuthProvider {
        var expectation: XCTestExpectation?
        init(_ expectation: XCTestExpectation){
            self.expectation = expectation;
        }
        func getLatestAuthToken() -> String {
            self.expectation?.fulfill()
            return "PoolProvider"
        }
    }

    class ApiKeyProvider: AWSAPIKeyAuthProvider {
        var expectation: XCTestExpectation?
        var isExpectaionFulfilled: Bool = false
        init(_ expectation: XCTestExpectation){
            self.expectation = expectation;
        }
        func getAPIKey() -> String {
            if (!isExpectaionFulfilled) {
                self.expectation?.fulfill()
                isExpectaionFulfilled = true
            }
            return "AuthTokenTests"
        }
    }
    
    func testCanAuthenticateWithApiKey(){
        
        let expectation = self.expectation(description: "token retrieved")
       
        // The test validates that an auth token is retrieved prior to sending the request, so
        // its ok if the URL is invalid.
        let url = URL(string: "https://localhost")!
        
        let config = try? AWSAppSyncClientConfiguration(url: url,
                                                        serviceRegion: .USEast1,
                                                        apiKeyAuthProvider: ApiKeyProvider(expectation))
        
        let client = try! AWSAppSyncClient(appSyncConfig: config!)
        let mutation = CreatePostWithoutFileUsingParametersMutation(
            author: "Test author",
            title: "Test title",
            content: "Test content"
        )
        
        client.perform(mutation: mutation)
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCanAuthenticateWithOIDCToken(){
        
        let expectation = self.expectation(description: "token retrieved")
        
        // The test validates that an auth token is retrieved prior to sending the request, so
        // its ok if the URL is invalid.
        let url = URL(string: "https://localhost")!
        
        let config = try? AWSAppSyncClientConfiguration(url: url,
                                                       serviceRegion: .USEast1,
                                                       oidcAuthProvider: OIDCAuthProvider(expectation))

        
        let client = try! AWSAppSyncClient(appSyncConfig: config!)
        let mutation = CreatePostWithoutFileUsingParametersMutation(
            author: "Test author",
            title: "Test title",
            content: "Test content"
        )

        client.perform(mutation: mutation)
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCanHandleAsyncTokenErrors(){
        let expectation1 = self.expectation(description: "token retrieved")
        let expectation2 = self.expectation(description: "callback complete")
        let erroringProvider = OIDCAuthProviderAsync(expectation1, forceError: true)
        
        // The test validates that an auth token is retrieved prior to sending the request, so
        // its ok if the URL is invalid.
        let url = URL(string: "https://localhost")!
        
        let config = try? AWSAppSyncClientConfiguration(url: url,
                                                        serviceRegion: .USEast1,
                                                        oidcAuthProvider: erroringProvider)
        
        let client = try! AWSAppSyncClient(appSyncConfig: config!)
        let mutation = CreatePostWithoutFileUsingParametersMutation(
            author: "Test author",
            title: "Test title",
            content: "Test content"
        )

        client.perform(mutation: mutation, resultHandler: { (_, error) in
            XCTAssert(error != nil)
            if case AWSAppSyncClientError.authenticationError(let authError) = error as! AWSAppSyncClientError {
                XCTAssert(authError is AuthProviderTestError)
            } else {
                XCTAssertTrue(false, "Error of unexpected type")
            }
            expectation2.fulfill()
        })
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCanAuthenticateWithOIDCTokenAsync(){
        
        let expectation = self.expectation(description: "token retrieved")
        
        // The test validates that an auth token is retrieved prior to sending the request, so
        // its ok if the URL is invalid.
        let url = URL(string: "https://localhost")!
        
        let config = try? AWSAppSyncClientConfiguration(url: url,
                                                        serviceRegion: .USEast1,
                                                        oidcAuthProvider: OIDCAuthProviderAsync(expectation))
        
        
        
        let client = try! AWSAppSyncClient(appSyncConfig: config!)
        let mutation = CreatePostWithoutFileUsingParametersMutation(
            author: "Test author",
            title: "Test title",
            content: "Test content"
        )

        client.perform(mutation: mutation)
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCanAuthenticateWithCognitoUserPool(){
        
        let expectation = self.expectation(description: "token retrieved")
        
        // The test validates that an auth token is retrieved prior to sending the request, so
        // its ok if the URL is invalid.
        let url = URL(string: "https://localhost")!
        
        let config = try? AWSAppSyncClientConfiguration(url: url,
                                                        serviceRegion: .USEast1,
                                                        userPoolsAuthProvider: CognitoUserPoolsAuthProvider(expectation))
        
        
        
        let client = try! AWSAppSyncClient(appSyncConfig: config!)
        let mutation = CreatePostWithoutFileUsingParametersMutation(
            author: "Test author",
            title: "Test title",
            content: "Test content"
        )

        client.perform(mutation: mutation)
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCanAuthenticateWithCognitoUserPoolAsync(){
        
        let expectation = self.expectation(description: "token retrieved")
        
        // The test validates that an auth token is retrieved prior to sending the request, so
        // its ok if the URL is invalid.
        let url = URL(string: "https://localhost")!
        
        let config = try? AWSAppSyncClientConfiguration(url: url,
                                                        serviceRegion: .USEast1,
                                                        userPoolsAuthProvider: CognitoUserPoolsAuthProviderAsync(expectation))
        
        
        
        let client = try! AWSAppSyncClient(appSyncConfig: config!)
        let mutation = CreatePostWithoutFileUsingParametersMutation(
            author: "Test author",
            title: "Test title",
            content: "Test content"
        )

        client.perform(mutation: mutation)
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }

    func testAppSynClientConfigurationApiKeyAuthProvider() throws {
        let appSyncClient = try AppSyncClientTestHelper(
            with: .apiKey,
            testBundle: AuthProviderTests.testBundle).appSyncClient
        XCTAssertNotNil(appSyncClient, "AppSyncClient should not be nil when initialized using API Key auth type")
    }

    func testAppSynClientConfigurationOidcAuthProvider() throws {
        let appSyncClient = try AppSyncClientTestHelper(
            with: .invalidOIDC,
            testBundle: AuthProviderTests.testBundle).appSyncClient
        XCTAssertNotNil(appSyncClient, "AppSyncClient should not be nil when initialized using OIDC auth type")
    }

    func testInvalidAPIKeyAuth() throws {
        let badlyConfiguredAppSyncClient = try AppSyncClientTestHelper(
            with: .invalidAPIKey,
            testBundle: AuthProviderTests.testBundle).appSyncClient
        XCTAssertNotNil(badlyConfiguredAppSyncClient, "AppSyncClient cannot be nil")
        assertConnectGeneratesAuthError(with: badlyConfiguredAppSyncClient)
    }

    func testInvalidOIDCProvider() throws {
        let badlyConfiguredAppSyncClient = try AppSyncClientTestHelper(
            with: .invalidOIDC,
            testBundle: AuthProviderTests.testBundle).appSyncClient
        XCTAssertNotNil(badlyConfiguredAppSyncClient, "AppSyncClient cannot be nil")
        assertConnectGeneratesAuthError(with: badlyConfiguredAppSyncClient)
    }

    func testInvalidCredentials() throws {
        let badlyConfiguredAppSyncClient = try AppSyncClientTestHelper(
            with: .invalidStaticCredentials,
            testBundle: AuthProviderTests.testBundle).appSyncClient
        XCTAssertNotNil(badlyConfiguredAppSyncClient, "AppSyncClient cannot be nil")
        assertConnectGeneratesAuthError(with: badlyConfiguredAppSyncClient)
    }

    // MARK: - Utilities

    // Asserts that the AWSAppSyncClient can connect to the server, thus validating URL and authentication
    func assertCanConnectSuccessfully(with client: AWSAppSyncClient, file: StaticString = #file, line: UInt = #line) {
        let result = simpleFetch(with: client)
        switch result {
        case .failure(let error):
            XCTFail("Failed to connect successfully: \(error.localizedDescription)", file: file, line: line)
        case .success(_):
            break
        }
    }

    func assertConnectGeneratesAuthError(with client: AWSAppSyncClient, file: StaticString = #file,line: UInt = #line) {
        let result = simpleFetch(with: client)

        guard case .failure(let error) = result else {
            XCTFail("Connect successfully but expected auth error", file: file, line: line)
            return
        }

        guard let appSyncError = error as? AWSAppSyncClientError else {
            XCTFail("Received unexpected error type during fetch: \(error.localizedDescription)", file: file, line: line)
            return
        }

        // Can't use enum pattern matching in the XCTAssert macros, so we'll have a bogus "XCTAssertTrue"
        if case .authenticationError = appSyncError {
            XCTAssertTrue(true, "Received authentication error as expected")
        } else if case .requestFailed(_, let response, _) = appSyncError {
            XCTAssertTrue(response?.statusCode == 401 || response?.statusCode == 403, "Expected invalid error code to be either 401 or 403, got \(String(describing: response?.statusCode))")
        } else {
            XCTFail("Received something other than authentication error during fetch: \(error.localizedDescription)", file: file, line: line)
        }
    }

    func simpleFetch(with client: AWSAppSyncClient) -> Result<Void> {
        let queryDidComplete = expectation(description: "ListEventsQuery did complete")
        let query = ListPostsQuery()

        var fetchResult: Result<Void> = .failure("Fetch didn't complete before timeout")

        client.fetch(query: query) { result, error in
            if let error = error {
                fetchResult = .failure(error)
            } else if result == nil {
                fetchResult = .failure("The result was nil")
            } else {
                fetchResult = .success(())
            }

            queryDidComplete.fulfill()
        }

        wait(for: [queryDidComplete], timeout: 5.0)

        return fetchResult
    }

}
