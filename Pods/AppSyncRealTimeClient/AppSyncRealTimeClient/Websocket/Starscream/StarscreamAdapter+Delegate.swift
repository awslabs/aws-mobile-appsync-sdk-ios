//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Starscream

/// Extension to handle delegate callback from Starscream
extension StarscreamAdapter: Starscream.WebSocketDelegate {
    public func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected:
            websocketDidConnect(socket: client)
        case .disconnected(let reason, let code):
            AppSyncLogger.verbose("[StarscreamAdapter] disconnected: reason=\(reason); code=\(code)")
            websocketDidDisconnect(socket: client, error: nil)
        case .text(let string):
            websocketDidReceiveMessage(socket: client, text: string)
        case .binary(let data):
            websocketDidReceiveData(socket: client, data: data)
        case .ping:
            AppSyncLogger.verbose("[StarscreamAdapter] ping")
        case .pong:
            AppSyncLogger.verbose("[StarscreamAdapter] pong")
        case .viabilityChanged(let viability):
            AppSyncLogger.verbose("[StarscreamAdapter] viabilityChanged: \(viability)")
        case .reconnectSuggested(let suggestion):
            AppSyncLogger.verbose("[StarscreamAdapter] reconnectSuggested: \(suggestion)")
        case .cancelled:
            websocketDidDisconnect(socket: client, error: nil)
        case .error(let error):
            websocketDidDisconnect(socket: client, error: error)
        }
    }

    private func websocketDidConnect(socket: WebSocketClient) {
        AppSyncLogger.verbose("[StarscreamAdapter] websocketDidConnect: websocket has been connected.")
        serialQueue.async {
            self._isConnected = true
            self.delegate?.websocketDidConnect(provider: self)
        }
    }

    private func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        AppSyncLogger.verbose("[StarscreamAdapter] websocketDidDisconnect: \(error?.localizedDescription ?? "No error")")
        serialQueue.async {
            self._isConnected = false
            self.delegate?.websocketDidDisconnect(provider: self, error: error)
        }
    }

    private func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        AppSyncLogger.verbose("[StarscreamAdapter] websocketDidReceiveMessage: - \(text)")
        let data = text.data(using: .utf8) ?? Data()
        delegate?.websocketDidReceiveData(provider: self, data: data)
    }

    private func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        AppSyncLogger.verbose("[StarscreamAdapter] WebsocketDidReceiveData - \(data)")
        delegate?.websocketDidReceiveData(provider: self, data: data)
    }
}
