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

// These tests validate authentication using OIDC, API Key, and Cognito User Pools.
// For both OIDC and Cognito User pools, tokens can be fetched either synchronously
// or via a callback.

class AuthProviderTestError: Error {}

class AuthProviderTests: XCTestCase {

    class OIDCAuthProviderAsync: AWSOIDCAuthProviderAsync {
        var expectation: XCTestExpectation?
        var forceError: Bool = false
        init(_ expectation: XCTestExpectation, forceError: Bool = false){
            self.expectation = expectation;
            self.forceError = forceError
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
        
        func getLatestAuthToken(_ callback: @escaping (String?, Error?) -> Void) {
            callback("CognitoUserPoolsAuthProviderAsync", nil)
            self.expectation?.fulfill()
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
        let mutation = AddEventMutation(name: "test", when: "test", where: "test", description: "test")
        
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
        let mutation = AddEventMutation(name: "test", when: "test", where: "test", description: "test")
        
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
        let mutation = AddEventMutation(name: "test", when: "test", where: "test", description: "test")
        
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
        let mutation = AddEventMutation(name: "test", when: "test", where: "test", description: "test")
        
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
        let mutation = AddEventMutation(name: "test", when: "test", where: "test", description: "test")
        
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
        let mutation = AddEventMutation(name: "test", when: "test", where: "test", description: "test")
        
        client.perform(mutation: mutation)
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
}
