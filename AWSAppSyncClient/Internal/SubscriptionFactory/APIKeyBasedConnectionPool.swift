//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
import AppSyncRealTimeClient

class APIKeyBasedConnectionPool: SubscriptionConnectionPool {

    private let apiKeyProvider: AWSAPIKeyAuthProvider
    var endPointToProvider: [String: ConnectionProvider]

    private let queue = DispatchQueue(
        label: "com.amazonaws.connectionPool.APIKeyBased.concurrentQueue",
        attributes: .concurrent,
        target: .global(
            qos: .userInitiated
        )
    )

    init(_ apiKeyProvider: AWSAPIKeyAuthProvider) {
        self.apiKeyProvider = apiKeyProvider
        self.endPointToProvider = [:]
    }

    func connection(for url: URL, connectionType: SubscriptionConnectionType) -> SubscriptionConnection {
        queue.sync(flags: .barrier) {
            let connectionProvider = endPointToProvider[url.absoluteString] ??
                ConnectionProviderFactory.createConnectionProvider(for: URLRequest(url: url),
                                                                   authInterceptor: APIKeyAuthInterceptor(apiKeyProvider.getAPIKey()),
                                                                   connectionType: connectionType)
            endPointToProvider[url.absoluteString] = connectionProvider
            let connection = AppSyncSubscriptionConnection(provider: connectionProvider)
            return connection
        }
    }
}
