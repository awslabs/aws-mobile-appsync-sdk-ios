//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
import AppSyncSubscriptionClient

/// Protocol for the subscription factory
protocol SubscriptionConnectionFactory {

    /// Get connection based on the connection type
    /// - Parameter connectionType: 
    func connection(connectionType: SubscriptionConnectionType) -> SubscriptionConnection?
}
