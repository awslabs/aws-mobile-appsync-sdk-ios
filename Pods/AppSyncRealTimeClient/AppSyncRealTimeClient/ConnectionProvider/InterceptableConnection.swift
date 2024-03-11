//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Intercepts the connect request
public protocol ConnectionInterceptable {

    /// Add a new interceptor to the object.
    ///
    /// - Parameter interceptor: interceptor to be added
    func addInterceptor(_ interceptor: ConnectionInterceptor)

    @available(
        *,
        deprecated,
        message:
            """
            Use the async version under ConnectionInterceptableAsync or completion handler flavor
            """
    )
    func interceptConnection(
        _ request: AppSyncConnectionRequest,
        for endpoint: URL
    ) -> AppSyncConnectionRequest

    func interceptConnection(
        _ request: AppSyncConnectionRequest,
        for endpoint: URL,
        completion: @escaping (AppSyncConnectionRequest) -> Void
    )
}

public protocol MessageInterceptable {

    func addInterceptor(_ interceptor: MessageInterceptor)

    @available(
        *,
        deprecated,
        message:
            """
            Use the async version under MessageInterceptableAsync or completion handler flavor
            """
    )
    func interceptMessage(_ message: AppSyncMessage, for endpoint: URL) -> AppSyncMessage

    func interceptMessage(
        _ message: AppSyncMessage,
        for endpoint: URL,
        completion: @escaping (AppSyncMessage) -> Void
    )
}

public protocol ConnectionInterceptor {

    @available(
        *,
        deprecated,
        message:
            """
            Use the async version under ConnectionInterceptorAsync or completion handler flavor
            """
    )
    func interceptConnection(
        _ request: AppSyncConnectionRequest,
        for endpoint: URL
    ) -> AppSyncConnectionRequest

    func interceptConnection(
        _ request: AppSyncConnectionRequest,
        for endpoint: URL,
        completion: @escaping (AppSyncConnectionRequest) -> Void
    )
}

public protocol MessageInterceptor {

    @available(
        *,
        deprecated,
        message:
            """
            Use the async version under MessageInterceptorAsync or completion handler flavor
            """
    )
    func interceptMessage(_ message: AppSyncMessage, for endpoint: URL) -> AppSyncMessage

    func interceptMessage(
        _ message: AppSyncMessage,
        for endpoint: URL,
        completion: @escaping (AppSyncMessage) -> Void
    )
}

public protocol AuthInterceptor: MessageInterceptor, ConnectionInterceptor {}
