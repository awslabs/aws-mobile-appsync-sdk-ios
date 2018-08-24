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

import Foundation

/// Protocol to be implemented by Log Providers.
public protocol AWSLogProvider {
    
    /// Verbose Logging
    func verbose(_ message: @autoclosure () -> Any, _ file: String, _ function: String, _ line: Int)
    
    /// Debug Logging
    func debug(_ message: @autoclosure () -> Any, _ file: String, _ function: String, _ line: Int)
    
    /// Info Logging
    func info(_ message: @autoclosure () -> Any, _ file: String, _ function: String, _ line: Int)
    
    /// Warning Logging
    func warning(_ message: @autoclosure () -> Any, _ file: String, _ function: String, _ line: Int)
    
    /// Error Logging
    func error(_ message: @autoclosure () -> Any, _ file: String, _ function: String, _ line: Int)
}

/// The default logging provider for AWS AppSync SDK
public class AWSAppSyncDefaultLogProvider: AWSLogProvider {
    
    var logLevel: AWSDefaultLogProviderLogLevel
    var dispatchQueue: DispatchQueue = DispatchQueue(label: "AWSAppSyncDefaultLogProvider" + NSUUID().uuidString, qos: DispatchQoS.default)
    var messagesOutput: [String] = []
    var enableMessageOutputList = false
    
    /// Initializer for `AWSDefaultLogProvider`. Provider a `logLevel` as required.
    public init(logLevel: AWSDefaultLogProviderLogLevel) {
        self.logLevel = logLevel
    }
    
    // Log levels for `AWSDefaultLogProvider`
    public enum AWSDefaultLogProviderLogLevel: Int {
        case verbose = 50
        case debug = 40
        case info = 30
        case warning = 20
        case error = 10
        case none = 0
    }
    
    /// Set the log level to desired level
    public func setLogLevel(logLevel: AWSDefaultLogProviderLogLevel) {
        self.logLevel = logLevel
    }
    
   
    /// Verbose Logging
    public func verbose(_ message: @autoclosure () -> Any, _ file: String, _ function: String, _ line: Int) {
        guard logLevel.rawValue >= AWSDefaultLogProviderLogLevel.verbose.rawValue else {
            return
        }
        logMessage("⚡️VERBOSE", message, file, function, line)
    }
    
    /// Debug Logging
    public func debug(_ message: @autoclosure () -> Any, _ file: String, _ function: String, _ line: Int) {
        guard logLevel.rawValue >= AWSDefaultLogProviderLogLevel.debug.rawValue else {
            return
        }
        logMessage("✏️DEBUG", message, file, function, line)
    }
    
    /// Info Logging
    public func info(_ message: @autoclosure () -> Any, _ file: String, _ function: String, _ line: Int) {
        guard logLevel.rawValue >= AWSDefaultLogProviderLogLevel.info.rawValue else {
            return
        }
        logMessage("ℹ️INFO", message, file, function, line)
    }
    
    /// Warning Logging
    public func warning(_ message: @autoclosure () -> Any, _ file: String, _ function: String, _ line: Int) {
        guard logLevel.rawValue >= AWSDefaultLogProviderLogLevel.warning.rawValue else {
            return
        }
        logMessage("⚠️WARNING", message, file, function, line)
    }
    
    /// Error Logging
    public func error(_ message: @autoclosure () -> Any, _ file: String, _ function: String, _ line: Int) {
        guard logLevel.rawValue >= AWSDefaultLogProviderLogLevel.error.rawValue else {
            return
        }
        logMessage("❗️ERROR", message, file, function, line)
    }
    
    func logMessage(_ logType: String, _ message: @autoclosure () -> Any, _ file: String, _ function: String, _ line: Int) {
        guard let msg = message() as? String else {
            return
        }
        dispatchQueue.async {
            print("\(Date()) \(logType): \(file.components(separatedBy: "/").last!) | \(function) | \(line) | \(msg)")
        }
        // for debugging and testing
        if (enableMessageOutputList) {
            messagesOutput.append(msg)
        }
    }
}

/// The logging client for AWS AppSync SDK
public class AWSAppSyncLogClient {
    
    static var sharedLoggingClient = AWSAppSyncLogClient()
  
    static public func setSharedLoggingClient(loggingClient:AWSAppSyncLogClient ) {
        AWSAppSyncLogClient.sharedLoggingClient = loggingClient
    }
    
    var logProvider: AWSLogProvider?
    
    public init() {
        logProvider = AWSAppSyncDefaultLogProvider(logLevel: .error)
    }
    
    public func setLoggingProvider(provider: AWSLogProvider) {
        logProvider = provider
    }
    
    /// Verbose Logging
    public func verbose(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        logProvider?.verbose(message, file, function, line)
    }
    
    /// Debug Logging
    public func debug(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        logProvider?.debug(message, file, function, line)
    }
    
    /// Info Logging
    public func info(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        logProvider?.info(message, file, function, line)
    }
    
    /// Warning Logging
    public func warning(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        logProvider?.warning(message, file, function, line)
    }
    
    /// Error Logging
    public func error(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        logProvider?.error(message, file, function, line)
    }
}
