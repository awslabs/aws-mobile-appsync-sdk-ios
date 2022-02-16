//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Connection interceptor for real time connection provider
public class RealtimeGatewayURLInterceptor: ConnectionInterceptor {
    public init() {
        // Do nothing
    }

    public func interceptConnection(
        _ request: AppSyncConnectionRequest,
        for endpoint: URL
    ) -> AppSyncConnectionRequest {
        guard let host = endpoint.host else {
            return request
        }
        guard var urlComponents = URLComponents(url: request.url, resolvingAgainstBaseURL: false) else {
            return request
        }

        urlComponents.scheme = SubscriptionConstants.realtimeWebsocketScheme
        if AppSyncURLHelper.isStandardAppSyncGraphQLEndpoint(url: endpoint) {
            urlComponents.host = host.replacingOccurrences(
                of: SubscriptionConstants.appsyncHostPart,
                with: SubscriptionConstants.appsyncRealtimeHostPart
            )
        } else {
            // else this is a custom domain such that the host remains untouched and "/realtime" path is added
            urlComponents.path.append(contentsOf: "/" + SubscriptionConstants.appsyncCustomDomainRealtimePath)
        }

        guard let url = urlComponents.url else {
            return request
        }
        let realtimeRequest = AppSyncConnectionRequest(url: url)
        return realtimeRequest
    }
}
