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

/// Configuration values for an AppSyncSubscriptionWithSync instance.
@available(*, deprecated, renamed: "SubscriptionWithSyncConfiguration", message: "Use SubscriptionWithSyncConfiguration")
public final class SyncConfiguration {

    internal let seconds: Int

    internal var syncIntervalInSeconds: Int {
        return seconds
    }

    public init(baseRefreshIntervalInSeconds: Int) {
        self.seconds = baseRefreshIntervalInSeconds
    }

    /// Returns a default configuration with `syncIntervalInSeconds` set to one day.
    ///
    /// - Deprecated: Use `SyncConfiguration.default` instead
    /// - Returns: A default `SyncConfiguration` instance
    public class func defaultSyncConfiguration() -> SyncConfiguration {
        return SyncConfiguration(baseRefreshIntervalInSeconds: 86_400)
    }
}
