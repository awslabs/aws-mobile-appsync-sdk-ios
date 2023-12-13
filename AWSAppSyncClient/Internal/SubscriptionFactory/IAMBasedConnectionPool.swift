//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
import AppSyncRealTimeClient
import AWSCore

class IAMBasedConnectionPool: SubscriptionConnectionPool {

    private let credentialProvider: AWSCredentialsProvider
    private let regionType: AWSRegionType
    var endPointToProvider: [String: ConnectionProvider]
    
    private let queue = DispatchQueue(label: "com.amazonaws.connectionPool.IAMBased.concurrentQueue",
                                      attributes: .concurrent,
                                      target: .global(qos: .userInitiated))

    init(_ credentialProvider: AWSCredentialsProvider, region: AWSRegionType) {
        self.credentialProvider = credentialProvider
        self.regionType = region
        self.endPointToProvider = [:]
    }

    func connection(for url: URL, connectionType: SubscriptionConnectionType) -> SubscriptionConnection {
        queue.sync(flags: .barrier) {
            let connectionProvider = endPointToProvider[url.absoluteString] ??
            ConnectionProviderFactory.createConnectionProvider(for: URLRequest(url: url),
                                                               authInterceptor: IAMAuthInterceptor(credentialProvider,
                                                                                                   region: regionType),
                                                               connectionType: connectionType)
            
            endPointToProvider[url.absoluteString] = connectionProvider
            let connection = AppSyncSubscriptionConnection(provider: connectionProvider)
            return connection
        }
    }
}
