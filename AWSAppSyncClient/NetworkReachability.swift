//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
import Reachability

/// Defines a factory to return a NetworkReachabilityProviding instance
public protocol NetworkReachabilityProvidingFactory {
    /// Abstracting the only of Reachability's initializers that we care about into a factory method. Since Reachability isn't
    /// final, we'd have to add a lot of code to conform its initializers otherwise.
    static func make(for hostname: String) -> NetworkReachabilityProviding?
}

/// Wraps methods and properties of Reachability
public protocol NetworkReachabilityProviding: class {
    /// If `true`, device can attempt to reach the host using a cellular connection (WAN). If `false`, host is only considered
    /// reachable if it can be accessed via WiFi
    var allowsCellularConnection: Bool { get set }

    var connection: Reachability.Connection { get }

    /// The notification center on which "reachability changed" events are being posted
    var notificationCenter: NotificationCenter { get set }

    /// Starts notifications for reachability changes
    func startNotifier() throws

    /// Pauses notifications for reachability changes
    func stopNotifier()
}
