//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

/// The status of a SubscriptionWatcher
public enum AWSAppSyncSubscriptionWatcherStatus {
    /// The subscription is in process of connecting
    case connecting

    /// The subscription has connected and is receiving events from the service
    case connected

    /// The subscription has been disconnected because of a lifecycle event or manual disconnect request
    case disconnected

    /// The subscription is in an error state. The enum's associated value will provide more details, including recovery options if available.
    case error(AWSAppSyncSubscriptionError)
}
