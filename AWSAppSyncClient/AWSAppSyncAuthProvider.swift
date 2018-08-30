//
//  AWSAppSyncAuthProvider.swift
//  AWSAppSync
//

import Foundation

// For using OIDC based authorization, this protocol needs to be implemented and passed to configuration object.
// Use this for cases where the OIDC token needs to be fetched asynchronously and requires a callback
public protocol AWSOIDCAuthProviderAsync: AWSOIDCAuthProvider {
    func getLatestAuthToken(_ callback: @escaping (String) -> Void)
}

// For AuthProviders that use a callback, the getLatestAuthToken is defaulted to return an empty string
extension AWSOIDCAuthProviderAsync {
    public func getLatestAuthToken() -> String { return "" }
}

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

