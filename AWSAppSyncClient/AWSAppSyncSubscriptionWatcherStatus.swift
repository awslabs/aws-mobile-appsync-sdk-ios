//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

/// The status of a SubscriptionWatcher
public enum AWSAppSyncSubscriptionWatcherStatus {
    /// The subscription is in process of connecting
    case connecting

    /// The subscription has connected and is receiving events from the service
    case connected

    /// The subscription has been disconnected because of a lifecycle event or manual disconnect request
    case disconnected

    /// The subscription is in an error state. The enum's associated value will provide more details, including recovery options if available.
    case error(AWSAppSyncSubscriptionError)
}

extension AWSIoTMQTTStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .connected:
            return "connected"
        case .connecting:
            return "connecting"
        case .connectionError:
            return "connectionError"
        case .connectionRefused:
            return "connectionRefused"
        case .disconnected:
            return "disconnected"
        case .protocolError:
            return "protocolError"
        case .unknown:
            return "unknown"
        }
    }

    /// Convert to the equivalent SubscriptionWatcherStatus. Note that there is no equivalent status to
    /// SubscriptionWatcherStatus.connected -- that can only be set upon receipt of a SUBACK from the service.
    var toSubscriptionWatcherStatus: AWSAppSyncSubscriptionWatcherStatus {
        switch self {
        case .connected:
            return .connecting
        case .connecting:
            return .connecting
        case .connectionError:
            return .error(.connectionError)
        case .connectionRefused:
            return .error(.connectionRefused)
        case .disconnected:
            return .error(.disconnected)
        case .protocolError:
            return .error(.protocolError)
        case .unknown:
            return .error(.unknownMQTTConnectionStatus)
        }

    }

}
