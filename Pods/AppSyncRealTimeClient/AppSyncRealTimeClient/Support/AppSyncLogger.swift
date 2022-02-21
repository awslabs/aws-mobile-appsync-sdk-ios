//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import os

struct AppSyncLogger {

    static var logLevel: AppSyncRealTimeClient.LogLevel {
        AppSyncRealTimeClient.logLevel
    }

    static func error(_ log: String) {
        // Always logged, no conditional check needed
        if #available(iOS 10.0, *) {
            os_log("%@", type: .error, log)
        } else {
            NSLog("%@", log)
        }
    }

    static func error(_ error: Error) {
        if #available(iOS 10.0, *) {
            os_log("%@", type: .error, error.localizedDescription)
        } else {
            NSLog("%@", error.localizedDescription)
        }
    }

    static func warn(_ log: String) {
        guard logLevel.rawValue >= AppSyncRealTimeClient.LogLevel.warn.rawValue else {
            return
        }

        if #available(iOS 10.0, *) {
            os_log("%@", type: .info, log)
        } else {
            NSLog("%@", log)
        }
    }

    static func info(_ log: String) {
        guard logLevel.rawValue >= AppSyncRealTimeClient.LogLevel.info.rawValue else {
            return
        }

        if #available(iOS 10.0, *) {
            os_log("%@", type: .info, log)
        } else {
            NSLog("%@", log)
        }
    }

    static func debug(_ log: String) {
        guard logLevel.rawValue >= AppSyncRealTimeClient.LogLevel.debug.rawValue else {
            return
        }

        if #available(iOS 10.0, *) {
            os_log("%@", type: .debug, log)
        } else {
            NSLog("%@", log)
        }
    }

    static func verbose(_ log: String) {
        guard logLevel.rawValue >= AppSyncRealTimeClient.LogLevel.verbose.rawValue else {
            return
        }

        if #available(iOS 10.0, *) {
            os_log("%@", type: .debug, log)
        } else {
            NSLog("%@", log)
        }
    }
}
