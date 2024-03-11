//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public extension ConnectionInterceptable {

    func interceptConnection(
        _ request: AppSyncConnectionRequest,
        for endpoint: URL,
        completion: @escaping (AppSyncConnectionRequest) -> Void
    ) {
        let result = interceptConnection(request, for: endpoint)
        completion(result)
    }
}

public extension MessageInterceptable {

    func interceptMessage(
        _ message: AppSyncMessage,
        for endpoint: URL,
        completion: @escaping (AppSyncMessage) -> Void
    ) {
        let result = interceptMessage(message, for: endpoint)
        completion(result)
    }
}

public extension ConnectionInterceptor {

    func interceptConnection(
        _ request: AppSyncConnectionRequest,
        for endpoint: URL,
        completion: @escaping (AppSyncConnectionRequest) -> Void
    ) {
        let result = interceptConnection(request, for: endpoint)
        completion(result)
    }
}

public extension MessageInterceptor {

    func interceptMessage(
        _ message: AppSyncMessage,
        for endpoint: URL,
        completion: @escaping (AppSyncMessage) -> Void
    ) {
        let result = interceptMessage(message, for: endpoint)
        completion(result)
    }
}
