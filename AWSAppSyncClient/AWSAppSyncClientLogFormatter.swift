//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

public final class AWSAppSyncClientLogFormatter: NSObject, AWSDDLogFormatter {

    static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        // 2019-02-27 15:09:34.624-0800
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSZ"
        return dateFormatter
    }()

    public func format(message logMessage: AWSDDLogMessage) -> String? {
        let logLevelPrefix: String
        switch logMessage.flag {
        case .error:
            logLevelPrefix = "E"
        case .warning:
            logLevelPrefix = "W"
        case .info:
            logLevelPrefix = "I"
        case .debug:
            logLevelPrefix = "D"
        default:
            logLevelPrefix = "V"
        }

        let date = AWSAppSyncClientLogFormatter.dateFormatter.string(from: logMessage.timestamp)
        let file = AWSDDExtractFileNameWithoutExtension(logMessage.file, false) ?? "(no file)"
        let line = String(describing: logMessage.line)

        var sourceSection = file
        if let function = logMessage.function {
            sourceSection += ".\(function)"
        }
        sourceSection += ", L\(line)"

        let message = "\(date) [\(logLevelPrefix) \(sourceSection)] \(logMessage.message)"
        return message
    }

}
