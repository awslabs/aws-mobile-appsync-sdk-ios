//
// Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
import AWSCore

struct AppSyncLogHelper {
    
    public static func shouldLog(flag: AWSDDLogFlag) -> Bool {
        let shouldLog = flag.rawValue & AWSDDLog.sharedInstance.logLevel.rawValue
        return shouldLog != 0
    }
    
    public static func log(_ message: String,
                           flag: AWSDDLogFlag,
                           file: String,
                           function: String,
                           line: UInt) {
        
        AWSDDLog.log(asynchronous: true,
                     level: AWSDDLog.sharedInstance.logLevel,
                     flag: flag,
                     context: 0,
                     file: file.cString(using: .utf8)!,
                     function: function.cString(using: .utf8)!,
                     line: line,
                     tag: nil,
                     format: message,
                     arguments: getVaList([]))
    }
}
