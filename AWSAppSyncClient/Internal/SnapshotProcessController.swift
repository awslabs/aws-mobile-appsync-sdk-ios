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

final class SnapshotProcessController {
    let endpointURL: URL
    var reachability: Reachability?
    private var networkStatusWatchers: [NetworkConnectionNotification] = []
    let allowsCellularAccess: Bool

    init(endpointURL: URL, allowsCellularAccess: Bool = true) {
        self.endpointURL = endpointURL
        self.allowsCellularAccess = allowsCellularAccess

        reachability = Reachability(hostname: endpointURL.host!)
        reachability?.allowsCellularConnection = allowsCellularAccess

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(checkForReachability(note:)),
            name: .reachabilityChanged,
            object: reachability)
        do {
            try reachability?.startNotifier()
        } catch {
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(SnapshotProcessController.checkForReachability),
            name: NSNotification.Name(rawValue: kAWSDefaultNetworkReachabilityChangedNotification),
            object: nil)
    }

    @objc func checkForReachability(note: Notification) {

        let reachability = note.object as! Reachability
        var isReachable = true
        switch reachability.connection {
        case .none:
            isReachable = false
        default:
            break
        }

        for watchers in networkStatusWatchers {
            watchers.onNetworkAvailabilityStatusChanged(isEndpointReachable: isReachable)
        }
    }

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

    func isEligibleForExecution(_ operation: AWSAppSyncGraphQLOperation) -> Bool {
        switch operation {
        case .mutation:
            return isNetworkReachable
        case .query:
            return true
        case .subscription:
            return true
        }
    }
}
