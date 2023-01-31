//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if swift(>=5.5.2)

import Foundation

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension RealtimeConnectionProviderAsync: ConnectionInterceptableAsync {

    public func addInterceptor(_ interceptor: ConnectionInterceptorAsync) {
        connectionInterceptors.append(interceptor)
    }

    public func interceptConnection(
        _ request: AppSyncConnectionRequest,
        for endpoint: URL
    ) async -> AppSyncConnectionRequest {
        var finalRequest = request
        for interceptor in connectionInterceptors {
            finalRequest = await interceptor.interceptConnection(finalRequest, for: endpoint)
        }

        return finalRequest
    }
}

#endif
