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
