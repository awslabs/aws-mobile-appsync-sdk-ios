//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension RealtimeConnectionProvider: AppSyncWebsocketDelegate {

    public func websocketDidConnect(provider: AppSyncWebsocketProvider) {
        // Call the ack to finish the connection handshake
        // Inform the callback when ack gives back a response.
        AppSyncLogger.debug("[RealtimeConnectionProvider] WebsocketDidConnect, sending init message")
        sendConnectionInitMessage()
        startStaleConnectionTimer()
    }

    public func websocketDidDisconnect(provider: AppSyncWebsocketProvider, error: Error?) {
        connectionQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.status = .notConnected
            guard error != nil else {
                self.updateCallback(event: .connection(self.status))
                return
            }
            self.updateCallback(event: .error(ConnectionProviderError.connection))
        }
    }

    public func websocketDidReceiveData(provider: AppSyncWebsocketProvider, data: Data) {
        do {
            let response = try JSONDecoder().decode(RealtimeConnectionProviderResponse.self, from: data)
            handleResponse(response)
        } catch {
            AppSyncLogger.error(error)
            updateCallback(event: .error(ConnectionProviderError.jsonParse(nil, error)))
        }
    }

    // MARK: - Handle websocket response

    private func handleResponse(_ response: RealtimeConnectionProviderResponse) {
        resetStaleConnectionTimer()

        switch response.responseType {
        case .connectionAck:
            AppSyncLogger.debug("[RealtimeConnectionProvider] received connectionAck")
            connectionQueue.async { [weak self] in
                self?.handleConnectionAck(response: response)
            }
        case .error:
            AppSyncLogger.verbose("[RealtimeConnectionProvider] received error")
            connectionQueue.async { [weak self] in
                self?.handleError(response: response)
            }
        case .subscriptionAck, .unsubscriptionAck, .data:
            if let appSyncResponse = response.toAppSyncResponse() {
                updateCallback(event: .data(appSyncResponse))
            }
        case .keepAlive:
            AppSyncLogger.verbose("[RealtimeConnectionProvider] received keepAlive")
        }
    }

    /// Updates connection status callbacks and sets stale connection timeout
    ///
    /// - Warning: This method must be invoked on the `connectionQueue`
    private func handleConnectionAck(response: RealtimeConnectionProviderResponse) {
        // Only from in progress state, the connection can transition to connected state.
        // The below guard statement make sure that. If we get connectionAck in other
        // state means that we have initiated a disconnect parallely.
        guard status == .inProgress else {
            return
        }

        status = .connected
        updateCallback(event: .connection(status))

        // If the service returns a connection timeout, use that instead of the default
        guard case let .number(value) = response.payload?["connectionTimeoutMs"] else {
            return
        }

        let interval = value / 1_000

        guard interval != staleConnectionTimer.interval else {
            return
        }

        AppSyncLogger.debug(
            """
            Resetting keep alive timer in response to service timeout \
            instructions: \(interval)s
            """
        )
        resetStaleConnectionTimer(interval: interval)
    }

    /// Resolves & dispatches errors from `response`.
    ///
    /// - Warning: This method must be invoked on the `connectionQueue`
    private func handleError(response: RealtimeConnectionProviderResponse) {
        // If we get an error in connection inprogress state, return back as connection error.
        guard status != .inProgress else {
            status = .notConnected
            updateCallback(event: .error(ConnectionProviderError.connection))
            return
        }

        // Return back as generic error if there is no identifier.
        guard let identifier = response.id else {
            let genericError = ConnectionProviderError.other
            updateCallback(event: .error(genericError))
            return
        }

        if response.isMaxSubscriptionReachedError() {
            let limitExceedError = ConnectionProviderError.limitExceeded(identifier)
            updateCallback(event: .error(limitExceedError))
            return
        }

        let subscriptionError = ConnectionProviderError.subscription(identifier, response.payload)
        updateCallback(event: .error(subscriptionError))
    }

}

extension RealtimeConnectionProviderResponse {

    func toAppSyncResponse() -> AppSyncResponse? {
        guard let appSyncType = responseType.toAppSyncResponseType() else {
            return nil
        }
        return AppSyncResponse(id: id, payload: payload, type: appSyncType)
    }
}

extension RealtimeConnectionProviderResponseType {

    func toAppSyncResponseType() -> AppSyncResponseType? {
        switch self {
        case .subscriptionAck:
            return .subscriptionAck
        case .unsubscriptionAck:
            return .unsubscriptionAck
        case .data:
            return .data
        default:
            return nil
        }
    }
}
