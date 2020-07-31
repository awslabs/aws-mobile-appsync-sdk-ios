//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Appsync Real time connection that connects to subscriptions
/// through websocket.
public class RealtimeConnectionProvider: ConnectionProvider {

    let url: URL
    var status: ConnectionState = .notConnected
    let websocket: AppSyncWebsocketProvider
    var listeners: [String: ConnectionProviderCallback] = [:]
    var messageInterceptors: [MessageInterceptor] = []
    var connectionInterceptors: [ConnectionInterceptor] = []

    /// Maximum number of seconds a connection may go without receiving a keep alive
    /// message before we consider it stale and force a disconnect
    var staleConnectionTimeout: TimeInterval = 5 * 60

    /// A timer that automatically disconnects the current connection if it goes longer
    /// than `staleConnectionTimeout` without activity. Receiving any data or "keep
    /// alive" message will cause the timer to be reset to the full interval.
    var staleConnectionTimer: CountdownTimer?

    /// Serial queue for websocket connection.
    ///
    /// Each connection request will be sent to this queue. Connection request are
    /// handled one at a time.
    let serialConnectionQueue = DispatchQueue(label: "com.amazonaws.AppSyncRealTimeConnectionProvider.serialQueue")

    let serialCallbackQueue = DispatchQueue(label: "com.amazonaws.AppSyncRealTimeConnectionProvider.callbackQueue")

    let serialWriteQueue = DispatchQueue(label: "com.amazonaws.AppSyncRealTimeConnectionProvider.writeQueue")

    public init(for url: URL, websocket: AppSyncWebsocketProvider) {
        self.url = url
        self.websocket = websocket
    }

    // MARK: - ConnectionProvider methods

    public func connect() {
        serialConnectionQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            guard self.status == .notConnected else {
                self.updateCallback(event: .connection(self.status))
                return
            }
            self.status = .inProgress
            self.updateCallback(event: .connection(self.status))
            let request = AppSyncConnectionRequest(url: self.url)
            let signedRequest = self.interceptConnection(request, for: self.url)
            DispatchQueue.global().async {
                self.websocket.connect(
                    url: signedRequest.url,
                    protocols: ["graphql-ws"],
                    delegate: self
                )
            }
        }
    }

    public func write(_ message: AppSyncMessage) {

        serialWriteQueue.async { [weak self] in
            guard let self = self else {
                return
            }

            let signedMessage = self.interceptMessage(message, for: self.url)
            let jsonEncoder = JSONEncoder()
            do {
                let jsonData = try jsonEncoder.encode(signedMessage)
                guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                    let jsonError = ConnectionProviderError.jsonParse(message.id, nil)
                    self.updateCallback(event: .error(jsonError))
                    return
                }
                self.websocket.write(message: jsonString)
            } catch {
                AppSyncLogger.error(error)
                switch message.messageType {
                case .connectionInit:
                    self.receivedConnectionInit()
                default:
                    self.updateCallback(event: .error(ConnectionProviderError.jsonParse(message.id, error)))
                }
            }
        }

    }

    public func disconnect() {
        websocket.disconnect()
        staleConnectionTimer?.invalidate()
        staleConnectionTimer = nil
    }

    public func addListener(identifier: String, callback: @escaping ConnectionProviderCallback) {
        serialCallbackQueue.async { [weak self] in
            self?.listeners[identifier] = callback
        }
    }

    public func removeListener(identifier: String) {
        serialCallbackQueue.async { [weak self] in
            guard let self = self else {
                return
            }

            self.listeners.removeValue(forKey: identifier)

            if self.listeners.isEmpty {
                AppSyncLogger.debug("All listeners removed, disconnecting")
                self.serialConnectionQueue.async { [weak self] in
                    guard let self = self else {
                        return
                    }
                    self.status = .notConnected
                    self.disconnect()
                }
            }
        }
    }

    // MARK: -
    func sendConnectionInitMessage() {
        let message = AppSyncMessage(type: .connectionInit("connection_init"))
        write(message)
    }

    func updateCallback(event: ConnectionProviderEvent) {
        serialCallbackQueue.async { [weak self] in
            self?.listeners.values.forEach { $0(event) }
        }
    }

    func receivedConnectionInit() {
        serialConnectionQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.status = .notConnected
            self.updateCallback(event: .error(ConnectionProviderError.connection))
        }
    }
}
