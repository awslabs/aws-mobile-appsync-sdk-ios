//
// Copyright 2010-2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
import Reachability
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

    var connection = Reachability.Connection.wifi {
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
