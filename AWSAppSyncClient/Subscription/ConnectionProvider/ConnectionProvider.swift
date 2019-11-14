//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

protocol ConnectionProvider: class {

    func connect()

    func write(_ message: AppSyncMessage)

    func disconnect()

    func addListener(identifier: String, callback: @escaping ConnectionProviderCallback)

    func removeListener(identifier: String)
}

typealias ConnectionProviderCallback = (ConnectionProviderEvent) -> Void

enum ConnectionProviderEvent {

    case connection(ConnectionState)

    case data(AppSyncResponse)

    case error(Error)
}

/// Connection states
enum ConnectionState {

    case notConnected

    case inProgress

    case connected
}
