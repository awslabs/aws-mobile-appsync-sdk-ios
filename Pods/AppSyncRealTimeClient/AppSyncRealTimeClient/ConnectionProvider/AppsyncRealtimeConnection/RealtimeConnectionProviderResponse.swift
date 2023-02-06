//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// More information about the response can be found here
/// https://docs.aws.amazon.com/appsync/latest/devguide/real-time-websocket-client.html#connection-init-message
struct RealtimeConnectionProviderResponse {

    /// Subscription Identifier
    ///
    let id: String?

    let payload: [String: AppSyncJSONValue]?

    let responseType: RealtimeConnectionProviderResponseType

    init(
        id: String? = nil,
        payload: [String: AppSyncJSONValue]? = nil,
        type: RealtimeConnectionProviderResponseType
    ) {
        self.id = id
        self.responseType = type
        self.payload = payload
    }
}

/// Response types
enum RealtimeConnectionProviderResponseType: String, Decodable {

    case connectionAck = "connection_ack"

    case subscriptionAck = "start_ack"

    case unsubscriptionAck = "complete"

    case keepAlive = "ka"

    case data

    case error

    case connectionError = "connection_error"
}

extension RealtimeConnectionProviderResponse: Decodable {

    enum CodingKeys: String, CodingKey {
        case id
        case payload
        case responseType = "type"
    }
}

/// Helper methods to check which type of errors, such as `MaxSubscriptionsReachedError`, `LimitExceededError`.
/// Errors have the following shape
///
///      "type": "error": A constant <string> parameter.
///      "id": <string>: The ID of the corresponding registered subscription, if relevant.
///      "payload" <Object>: An object that contains the corresponding error information.
///
/// More information can be found here
/// https://docs.aws.amazon.com/appsync/latest/devguide/real-time-websocket-client.html#error-message
extension RealtimeConnectionProviderResponse {

    func toConnectionProviderError(connectionState: ConnectionState) -> ConnectionProviderError {
        // If it is Unauthorized, return `.unauthorized` error.
        guard !isUnauthorizationError() else {
            return .unauthorized
        }

        // If it is in-progress, return `.connection`.
        guard connectionState != .inProgress else {
            return .connection
        }

        if isLimitExceededError() || isMaxSubscriptionReachedError() {
            // Is it observed that LimitExceeded error does not have `id` while MaxSubscriptionReached does have a
            // corresponding identifier. Both are mapped to `limitExceeded` with optional identifier.
            return .limitExceeded(id)
        }

        // If the type of error is not handled (by checking `isLimitExceededError`, `isMaxSubscriptionReachedError`,
        // etc), and is not for a specific subscription, then return unknown error
        guard let identifier = id else {
            return .unknown(message: nil, causedBy: nil, payload: payload)
        }

        // Default scenario - return the error with subscription id and error payload.
        return .subscription(identifier, payload)
    }

    func isMaxSubscriptionReachedError() -> Bool {
        // It is expected to contain payload with corresponding error information
        guard let payload = payload else {
            return false
        }

        // Keep this here for backwards compatibility for previously provisioned AppSync services
        if let errorType = payload["errorType"],
            errorType == "MaxSubscriptionsReachedException" {
            return true
        }

        // The observed response from the service
        // { "id":"DB23EC80-C51A-4FEE-82F7-AA4949B4F299",
        //  "type":"error",
        //  "payload": {
        //      "errors": {
        //          "errorType":"MaxSubscriptionsReachedError",
        //          "message":"Max number of 100 subscriptions reached" }}}
        if let errors = payload["errors"],
           case let .object(errorsObject) = errors,
           let errorType = errorsObject["errorType"],
           errorType == "MaxSubscriptionsReachedError" {
            return true
        }

        return false
    }

    func isLimitExceededError() -> Bool {
        // It is expected to contain payload with corresponding error information
        guard let payload = payload else {
            return false
        }

        // The observed response from the service
        // { "type":"error",
        //  "payload": {
        //      "errors": {
        //          "errorType":"LimitExceededError",
        //          "message":"Rate limit exceeded" }}}
        if let errors = payload["errors"],
           case let .object(errorsObject) = errors,
           let errorType = errorsObject["errorType"],
           errorType == "LimitExceededError" {
            return true
        }

        return false
    }

    func isUnauthorizationError() -> Bool {
        // It is expected to contain payload with corresponding error information
        guard let payload = payload,
              let errors = payload["errors"],
              case let .array(errorsArray) = errors else {
            return false
        }

        // The observed response from the service
        // { "payload": {
        //      "errors": [{
        //          "errorType":"com.amazonaws.deepdish.graphql.auth#UnauthorizedException",
        //          "message":"You are not authorized to make this call.",
        //          "errorCode":400 }]},
        //  "type":"connection_error" }
        return errorsArray.contains { error in
            guard case let .object(errorObject) = error,
                  case let .string(errorObjectString) = errorObject["errorType"] else {
                return false
            }

            if errorObjectString.contains("UnauthorizedException") {
                return true
            }

            return false
        }
    }
}
