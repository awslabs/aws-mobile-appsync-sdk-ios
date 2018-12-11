//
//  SyncStrategyTests.swift
//  AWSAppSyncTests
//
//  Created by Schmelter, Tim on 12/12/18.
//  Copyright © 2018 Amazon Web Services. All rights reserved.
//

import XCTest
@testable import AWSAppSync

class SyncStrategyTests: XCTestCase {

    func test_ReturnsFullIfNoDeltaQuery() {
        let syncRefreshIntervalInSeconds = 1
        let syncStrategy = SyncStrategy(hasDeltaQuery: false, syncRefreshIntervalInSeconds: syncRefreshIntervalInSeconds)
        let syncMethodToUse = syncStrategy.methodToUseForSync
        XCTAssertEqual(syncMethodToUse, SyncMethod.full)
    }

    func test_ReturnsFullIfNotPreviouslySynced() {
        let syncRefreshIntervalInSeconds = 1
        let syncStrategy = SyncStrategy(hasDeltaQuery: false, syncRefreshIntervalInSeconds: syncRefreshIntervalInSeconds)
        let syncMethodToUse = syncStrategy.methodToUseForSync
        XCTAssertEqual(syncMethodToUse, SyncMethod.full)
    }

    func test_ReturnsFullIfLastSyncTimeIsOutsideInterval() {
        let now = Date()
        let syncRefreshIntervalInSeconds = 1
        let lastSyncTime = now.addingTimeInterval(-10)

        var syncStrategy = SyncStrategy(hasDeltaQuery: false, syncRefreshIntervalInSeconds: syncRefreshIntervalInSeconds)
        syncStrategy.lastSyncTime = lastSyncTime

        let syncMethodToUse = syncStrategy.methodToUseForSync
        XCTAssertEqual(syncMethodToUse, SyncMethod.full)
    }

    func test_ReturnsPartialIfLastSyncTimeIsInsideInterval() {
        let now = Date()
        let syncRefreshIntervalInSeconds = 10
        let lastSyncTime = now.addingTimeInterval(-5)

        var syncStrategy = SyncStrategy(hasDeltaQuery: false, syncRefreshIntervalInSeconds: syncRefreshIntervalInSeconds)
        syncStrategy.lastSyncTime = lastSyncTime

        let syncMethodToUse = syncStrategy.methodToUseForSync
        XCTAssertEqual(syncMethodToUse, SyncMethod.partial)
    }

    func test_ReturnsPartialIfLastSyncTimeIsInFuture() {
        let now = Date()
        let syncRefreshIntervalInSeconds = 1
        let lastSyncTime = now.addingTimeInterval(10)

        var syncStrategy = SyncStrategy(hasDeltaQuery: false, syncRefreshIntervalInSeconds: syncRefreshIntervalInSeconds)
        syncStrategy.lastSyncTime = lastSyncTime

        let syncMethodToUse = syncStrategy.methodToUseForSync
        XCTAssertEqual(syncMethodToUse, SyncMethod.partial)
    }

}

