//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
import AppSyncRealTimeClient

class OIDCBasedConnectionPool: SubscriptionConnectionPool {

    private let tokenProvider: AWSOIDCAuthProvider
    var endPointToProvider: [String: ConnectionProvider]

    init(_ tokenProvider: AWSOIDCAuthProvider) {
        self.tokenProvider = tokenProvider
        self.endPointToProvider = [:]
    }

    func connection(for url: URL, connectionType: SubscriptionConnectionType) -> SubscriptionConnection {
        if let connectionProvider = endPointToProvider[url.absoluteString] {
            return AppSyncSubscriptionConnection(provider: connectionProvider)
        }

        let authProvider = AppSyncRealTimeClientOIDCAuthProvider(authProvider: tokenProvider)
        let authInterceptor = OIDCAuthInterceptor(authProvider)
        let connectionProvider = ConnectionProviderFactory.createConnectionProvider(for: url,
                                                                                    authInterceptor: authInterceptor,
                                                                                    connectionType: connectionType)
        endPointToProvider[url.absoluteString] = connectionProvider

        return AppSyncSubscriptionConnection(provider: connectionProvider)
    }
}
