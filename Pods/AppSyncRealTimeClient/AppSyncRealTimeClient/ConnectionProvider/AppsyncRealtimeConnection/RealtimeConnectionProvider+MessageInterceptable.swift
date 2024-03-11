//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension RealtimeConnectionProvider: MessageInterceptable {

    public func addInterceptor(_ interceptor: MessageInterceptor) {
        messageInterceptors.append(interceptor)
    }

    public func interceptMessage(
        _ message: AppSyncMessage,
        for endpoint: URL,
        completion: @escaping (AppSyncMessage) -> Void
    ) {

        chainInterceptors(
            iterator: messageInterceptors.makeIterator(),
            message: message,
            endpoint: endpoint,
            completion: completion
        )
    }

    private func chainInterceptors<I: IteratorProtocol>(
        iterator: I,
        message: AppSyncMessage,
        endpoint: URL,
        completion: @escaping (AppSyncMessage) -> Void
    ) where I.Element == MessageInterceptor {

        var mutableIterator = iterator
        guard let interceptor = mutableIterator.next() else {
            completion(message)
            return
        }
        interceptor.interceptMessage(message, for: endpoint) { interceptedMessage in
            self.chainInterceptors(
                iterator: mutableIterator,
                message: interceptedMessage,
                endpoint: endpoint,
                completion: completion
            )
        }
    }

    // MARK: Deprecated method

    public func interceptMessage(_ message: AppSyncMessage, for endpoint: URL) -> AppSyncMessage {
        // This is added here for backward compatibility
        let finalMessage = messageInterceptors.reduce(message) { $1.interceptMessage($0, for: endpoint) }
        return finalMessage
    }
}
