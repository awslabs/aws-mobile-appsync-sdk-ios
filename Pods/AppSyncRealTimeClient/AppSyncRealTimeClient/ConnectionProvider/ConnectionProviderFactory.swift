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
        for url: URL,
        authInterceptor: AuthInterceptor,
        connectionType: SubscriptionConnectionType
    ) -> ConnectionProvider {
        let provider = ConnectionProviderFactory.createConnectionProvider(for: url, connectionType: connectionType)

        if let messageInterceptable = provider as? MessageInterceptable {
            messageInterceptable.addInterceptor(authInterceptor)
        }
        if let connectionInterceptable = provider as? ConnectionInterceptable {
            connectionInterceptable.addInterceptor(RealtimeGatewayURLInterceptor())
            connectionInterceptable.addInterceptor(authInterceptor)
        }

        return provider
    }

    static func createConnectionProvider(
        for url: URL,
        connectionType: SubscriptionConnectionType
    ) -> ConnectionProvider {
        switch connectionType {
        case .appSyncRealtime:
            let websocketProvider = StarscreamAdapter()
            let connectionProvider = RealtimeConnectionProvider(for: url, websocket: websocketProvider)
            return connectionProvider
        }
    }
}
