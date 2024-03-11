//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension RealtimeConnectionProvider: ConnectionInterceptable {

    public func addInterceptor(_ interceptor: ConnectionInterceptor) {
        connectionInterceptors.append(interceptor)
    }

    public func interceptConnection(
        _ request: AppSyncConnectionRequest,
        for endpoint: URL,
        completion: @escaping (AppSyncConnectionRequest) -> Void
    ) {
            chainInterceptors(
                iterator: connectionInterceptors.makeIterator(),
                request: request,
                endpoint: endpoint,
                completion: completion
            )
        }

    private func chainInterceptors<I: IteratorProtocol>(
        iterator: I,
        request: AppSyncConnectionRequest,
        endpoint: URL,
        completion: @escaping (AppSyncConnectionRequest) -> Void
    ) where I.Element == ConnectionInterceptor {

            var mutableIterator = iterator
            guard let interceptor = mutableIterator.next() else {
                completion(request)
                return
            }
            interceptor.interceptConnection(request, for: endpoint) { interceptedRequest in
                self.chainInterceptors(
                    iterator: mutableIterator,
                    request: interceptedRequest,
                    endpoint: endpoint,
                    completion: completion
                )
            }
        }

    // MARK: Deprecated method

    public func interceptConnection(
        _ request: AppSyncConnectionRequest,
        for endpoint: URL
    ) -> AppSyncConnectionRequest {
        // This is added here for backward compatibility
        let finalRequest = connectionInterceptors.reduce(request) { $1.interceptConnection($0, for: endpoint) }
        return finalRequest
    }
}
