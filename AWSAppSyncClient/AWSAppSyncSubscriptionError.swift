//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

public enum AWSAppSyncSubscriptionError: Error, LocalizedError {
    /// The underlying connection reported a status of "connectionError"
    case connectionError

    /// The underlying connection reported a status of "connectionRefused"
    case connectionRefused

    /// The underlying connection reported a status of "disconnected"
    case disconnected

    /// An error occurred parsing the subscription message received from the service
    case messageCallbackError(String)

    /// Some other error occurred. See associated value for details
    case other(Error)

    /// An error occurred parsing the published subscription message
    case parseError(Error)

    /// The underlying connection reported a status of "protocolError"
    case protocolError

    /// An error occurred while making the initial subscription request to AppSync, parsing its response, or
    /// evaluating the response's subscription info payload
    case setupError(String)

    /// The underlying MQTT client reported a status of "unknown"
    @available(*, deprecated, message: "Subscription is not tied with mqtt connection anymore")
    case unknownMQTTConnectionStatus

    public var errorDescription: String? {
        switch self {
        case .messageCallbackError(let message):
            return message
        case .other(let error):
            return error.localizedDescription
        case .parseError(let error):
            return error.localizedDescription
        case .setupError(let message):
            return message
        case .unknownMQTTConnectionStatus:
            return "MQTT status unknown"
        default:
            return "Subscription Terminated."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .other(let error as NSError):
            return error.localizedRecoverySuggestion
        case .parseError, .unknownMQTTConnectionStatus:
            return nil
        default:
            return "Restart subscription request."
        }
    }

    public var failureReason: String? {
        switch self {
        case .other(let error as NSError):
            return error.localizedFailureReason
        case .parseError, .unknownMQTTConnectionStatus:
            return nil
        case .setupError(let message):
            return message
        default:
            return "Disconnected from service."
        }
    }
}
