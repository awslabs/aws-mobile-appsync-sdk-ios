//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Create connection providers to connect to the websocket endpoint of the AppSync endpoint.
public enum ConnectionProviderFactory {

    public static func createConnectionProvider(
        for urlRequest: URLRequest,
        authInterceptor: AuthInterceptor,
        connectionType: SubscriptionConnectionType
    ) -> ConnectionProvider {
        let provider: ConnectionProvider

        switch connectionType {
        case .appSyncRealtime:
            let websocketProvider = StarscreamAdapter()
            provider = RealtimeConnectionProvider(for: urlRequest, websocket: websocketProvider)
        }

        if let messageInterceptable = provider as? MessageInterceptable {
            messageInterceptable.addInterceptor(authInterceptor)
        }
        if let connectionInterceptable = provider as? ConnectionInterceptable {
            connectionInterceptable.addInterceptor(RealtimeGatewayURLInterceptor())
            connectionInterceptable.addInterceptor(authInterceptor)
        }

        return provider
    }

    #if swift(>=5.5.2)
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    public static func createConnectionProviderAsync(
        for urlRequest: URLRequest,
        authInterceptor: AuthInterceptorAsync,
        connectionType: SubscriptionConnectionType
    ) -> ConnectionProvider {
        let provider: ConnectionProvider

        switch connectionType {
        case .appSyncRealtime:
            let websocketProvider = StarscreamAdapter()
            provider = RealtimeConnectionProviderAsync(for: urlRequest, websocket: websocketProvider)
        }

        if let messageInterceptable = provider as? MessageInterceptableAsync {
            messageInterceptable.addInterceptor(authInterceptor)
        }
        if let connectionInterceptable = provider as? ConnectionInterceptableAsync {
            connectionInterceptable.addInterceptor(RealtimeGatewayURLInterceptor())
            connectionInterceptable.addInterceptor(authInterceptor)
        }

        return provider
    }
    #endif
}
