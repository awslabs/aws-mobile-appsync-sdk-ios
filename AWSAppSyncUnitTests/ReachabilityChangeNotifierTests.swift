//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import XCTest
@testable import AWSAppSync
@testable import AWSAppSyncTestCommon

class ReachabilityChangeNotifierTests: XCTestCase {

    override func tearDown() {
        NetworkReachabilityNotifier.clearShared()
    }

    func testDispatchesNotification() throws {
        let reachability = MockReachabilityProvidingFactory.instance
        try reachability.startNotifier()
        reachability.connection = .unavailable

        NetworkReachabilityNotifier.setupShared(
            host: "http://www.amazon.com",
            allowsCellularAccess: true,
            reachabilityFactory: MockReachabilityProvidingFactory.self)

        let notificationReceived = expectation(description: "Reachability notification received")
        let observer = NotificationCenter.default.addObserver(forName: .appSyncReachabilityChanged, object: nil, queue: nil) { _ in
            notificationReceived.fulfill()
        }

        reachability.connection = .wifi
        wait(for: [notificationReceived], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }

    func testNotifiesSingleWatcher() throws {
        let reachability = MockReachabilityProvidingFactory.instance
        try reachability.startNotifier()
        reachability.connection = .unavailable

        NetworkReachabilityNotifier.setupShared(
            host: "http://www.amazon.com",
            allowsCellularAccess: true,
            reachabilityFactory: MockReachabilityProvidingFactory.self)

        let firstWatcherNotified = expectation(description: "First watcher was notified")
        let firstWatcher = MockNetworkReachabilityWatcher() {
            firstWatcherNotified.fulfill()
        }
        NetworkReachabilityNotifier.shared?.add(watcher: firstWatcher)

        reachability.connection = .wifi
        wait(for: [firstWatcherNotified], timeout: 1.0)
    }

    func testNotifiesMultipleWatchers() throws {
        let reachability = MockReachabilityProvidingFactory.instance
        try reachability.startNotifier()
        reachability.connection = .unavailable

        NetworkReachabilityNotifier.setupShared(
            host: "http://www.amazon.com",
            allowsCellularAccess: true,
            reachabilityFactory: MockReachabilityProvidingFactory.self)

        let firstWatcherNotified = expectation(description: "First watcher was notified")
        let firstWatcher = MockNetworkReachabilityWatcher() {
            firstWatcherNotified.fulfill()
        }
        NetworkReachabilityNotifier.shared?.add(watcher: firstWatcher)

        let secondWatcherNotified = expectation(description: "Second watcher was notified")
        let secondWatcher = MockNetworkReachabilityWatcher() {
            secondWatcherNotified.fulfill()
        }
        NetworkReachabilityNotifier.shared?.add(watcher: secondWatcher)

        reachability.connection = .wifi
        wait(for: [firstWatcherNotified, secondWatcherNotified], timeout: 1.0)
    }

    // This will fail with an overfulfillment if tearDown doesn't work as expected
    func testClearSharedRemovesWatchers() throws {
        let reachability = MockReachabilityProvidingFactory.instance
        try reachability.startNotifier()
        reachability.connection = .unavailable

        NetworkReachabilityNotifier.setupShared(
            host: "http://www.amazon.com",
            allowsCellularAccess: true,
            reachabilityFactory: MockReachabilityProvidingFactory.self)

        let firstWatcherWasNotifiedOnce = expectation(description: "First watcher was notified one time")
        let firstWatcherWasNotNotifiedTwice = expectation(description: "First watcher was not notified more than one time")
        firstWatcherWasNotNotifiedTwice.isInverted = true
        var count = 0
        let firstWatcher = MockNetworkReachabilityWatcher() {
            if count == 0 {
                firstWatcherWasNotifiedOnce.fulfill()
            } else {
                firstWatcherWasNotNotifiedTwice.fulfill()
            }
            count += 1
        }
        NetworkReachabilityNotifier.shared?.add(watcher: firstWatcher)

        reachability.connection = .wifi

        // Wait for watcher to be notified, since if clearShared works propertly, it would immediately clear the watcher queue
        // and the first watcher would never actually be invoked
        wait(for: [firstWatcherWasNotifiedOnce], timeout: 1.0)

        NetworkReachabilityNotifier.clearShared()

        reachability.connection = .cellular

        // Wait for watcher to be notified, since if clearShared works propertly, it would immediately clear the watcher queue
        // and the first watcher would never actually be invoked
        wait(for: [firstWatcherWasNotNotifiedTwice], timeout: 1.0)
    }

    func testDoesNotDispatchNotificationOnInitialConnection() throws {
        let reachability = MockReachabilityProvidingFactory.instance
        try reachability.startNotifier()

        NetworkReachabilityNotifier.setupShared(
            host: "http://www.amazon.com",
            allowsCellularAccess: true,
            reachabilityFactory: MockReachabilityProvidingFactory.self)

        let notificationNotReceived = expectation(description: "Reachability notification should not be received")
        notificationNotReceived.isInverted = true
        let observer = NotificationCenter.default.addObserver(forName: .appSyncReachabilityChanged, object: nil, queue: nil) { _ in
            notificationNotReceived.fulfill()
        }

        reachability.connection = .wifi
        wait(for: [notificationNotReceived], timeout: 0.50)
        NotificationCenter.default.removeObserver(observer)
    }

    func testDoesNotNotifyWatchersOnInitialConnection() throws {
        let reachability = MockReachabilityProvidingFactory.instance
        try reachability.startNotifier()

        NetworkReachabilityNotifier.setupShared(
            host: "http://www.amazon.com",
            allowsCellularAccess: true,
            reachabilityFactory: MockReachabilityProvidingFactory.self)

        let firstWatcherNotNotified = expectation(description: "First watcher was not notified")
        firstWatcherNotNotified.isInverted = true
        let firstWatcher = MockNetworkReachabilityWatcher() {
            firstWatcherNotNotified.fulfill()
        }
        NetworkReachabilityNotifier.shared?.add(watcher: firstWatcher)

        reachability.connection = .wifi
        wait(for: [firstWatcherNotNotified], timeout: 0.5)
    }

}

struct MockNetworkReachabilityWatcher: NetworkReachabilityWatcher {
    private let block: () -> Void

    init(block: @escaping () -> Void) {
        self.block = block
    }

    func onNetworkReachabilityChanged(isEndpointReachable: Bool) {
        block()
    }
}
