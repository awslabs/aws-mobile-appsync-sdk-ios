//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
import AppSyncRealTimeClient

class IAMBasedConnectionPool: SubscriptionConnectionPool {

    private let credentialProvider: AWSCredentialsProvider
    private let regionType: AWSRegionType
    var endPointToProvider: [String: ConnectionProvider]

    init(_ credentialProvider: AWSCredentialsProvider, region: AWSRegionType) {
        self.credentialProvider = credentialProvider
        self.regionType = region
        self.endPointToProvider = [:]
    }

    func connection(for url: URL, connectionType: SubscriptionConnectionType) -> SubscriptionConnection {

        let connectionProvider = endPointToProvider[url.absoluteString] ??
            ConnectionProviderFactory.createConnectionProvider(for: url,
                                                               authInterceptor: IAMAuthInterceptor(credentialProvider,
                                                                                                   region: regionType),
                                                               connectionType: connectionType)

        endPointToProvider[url.absoluteString] = connectionProvider
        let connection = AppSyncSubscriptionConnection(provider: connectionProvider)
        return connection
    }
}
