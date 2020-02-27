//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
import AppSyncRealTimeClient

/// Protocol for the subscription factory
protocol SubscriptionConnectionFactory {

    /// Get connection based on the connection type
    /// - Parameter connectionType: 
    func connection(connectionType: SubscriptionConnectionType) -> SubscriptionConnection?
}

/// Protocol for the different connection pool
protocol SubscriptionConnectionPool {

    /// Get Connection based on the url and connection type
    /// - Parameter url: url to connect to
    /// - Parameter connectionType:
    func connection(for url: URL, connectionType: SubscriptionConnectionType) -> SubscriptionConnection
}
