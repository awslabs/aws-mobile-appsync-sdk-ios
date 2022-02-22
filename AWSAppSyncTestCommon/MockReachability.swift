//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
@testable import AWSAppSync

/// The factory will always return the same instance. Make sure to clear the instance between tests by calling `clearShared`
/// in the test's `tearDown` method.
struct MockReachabilityProvidingFactory: NetworkReachabilityProvidingFactory {
    static var instance = MockReachabilityProviding()

    static func clearShared() {
        instance = MockReachabilityProviding()
    }

    static func make(for hostname: String) -> NetworkReachabilityProviding? {
        return instance
    }
}

/// The instance class vended by ReachabilityProvidingTestFactory
class MockReachabilityProviding: NetworkReachabilityProviding {

    var allowsCellularConnection = false
    var notificationCenter = NotificationCenter.default

    var connection = AWSAppSyncReachability.Connection.wifi {
        didSet {
            guard isNotifierStarted else {
                return
            }

            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                self.notificationCenter.post(name: .reachabilityChanged, object: self)
            }
        }
    }

    private var isNotifierStarted = false

    func startNotifier() throws {
        isNotifierStarted = true
    }

    func stopNotifier() {
        isNotifierStarted = false
    }

}
