//
// Copyright 2018-2021 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Starscream

public class StarscreamAdapter: AppSyncWebsocketProvider {
    public init() {
        // Do nothing
    }

    private let serialQueue = DispatchQueue(label: "com.amazonaws.StarscreamAdapter.serialQueue")

    var socket: WebSocket?
    weak var delegate: AppSyncWebsocketDelegate?

    public func connect(url: URL, protocols: [String], delegate: AppSyncWebsocketDelegate?) {
        serialQueue.async {
            AppSyncLogger.verbose("[StarscreamAdapter] connect. Connecting to url")
            self.socket = WebSocket(url: url, protocols: protocols)
            self.delegate = delegate
            self.socket?.delegate = self
            self.socket?.callbackQueue = DispatchQueue(label: "com.amazonaws.StarscreamAdapter.callBack")
            self.socket?.connect()
        }
    }

    public func disconnect() {
        serialQueue.async {
            AppSyncLogger.verbose("[StarscreamAdapter] socket.disconnect")
            self.socket?.disconnect()
            self.socket = nil
        }
    }

    public func write(message: String) {
        serialQueue.async {
            AppSyncLogger.verbose("[StarscreamAdapter] socket.write - \(message)")
            self.socket?.write(string: message)
        }
    }

    public var isConnected: Bool {
        serialQueue.sync {
            return socket?.isConnected ?? false
        }
    }
}
