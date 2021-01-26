//
// Copyright 2018-2021 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Appsync Real time connection that connects to subscriptions
/// through websocket.
public class RealtimeConnectionProvider: ConnectionProvider {
    private let url: URL
    private var listeners: [String: ConnectionProviderCallback]

    let websocket: AppSyncWebsocketProvider

    var status: ConnectionState
    var messageInterceptors: [MessageInterceptor]
    var connectionInterceptors: [ConnectionInterceptor]

    /// Maximum number of seconds a connection may go without receiving a keep alive
    /// message before we consider it stale and force a disconnect
    let staleConnectionTimeout: AtomicValue<TimeInterval>

    /// A timer that automatically disconnects the current connection if it goes longer
    /// than `staleConnectionTimeout` without activity. Receiving any data or "keep
    /// alive" message will cause the timer to be reset to the full interval.
    var staleConnectionTimer: CountdownTimer?

    /// Manages concurrency for socket connections, disconnections, writes, and status reports.
    ///
    /// Each connection request will be sent to this queue. Connection request are
    /// handled one at a time.
    let connectionQueue: DispatchQueue

    /// The serial queue on which status & message callbacks from the web socket are invoked.
    private let serialCallbackQueue = DispatchQueue(
        label: "com.amazonaws.AppSyncRealTimeConnectionProvider.callbackQueue"
    )

    public init(for url: URL, websocket: AppSyncWebsocketProvider) {
        self.url = url
        self.websocket = websocket

        self.listeners = [:]
        self.status = .notConnected
        self.messageInterceptors = []
        self.connectionInterceptors = []
        self.staleConnectionTimeout = AtomicValue(initialValue: 5 * 60)
        self.connectionQueue = DispatchQueue(
            label: "com.amazonaws.AppSyncRealTimeConnectionProvider.serialQueue"
        )
    }

    // MARK: - ConnectionProvider methods

    public func connect() {
        connectionQueue.async { [weak self] in
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

        connectionQueue.async { [weak self] in
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
        connectionQueue.async {
            self.websocket.disconnect()
            self.staleConnectionTimer?.invalidate()
            self.staleConnectionTimer = nil
        }
    }

    public func addListener(identifier: String, callback: @escaping ConnectionProviderCallback) {
        connectionQueue.async { [weak self] in
            self?.listeners[identifier] = callback
        }
    }

    public func removeListener(identifier: String) {
        connectionQueue.async { [weak self] in
            guard let self = self else {
                return
            }

            self.listeners.removeValue(forKey: identifier)

            if self.listeners.isEmpty {
                AppSyncLogger.debug("All listeners removed, disconnecting")
                self.status = .notConnected
                self.disconnect()
            }
        }
    }

    // MARK: -
    func sendConnectionInitMessage() {
        let message = AppSyncMessage(type: .connectionInit("connection_init"))
        write(message)
    }

    /// Invokes all registered listeners with `event`. The event is dispatched on `serialCallbackQueue`,
    /// but internally this method uses the connectionQueue to get the currently registered listeners.
    ///
    /// - Parameter event: The connection event to dispatch
    func updateCallback(event: ConnectionProviderEvent) {
        connectionQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            let allListeners = Array(self.listeners.values)
            self.serialCallbackQueue.async {
                allListeners.forEach { $0(event) }
            }
        }
    }

    /// - Warning: This must be invoked from the `connectionQueue`
    private func receivedConnectionInit() {
        status = .notConnected
        updateCallback(event: .error(ConnectionProviderError.connection))
    }
}
