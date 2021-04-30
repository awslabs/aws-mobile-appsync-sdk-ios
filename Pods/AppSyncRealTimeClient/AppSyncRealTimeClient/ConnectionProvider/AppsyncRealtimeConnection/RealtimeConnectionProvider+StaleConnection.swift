//
// Copyright 2018-2021 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension RealtimeConnectionProvider {

    /// Start a stale connection timer, first invalidating and destroying any existing timer
    func startStaleConnectionTimer() {
        AppSyncLogger.debug("[RealtimeConnectionProvider] Starting stale connection timer for \(staleConnectionTimeout.get())s")
        if staleConnectionTimer != nil {
            stopStaleConnectionTimer()
        }
        staleConnectionTimer = CountdownTimer(interval: staleConnectionTimeout.get()) {
            self.disconnectStaleConnection()
        }
    }

    /// Stop and destroy any existing stale connection timer
    func stopStaleConnectionTimer() {
        AppSyncLogger.debug("[RealtimeConnectionProvider] Stopping and destroying stale connection timer")
        staleConnectionTimer?.invalidate()
        staleConnectionTimer = nil
    }

    /// Reset the stale connection timer in response to receiving a message
    func resetStaleConnectionTimer() {
        AppSyncLogger.debug("[RealtimeConnectionProvider] Resetting stale connection timer")
        staleConnectionTimer?.resetCountdown()
    }

    /// Fired when the stale connection timer expires
    private func disconnectStaleConnection() {
        connectionQueue.async {[weak self] in
            guard let self = self else {
                return
            }
            AppSyncLogger.error("[RealtimeConnectionProvider] Realtime connection is stale, disconnecting.")
            self.status = .notConnected
            self.websocket.disconnect()
            self.updateCallback(event: .error(ConnectionProviderError.connection))
        }
    }

}
