//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

extension RealtimeConnectionProvider {

    /// Check if the we got a keep alive message within the given timeout window.
    /// If we did not get the keepalive, disconnect the connection and return an error.
    func disconnectIfStale() {

        // Validate the connection only when it is connected or inprogress state.
        guard status != .notConnected else {
            return
        }
        AppSyncLog.verbose("Validating connection")
        let staleThreshold = lastKeepAliveTime + staleConnectionTimeout
        let currentTime = DispatchTime.now()
        if staleThreshold < currentTime {

            serialConnectionQueue.async {[weak self] in
                guard let self = self else {
                    return
                }
                self.status = .notConnected
                self.websocket.disconnect()
                AppSyncLog.error("Realtime connection is stale, disconnected.")
                self.updateCallback(event: .error(ConnectionProviderError.connection))
            }

        } else {
            DispatchQueue.global().asyncAfter(deadline: currentTime + staleConnectionTimeout) { [weak self] in
                self?.disconnectIfStale()
            }
        }

    }
}
