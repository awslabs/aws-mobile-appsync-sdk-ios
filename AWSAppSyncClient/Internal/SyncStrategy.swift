//
// Copyright 2010-2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
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
