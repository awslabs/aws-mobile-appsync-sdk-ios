//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

/// Appsync Real time connection that connects to subscriptions
/// through websocket.
class RealtimeConnectionProvider: ConnectionProvider {

    let url: URL
    var status: ConnectionState = .notConnected
    let websocket: AppSyncWebsocketProvider
    var listeners: [String: ConnectionProviderCallback] = [:]
    var messageInterceptors: [MessageInterceptor] = []
    var connectionInterceptors: [ConnectionInterceptor] = []

    var staleConnectionTimeout = DispatchTimeInterval.seconds(5 * 60)
    var lastKeepAliveTime = DispatchTime.now()

    /// Serial queue for websocket connection.
    ///
    /// Each connection request will be send to this queue. Connection request are handled one at a time.
    let serialConnectionQueue = DispatchQueue(label: "com.amazonaws.AppSyncRealTimeConnectionProvider.serialQueue")

    let serialCallbackQueue = DispatchQueue(label: "com.amazonaws.AppSyncRealTimeConnectionProvider.callbackQueue")

    init (for url: URL, websocket: AppSyncWebsocketProvider) {
        self.url = url
        self.websocket = websocket
    }

    // MARK: - ConnectionProvider methods

    func connect() {
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
                self.websocket.connect(url: signedRequest.url,
                                       protocols: ["graphql-ws"],
                                       delegate: self)
            }
        }
    }

    func write(_ message: AppSyncMessage) {
        let signedMessage = interceptMessage(message, for: url)
        let jsonEncoder = JSONEncoder()
        do {
            let jsonData = try jsonEncoder.encode(signedMessage)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                updateCallback(event: .error(ConnectionProviderError.jsonParse(message.id, nil)))
                return
            }
            self.websocket.write(message: jsonString)
        } catch {
            AppSyncLog.error(error)
            switch message.messageType {
            case .connectionInit:
                serialConnectionQueue.async {[weak self] in
                    guard let self = self else {
                        return
                    }
                    self.status = .notConnected
                    self.updateCallback(event: .error(ConnectionProviderError.connection))
                }
            default:
                updateCallback(event: .error(ConnectionProviderError.jsonParse(message.id, error)))
            }
        }
    }

    func disconnect() {
        self.websocket.disconnect()
    }

    func addListener(identifier: String, callback: @escaping ConnectionProviderCallback) {
        serialCallbackQueue.async {
            self.listeners[identifier] = callback
        }

    }

    func removeListener(identifier: String) {
        serialCallbackQueue.async {
            self.listeners.removeValue(forKey: identifier)
        }
    }

    // MARK: -
    func sendConnectionInitMessage() {
        let message = AppSyncMessage(type: .connectionInit("connection_init"))
        self.write(message)
    }

    func updateCallback(event: ConnectionProviderEvent) {
        serialCallbackQueue.async { [weak self] in
            self?.listeners.values.forEach { $0(event) }
        }
    }
}
