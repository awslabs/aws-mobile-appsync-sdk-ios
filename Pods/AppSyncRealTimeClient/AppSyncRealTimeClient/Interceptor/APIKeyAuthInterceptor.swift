//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Auth interceptor for API Key based authentication
public class APIKeyAuthInterceptor: AuthInterceptor {

    let apiKey: String

    public init(_ apiKey: String) {
        self.apiKey = apiKey
    }

    /// Intercept the connection and adds header, payload query to the request url.
    ///
    /// The value of header should be the base64 string of the following:
    /// * "host": <string> : this is the host for the AppSync endpoint
    /// * "x-amz-date": <string> : UTC timestamp in the following ISO 8601 format: YYYYMMDD'T'HHMMSS'Z'
    /// * "x-api-key": <string> : Api key configured for AppSync API
    /// The value of payload is {}
    /// - Parameter request: Signed request
    public func interceptConnection(
        _ request: AppSyncConnectionRequest,
        for endpoint: URL
    ) -> AppSyncConnectionRequest {
        let host = endpoint.host!
        let authHeader = APIKeyAuthenticationHeader(apiKey: apiKey, host: host)
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

    public func interceptMessage(_ message: AppSyncMessage, for endpoint: URL) -> AppSyncMessage {
        let host = endpoint.host!
        switch message.messageType {
        case .subscribe:
            let authHeader = APIKeyAuthenticationHeader(apiKey: apiKey, host: host)
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
}

/// Authentication header for API key based auth
private class APIKeyAuthenticationHeader: AuthenticationHeader {
    static let ISO8601DateFormat: String = "yyyyMMdd'T'HHmmss'Z'"
    let date: String?
    let apiKey: String

    var formatter: DateFormatter = {
        var formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = ISO8601DateFormat
        return formatter
    }()

    init(apiKey: String, host: String) {
        self.date = formatter.string(from: Date())
        self.apiKey = apiKey
        super.init(host: host)
    }

    private enum CodingKeys: String, CodingKey {
        case date = "x-amz-date"
        case apiKey = "x-api-key"
    }

    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encode(apiKey, forKey: .apiKey)
        try super.encode(to: encoder)
    }
}
