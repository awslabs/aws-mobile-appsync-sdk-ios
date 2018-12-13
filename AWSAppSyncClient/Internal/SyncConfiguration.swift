//
//  SyncConfiguration.swift
//  AWSAppSync
//
//  Created by Schmelter, Tim on 12/11/18.
//  Copyright © 2018 Amazon Web Services. All rights reserved.
//

import Foundation

public class SyncConfiguration {

    internal let seconds: Int

    internal var syncIntervalInSeconds: Int {
        return seconds
    }

    public init(baseRefreshIntervalInSeconds: Int) {
        self.seconds = baseRefreshIntervalInSeconds
    }

    // utility for setting default sync to 1 day
    public class func defaultSyncConfiguration() -> SyncConfiguration {
        return SyncConfiguration(baseRefreshIntervalInSeconds: 86400)
    }
}
