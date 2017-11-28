//
//  AWSAppSyncAuthProvider.swift
//  AWSAppSync
//

import Foundation

// For using Cognito User Pools based authorization, this protocol needs to be implemented and passed to configuration object.
public protocol AWSCognitoUserPoolsAuthProvider {
    func getLatestAuthToken() -> String
}

// For using API Key based authorization, this protocol needs to be implemented and passed to configuration object.
public protocol AWSAPIKeyAuthProvider {
    func getAPIKey() -> String
}

