//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if swift(>=5.5.2)

import Foundation

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public class OIDCAuthInterceptorAsync: AuthInterceptorAsync {

    let authProvider: OIDCAuthProviderAsync

    public init(_ authProvider: OIDCAuthProviderAsync) {
        self.authProvider = authProvider
    }

    public func interceptMessage(_ message: AppSyncMessage, for endpoint: URL) async -> AppSyncMessage {
        let host = endpoint.host!
        let jwtToken: String
        do {
            jwtToken = try await authProvider.getLatestAuthToken()
        } catch {
            return message
        }
        switch message.messageType {
        case .subscribe:
            let authHeader = UserPoolsAuthenticationHeader(token: jwtToken, host: host)
            var payload = message.payload ?? AppSyncMessage.Payload()
            payload.authHeader = authHeader

            let signedMessage = AppSyncMessage(
                id: message.id,
                payload: payload,
                type: message.messageType
            )
            return signedMessage
        default:
            break
        }
        return message
    }

    public func interceptConnection(
        _ request: AppSyncConnectionRequest,
        for endpoint: URL
    ) async -> AppSyncConnectionRequest {
        let host = endpoint.host!
        let jwtToken: String
        do {
            jwtToken = try await authProvider.getLatestAuthToken()
        } catch {
            // A user that is not signed in should receive an unauthorized error from the connection attempt. This code
            // achieves this by always creating a valid request to AppSync even when the token cannot be retrieved. The
            // request sent to AppSync will receive a response indicating the request is unauthorized. If we do not use
            // empty token string and perform the remaining logic of the request construction then it will fail request
            // validation at AppSync before the authorization check, which ends up being propagated back to the caller
            // as a "bad request". Example of bad requests are when the header and payload query strings are missing
            // or when the data is not base64 encoded.
            jwtToken = ""
        }

        let authHeader = UserPoolsAuthenticationHeader(token: jwtToken, host: host)
        let base64Auth = AppSyncJSONHelper.base64AuthenticationBlob(authHeader)

        let payloadData = SubscriptionConstants.emptyPayload.data(using: .utf8)
        let payloadBase64 = payloadData?.base64EncodedString()

        guard var urlComponents = URLComponents(url: request.url, resolvingAgainstBaseURL: false) else {
            return request
        }
        let headerQuery = URLQueryItem(name: RealtimeProviderConstants.header, value: base64Auth)
        let payloadQuery = URLQueryItem(name: RealtimeProviderConstants.payload, value: payloadBase64)
        urlComponents.queryItems = [headerQuery, payloadQuery]
        guard let url = urlComponents.url else {
            return request
        }
        let signedRequest = AppSyncConnectionRequest(url: url)
        return signedRequest
    }
}

/// Authentication header for user pool based auth
private class UserPoolsAuthenticationHeader: AuthenticationHeader {
    let authorization: String

    init(token: String, host: String) {
        self.authorization = token
        super.init(host: host)
    }

    private enum CodingKeys: String, CodingKey {
        case authorization = "Authorization"
    }

    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(authorization, forKey: .authorization)
        try super.encode(to: encoder)
    }
}
#endif
