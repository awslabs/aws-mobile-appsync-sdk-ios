//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public enum AppSyncRealTimeClient {

    static let lock: NSLocking = NSLock()

    static var _logLevel = LogLevel.error // swiftlint:disable:this identifier_name

    public static var logLevel: LogLevel {
        get {
            lock.lock()
            defer {
                lock.unlock()
            }

            return _logLevel
        }
        set {
            lock.lock()
            defer {
                lock.unlock()
            }

            _logLevel = newValue
        }
    }
}

public extension AppSyncRealTimeClient {
    enum LogLevel: Int {
        case error
        case warn
        case info
        case debug
        case verbose
    }
}
