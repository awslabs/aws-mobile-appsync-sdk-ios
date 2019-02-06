//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

/// Configuration values for an AppSyncSubscriptionWithSync instance.
public struct SyncConfiguration {
    /// The interval, in whole seconds, at which the subscription will be refreshed using the `deltaQuery`. If more time has
    /// elapsed since the last sync, then local data will be refreshed using `baseQuery` instead.
    let baseRefreshIntervalInSeconds: Int

    /// Creates a new SyncConfiguration with the specified sync interval.
    ///
    /// - Parameters:
    ///   - baseRefreshIntervalInSeconds: The sync interval. Defaults to one day (86,400 seconds)
    public init(baseRefreshIntervalInSeconds: Int = 86_400) {
        self.baseRefreshIntervalInSeconds = baseRefreshIntervalInSeconds
    }
}
