//
// Copyright 2018-2021 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Starscream

/// Extension to handle delegate callback from Starscream
extension StarscreamAdapter: Starscream.WebSocketDelegate {

    public func websocketDidConnect(socket: WebSocketClient) {
        AppSyncLogger.verbose("[StarscreamAdapter] websocketDidConnect: websocket has been connected.")
        delegate?.websocketDidConnect(provider: self)
    }

    public func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        AppSyncLogger.verbose("[StarscreamAdapter] websocketDidDisconnect: \(error?.localizedDescription ?? "No error")")
        delegate?.websocketDidDisconnect(provider: self, error: error)
    }

    public func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        AppSyncLogger.verbose("[StarscreamAdapter] websocketDidReceiveMessage: - \(text)")
        let data = text.data(using: .utf8) ?? Data()
        delegate?.websocketDidReceiveData(provider: self, data: data)
    }

    public func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        AppSyncLogger.verbose("[StarscreamAdapter] WebsocketDidReceiveData - \(data)")
        delegate?.websocketDidReceiveData(provider: self, data: data)
    }
}
