//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

final class AppSyncLog {
    class func verbose(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        AppSyncLogHelper.logVerbose(message, file: file, funcion: function, line: UInt(line))
    }
    
    class func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        AppSyncLogHelper.logVerbose(message, file: file, funcion: function, line: UInt(line))
    }
    
    class func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        AppSyncLogHelper.logVerbose(message, file: file, funcion: function, line: UInt(line))
    }
    
    class func warn(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        AppSyncLogHelper.logVerbose(message, file: file, funcion: function, line: UInt(line))
    }
    
    class func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        AppSyncLogHelper.logVerbose(message, file: file, funcion: function, line: UInt(line))
    }
}
