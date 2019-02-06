//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

public struct AppSyncConnectionInfo {
    public let isConnectionAvailable: Bool
    public let isInitialConnection: Bool
}

public enum ClientNetworkAccessState {
    case Online
    case Offline
}

public protocol ConnectionStateChangeHandler {
    func stateChanged(networkState: ClientNetworkAccessState)
}
