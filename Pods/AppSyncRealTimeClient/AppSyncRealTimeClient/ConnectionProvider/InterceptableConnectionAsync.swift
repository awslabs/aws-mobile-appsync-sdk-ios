//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public protocol ConnectionInterceptableAsync {
    #if swift(>=5.5.2)
    /// Add a new interceptor to the object.
    ///
    /// - Parameter interceptor: interceptor to be added
    func addInterceptor(_ interceptor: ConnectionInterceptorAsync)

    func interceptConnection(_ request: AppSyncConnectionRequest, for endpoint: URL) async -> AppSyncConnectionRequest
    #endif
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public protocol MessageInterceptableAsync {
    #if swift(>=5.5.2)
    func addInterceptor(_ interceptor: MessageInterceptorAsync)

    func interceptMessage(_ message: AppSyncMessage, for endpoint: URL) async -> AppSyncMessage
    #endif
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public protocol ConnectionInterceptorAsync {
    #if swift(>=5.5.2)
    func interceptConnection(_ request: AppSyncConnectionRequest, for endpoint: URL) async -> AppSyncConnectionRequest
    #endif
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public protocol MessageInterceptorAsync {
    #if swift(>=5.5.2)
    func interceptMessage(_ message: AppSyncMessage, for endpoint: URL) async -> AppSyncMessage
    #endif
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public protocol AuthInterceptorAsync: MessageInterceptorAsync, ConnectionInterceptorAsync {}
