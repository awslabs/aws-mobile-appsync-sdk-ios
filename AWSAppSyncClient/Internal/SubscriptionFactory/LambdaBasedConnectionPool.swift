//
// Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
import AppSyncRealTimeClient

class LambdaBasedConnectionPool: SubscriptionConnectionPool {

    private let tokenProvider: AWSLambdaAuthProvider
    var endPointToProvider: [String: ConnectionProvider]

    init(_ tokenProvider: AWSLambdaAuthProvider) {
        self.tokenProvider = tokenProvider
        self.endPointToProvider = [:]
    }

    func connection(for url: URL, connectionType: SubscriptionConnectionType) -> SubscriptionConnection {
        if let connectionProvider = endPointToProvider[url.absoluteString] {
            return AppSyncSubscriptionConnection(provider: connectionProvider)
        }

        let authInterceptor = LambdaAuthInterceptor(authTokenProvider: tokenProvider)
        let connectionProvider = ConnectionProviderFactory.createConnectionProvider(for: url,
                                                                                    authInterceptor: authInterceptor,
                                                                                    connectionType: connectionType)
        endPointToProvider[url.absoluteString] = connectionProvider

        return AppSyncSubscriptionConnection(provider: connectionProvider)
    }
}
