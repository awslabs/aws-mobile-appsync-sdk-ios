//
// Copyright 2010-2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
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
