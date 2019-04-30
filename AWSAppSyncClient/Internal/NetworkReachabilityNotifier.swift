//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
import Reachability

internal extension Notification.Name {
    static let appSyncReachabilityChanged = Notification.Name("AppSyncNetworkAvailabilityChangedNotification")
}

protocol NetworkReachabilityWatcher {
    func onNetworkReachabilityChanged(isEndpointReachable: Bool)
}

class NetworkReachabilityNotifier {
    private(set) static var shared: NetworkReachabilityNotifier?

    // Network status monitoring
    private var reachability: NetworkReachabilityProviding?
    private var allowsCellularAccess = true
    private var isInitialConnection = true

    /// A list of watchers to be notified when the network status changes
    private var networkReachabilityWatchers: [NetworkReachabilityWatcher] = []

    /// Sets up the shared `NetworkReachabilityNotifier` instance for the specified host and access rules.
    ///
    /// - Parameters:
    ///   - host: The AppSync endpoint URL
    ///   - allowsCellularAccess: If `true`, the host is considered reachable if it is accessible via cellular (WAN) connection
    ///     _or_ WiFi. If `false`, the host is only reachable if it is accessible via WiFi.
    ///   - reachabilityFactory: An optional factory for making ReachabilityProviding instances. Defaults to `Reachability.self`
    static func setupShared(host: String,
                            allowsCellularAccess: Bool,
                            reachabilityFactory: NetworkReachabilityProvidingFactory.Type?) {
        guard shared == nil else {
            return
        }

        let factory = reachabilityFactory ?? Reachability.self
        shared = NetworkReachabilityNotifier(
            host: host,
            allowsCellularAccess: allowsCellularAccess,
            reachabilityFactory: factory)
    }

    /// Clears the shared instance and all networkReachabilityWatchers
    static func clearShared() {
        guard let shared = shared else {
            return
        }
        NotificationCenter.default.removeObserver(shared)
        shared.clearWatchers()
        NetworkReachabilityNotifier.shared = nil
    }

    /// Creates the instance
    private init(host: String,
                 allowsCellularAccess: Bool,
                 reachabilityFactory: NetworkReachabilityProvidingFactory.Type) {
        reachability = reachabilityFactory.make(for: host)
        self.allowsCellularAccess = allowsCellularAccess

        // Add listener for Reachability and start its notifier
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(respondToReachabilityChange),
                                               name: .reachabilityChanged,
                                               object: nil)
        do {
            try reachability?.startNotifier()
        } catch {
        }

        // Add listener for KSReachability's notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(respondToReachabilityChange),
            name: NSNotification.Name(rawValue: kAWSDefaultNetworkReachabilityChangedNotification),
            object: nil)
    }

    /// Returns `true` if `endpointURL` is reachable based on the current network state.
    ///
    /// Note that a `true` return value from this operation does not mean that a network operation is guaranteed to succeed, or
    /// even that the network state is necessarily being accurately evaluated at the time of execution. This value should be
    /// considered advisory only; callers are responsible for correct error handling when actually performing a network
    /// operation.
    var isNetworkReachable: Bool {
        guard let reachability = reachability else {
            return false
        }

        switch reachability.connection {
        case .none:
            return false
        case .wifi:
            return true
        case .cellular:
            return allowsCellularAccess
        }
    }

    /// Adds a new item to the list of watchers to be notified in case of a network reachability change
    ///
    /// - Parameter watcher: The watcher to add
    func add(watcher: NetworkReachabilityWatcher) {
        objc_sync_enter(networkReachabilityWatchers)
        networkReachabilityWatchers.append(watcher)
        objc_sync_exit(networkReachabilityWatchers)
    }

    private func clearWatchers() {
        objc_sync_enter(networkReachabilityWatchers)
        networkReachabilityWatchers = []
        objc_sync_exit(networkReachabilityWatchers)
    }

    // MARK: - Notifications

    /// If a network reachability change occurs after the initial connection, respond by posting a notification to the default
    /// notification center, and by invoking each networkReachabilityWatcher callback.
    @objc private func respondToReachabilityChange() {
        guard isInitialConnection == false else {
            isInitialConnection = false
            return
        }

        guard let reachability = reachability else {
            return
        }

        let isReachable: Bool
        switch reachability.connection {
        case .wifi:
            isReachable = true
        case .cellular:
            isReachable = allowsCellularAccess
        case .none:
            isReachable = false
        }

        for watchers in networkReachabilityWatchers {
            watchers.onNetworkReachabilityChanged(isEndpointReachable: isReachable)
        }

        let info = AppSyncConnectionInfo(isConnectionAvailable: isReachable, isInitialConnection: isInitialConnection)
        NotificationCenter.default.post(name: .appSyncReachabilityChanged, object: info)
    }

}

// MARK: - Reachability

extension Reachability: NetworkReachabilityProvidingFactory {
    public static func make(for hostname: String) -> NetworkReachabilityProviding? {
        return Reachability(hostname: hostname)
    }
}

extension Reachability: NetworkReachabilityProviding { }
