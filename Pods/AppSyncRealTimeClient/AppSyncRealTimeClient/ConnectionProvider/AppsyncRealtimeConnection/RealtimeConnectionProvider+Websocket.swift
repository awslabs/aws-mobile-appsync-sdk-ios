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
        case .connectionError:
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
    func handleError(response: RealtimeConnectionProviderResponse) {
        // If we get an error while the connection was inProgress state,
        let error = response.toConnectionProviderError(connectionState: status)
        if status == .inProgress {
            status = .notConnected
        }

        // If limit exceeded is for a particular subscription identifier, throttle using `limitExceededSubject`
        if case .limitExceeded(let id) = error, id == nil, #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *) {
            self.limitExceededSubject.send(error)
        } else {
            updateCallback(event: .error(error))
        }
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
