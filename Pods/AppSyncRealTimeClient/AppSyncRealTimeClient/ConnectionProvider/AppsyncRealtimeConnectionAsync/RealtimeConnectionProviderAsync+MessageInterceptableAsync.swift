//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if swift(>=5.5.2)

import Foundation

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension RealtimeConnectionProviderAsync: MessageInterceptableAsync {
    public func addInterceptor(_ interceptor: MessageInterceptorAsync) {
        messageInterceptors.append(interceptor)
    }

    public func interceptMessage(_ message: AppSyncMessage, for endpoint: URL) async -> AppSyncMessage {
        var finalMessage = message
        for interceptor in messageInterceptors {
            finalMessage = await interceptor.interceptMessage(finalMessage, for: endpoint)
        }

        return finalMessage
    }
}

#endif
