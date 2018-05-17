//
//  AWSAppSyncAuthProvider.swift
//  AWSAppSync
//

import Foundation

// For using OIDC based authorization, this protocol needs to be implemented and passed to configuration object.
public protocol AWSOIDCAuthProvider {
    /// The method should fetch the token and return it to the client for using in header request.
    func getLatestAuthToken() -> String
}

// For using Cognito User Pools based authorization, this protocol needs to be implemented and passed to configuration object.
public protocol AWSCognitoUserPoolsAuthProvider: AWSOIDCAuthProvider {
    
}

// For using API Key based authorization, this protocol needs to be implemented and passed to configuration object.
public protocol AWSAPIKeyAuthProvider {
    func getAPIKey() -> String
}

