//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

final class AppSyncLog {
    class func verbose(_ message: @autoclosure () -> String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, flag: .verbose, file: file, function: function, line: line)
    }
    
    class func debug(_ message: @autoclosure () -> String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, flag: .debug, file: file, function: function, line: line)
    }
    
    class func info(_ message: @autoclosure () -> String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, flag: .info, file: file, function: function, line: line)
    }
    
    class func warn(_ message: @autoclosure () -> String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, flag: .warning, file: file, function: function, line: line)
    }
    
    class func error(_ message: @autoclosure () -> String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, flag: .error, file: file, function: function, line: line)
    }

    class func error(_ error: Error, file: String = #file, function: String = #function, line: Int = #line) {
        log(error.localizedDescription, flag: .error, file: file, function: function, line: line)
    }

    private class func log(_ message: @autoclosure () -> String, flag: AWSDDLogFlag, file: String, function: String, line: Int) {
        if AppSyncLogHelper.shouldLog(flag: flag) {
            AppSyncLogHelper.log(message(),
                                 flag: flag,
                                 file: file,
                                 function: function,
                                 line: UInt(line))
        }
    }

}
