//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
import AppSyncRealTimeClient
import AWSCore

class BasicSubscriptionConnectionFactory: SubscriptionConnectionFactory {

    var apiKeyBasedPool: APIKeyBasedConnectionPool?
    var userpoolsBasedPool: UserPoolsBasedConnectionPool?
    var iamBasedPool: IAMBasedConnectionPool?
    var oidcBasedPool: OIDCBasedConnectionPool?
    var lambdaBasedPool: LambdaBasedConnectionPool?

    let url: URL
    let retryStrategy: AWSAppSyncRetryStrategy
    let authType: AWSAppSyncAuthType

    init (url: URL,
          authType: AWSAppSyncAuthType,
          retryStrategy: AWSAppSyncRetryStrategy,
          region: AWSRegionType?,
          apiKeyProvider: AWSAPIKeyAuthProvider?,
          cognitoUserPoolProvider: AWSCognitoUserPoolsAuthProvider?,
          awsLambdaAuthProvider: AWSLambdaAuthProvider?,
          oidcAuthProvider: AWSOIDCAuthProvider?,
          iamAuthProvider: AWSCredentialsProvider?) {

        self.url = url
        self.authType = authType
        self.retryStrategy = retryStrategy

        if let apiKeyProvider = apiKeyProvider {
            self.apiKeyBasedPool = APIKeyBasedConnectionPool(apiKeyProvider)
        }
        if let cognitoUserPoolProvider = cognitoUserPoolProvider {
            self.userpoolsBasedPool = UserPoolsBasedConnectionPool(cognitoUserPoolProvider)
        }
        if let iamAuthProvider = iamAuthProvider, let awsRegion = region {
            self.iamBasedPool = IAMBasedConnectionPool(iamAuthProvider, region: awsRegion)
        }
        if let oidcAuthProvider = oidcAuthProvider {
            self.oidcBasedPool = OIDCBasedConnectionPool(oidcAuthProvider)
        }
        if let awsLambdaAuthProvider = awsLambdaAuthProvider {
            self.lambdaBasedPool = LambdaBasedConnectionPool(awsLambdaAuthProvider)
        }
        
    }

    func connection(connectionType: SubscriptionConnectionType) -> SubscriptionConnection? {
        let connection = connectionPool(for: authType)?.connection(for: url, connectionType: connectionType)
        if let retryableConnection = connection as? RetryableConnection {
            let retryHandler = AWSAppSyncRetryHandler(retryStrategy: retryStrategy)
            retryableConnection.addRetryHandler(handler: retryHandler)
        }
        return connection
    }

    func connection(for url: URL, authType: AWSAppSyncAuthType, connectionType: SubscriptionConnectionType) -> SubscriptionConnection? {
        return connectionPool(for: authType)?.connection(for: url, connectionType: connectionType)
    }

    // MARK: - Private Methods
    private func connectionPool(for authType: AWSAppSyncAuthType) -> SubscriptionConnectionPool? {
        switch authType {
        case .apiKey:
            return apiKeyBasedPool
        case .awsIAM:
            return iamBasedPool
        case .amazonCognitoUserPools:
            return userpoolsBasedPool
        case .oidcToken:
            return oidcBasedPool
        case .awsLambda:
            return lambdaBasedPool
        }
    }
}
