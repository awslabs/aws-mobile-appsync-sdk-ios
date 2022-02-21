//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Consolidates usage and parameters passed to the `staleConnectionTimer` methods.
extension RealtimeConnectionProvider {

    /// Start a stale connection timer, first invalidating and destroying any existing timer
    func startStaleConnectionTimer() {
        AppSyncLogger.debug("[RealtimeConnectionProvider] Starting stale connection timer for \(staleConnectionTimer.interval)s")

        staleConnectionTimer.start(interval: RealtimeConnectionProvider.staleConnectionTimeout) {
            self.disconnectStaleConnection()
        }
    }

    /// Reset the stale connection timer in response to receiving a message from the websocket
    func resetStaleConnectionTimer(interval: TimeInterval? = nil) {
        AppSyncLogger.debug("[RealtimeConnectionProvider] Resetting stale connection timer")
        staleConnectionTimer.reset(interval: interval)
    }

    /// Stops the timer when disconnecting the websocket.
    func invalidateStaleConnectionTimer() {
        staleConnectionTimer.invalidate()
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
