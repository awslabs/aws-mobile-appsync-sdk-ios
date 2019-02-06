//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

/// The method for syncing local data with the service
enum SyncMethod {
    /// Sync data by performing a full (base) query to retrieve all data from the service
    case full

    /// Sync data by performing a partial (delta) query to retrieve only data since the last successful sync
    case partial
}

/// Logic that determines which SyncMethod to use to refresh local data for a given subscription. Tracks the last
/// sync time to compare it against the specified refresh interval.
struct SyncStrategy {
    var lastSyncTime: Date?
    let baseRefreshIntervalInSeconds: TimeInterval
    private let hasDeltaQuery: Bool

    var methodToUseForSync: SyncMethod {
        guard let lastSyncTime = lastSyncTime else {
            return .full
        }

        let timeIntervalSinceLastSync = Date().timeIntervalSince(lastSyncTime)

        if timeIntervalSinceLastSync <= baseRefreshIntervalInSeconds {
            return .partial
        } else {
            return .full
        }
    }

    init(hasDeltaQuery: Bool, baseRefreshIntervalInSeconds: Int) {
        self.hasDeltaQuery = hasDeltaQuery
        self.baseRefreshIntervalInSeconds = TimeInterval(exactly: baseRefreshIntervalInSeconds)!
    }

}

internal extension TimeInterval {
    var asDispatchTimeInterval: DispatchTimeInterval {
        return DispatchTimeInterval.seconds(Int(exactly: self)!)
    }
}
