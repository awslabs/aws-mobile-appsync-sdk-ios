//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

class BasicSubscriptionConnectionFactory: SubscriptionConnectionFactory {

    var endPointToProvider: [String: ConnectionProvider] = [:]
    var authInterceptor: AuthInterceptor?

    let url: URL
    let retryStrategy: AWSAppSyncRetryStrategy
    let authType: AWSAppSyncAuthType

    init (url: URL,
          authType: AWSAppSyncAuthType,
          retryStrategy: AWSAppSyncRetryStrategy,
          region: AWSRegionType?,
          apiKeyProvider: AWSAPIKeyAuthProvider?,
          cognitoUserPoolProvider: AWSCognitoUserPoolsAuthProvider?,
          oidcAuthProvider: AWSOIDCAuthProvider?,
          iamAuthProvider: AWSCredentialsProvider?) {

        self.url = url
        self.authType = authType
        self.retryStrategy = retryStrategy

        if let apiKeyProvider = apiKeyProvider {
            self.authInterceptor = APIKeyAuthInterceptor(apiKeyProvider)
        }
        if let cognitoUserPoolProvider = cognitoUserPoolProvider {
            self.authInterceptor = CognitoUserPoolsAuthInterceptor(cognitoUserPoolProvider)
        }
        if let iamAuthProvider = iamAuthProvider, let awsRegion = region {
            self.authInterceptor = IAMAuthInterceptor(iamAuthProvider, region: awsRegion)
        }
        if let oidcAuthProvider = oidcAuthProvider {
            self.authInterceptor = CognitoUserPoolsAuthInterceptor(oidcAuthProvider)
        }
    }

    func connection(connectionType: SubscriptionConnectionType) -> SubscriptionConnection? {
        guard let authInterceptor = self.authInterceptor else {
            return nil
        }

        let connectionProvider = endPointToProvider[url.absoluteString] ??
            createConnectionProvider(for: url, authInterceptor: authInterceptor, connectionType: connectionType)
        endPointToProvider[url.absoluteString] = connectionProvider
        let connection = AppSyncSubscriptionConnection(provider: connectionProvider)

        let retryHandler = AWSAppSyncRetryHandler(retryStrategy: retryStrategy)
        connection.addRetryHandler(handler: retryHandler)

        return connection
    }

    func connection(for url: URL, authType: AWSAppSyncAuthType, connectionType: SubscriptionConnectionType) -> SubscriptionConnection? {
        guard let authInterceptor = self.authInterceptor else {
            return nil
        }
        let connectionProvider = endPointToProvider[url.absoluteString] ??
            createConnectionProvider(for: url, authInterceptor: authInterceptor, connectionType: connectionType)
        endPointToProvider[url.absoluteString] = connectionProvider
        return AppSyncSubscriptionConnection(provider: connectionProvider)
    }

    // MARK: - Private Methods

    private func createConnectionProvider(for url: URL, authInterceptor: AuthInterceptor, connectionType: SubscriptionConnectionType) -> ConnectionProvider {

        let provider = createConnectionProvider(for: url, connectionType: connectionType)

        if let messageInterceptable = provider as? MessageInterceptable {
            messageInterceptable.addInterceptor(authInterceptor)
        }
        if let connectionInterceptable = provider as? ConnectionInterceptable {
            connectionInterceptable.addInterceptor(RealtimeGatewayURLInterceptor())
            connectionInterceptable.addInterceptor(authInterceptor)
        }

        return provider
    }

    private func createConnectionProvider(for url: URL, connectionType: SubscriptionConnectionType) -> ConnectionProvider {
        switch connectionType {
        case .appSyncRealtime:
            let websocketProvider = StarscreamAdapter()
            let connectionProvider = RealtimeConnectionProvider(for: url, websocket: websocketProvider)
            return connectionProvider
        }
    }
}
