//
// Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import XCTest
@testable import AWSAppSync
import AWSCore

class AppSyncLogHelperTests: XCTestCase {

    func testShouldLogTrueResult() {
        AWSDDLog.sharedInstance.logLevel = .warning
        let result = AppSyncLogHelper.shouldLog(flag: .warning)
        XCTAssertTrue(result)
    }
    
    func testShouldLogFalseResult() {
        AWSDDLog.sharedInstance.logLevel = .info
        let result = AppSyncLogHelper.shouldLog(flag: .warning)
        XCTAssertTrue(result)
    }
    
    func testLoggingInfo() {
        let mockedLogger = MockLogger()
        AWSDDLog.sharedInstance.logLevel = .info
        AWSDDLog.sharedInstance.add(mockedLogger)
        AppSyncLog.info("Hi there")
        // Logging happens in an async queue, so wait a second for
        // logging to happen
        sleep(1)
        XCTAssertEqual(mockedLogger.loggedMessage, "Hi there")
    }
    
    func testLoggingFail() {
        let mockedLogger = MockLogger()
        AWSDDLog.sharedInstance.logLevel = .info
        AWSDDLog.sharedInstance.add(mockedLogger)
        AppSyncLog.debug("Hi there")
        // Logging happens in an async queue, so wait a second for
        // logging to happen
        sleep(1)
        XCTAssertEqual(mockedLogger.loggedMessage, "")
    }
}

class MockLogger: NSObject, AWSDDLogger {
    var loggedMessage = ""
    
    var logFormatter: AWSDDLogFormatter? = AWSAppSyncClientLogFormatter()
    
    func log(message logMessage: AWSDDLogMessage) {
        loggedMessage = logMessage.message
    }
}
