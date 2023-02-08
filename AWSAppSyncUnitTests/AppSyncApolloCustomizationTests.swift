//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
import XCTest
@testable import AWSAppSync

class AppSyncApolloCustomizationTests: XCTestCase {

    func testRecordSetConformsToCustomPlaygroundDisplayConvertible() {
        // Note: this line will generate a compiler warning, but we're using it as documentation to ensure no regressions in our
        // forked Apollo code
        let conformedRecordSet = RecordSet(records: [])
        XCTAssertNotNil(conformedRecordSet)
    }
}
