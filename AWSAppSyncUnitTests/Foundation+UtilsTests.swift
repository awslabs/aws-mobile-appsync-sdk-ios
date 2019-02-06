//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import XCTest
@testable import AWSAppSync

class Foundation_UtilsTests: XCTestCase {

    func test_isEmpty_extensionPlaysNicelyWithStandardLib_Array() {
        let notEmpty: [String] = ["Foo"]
        XCTAssertFalse(notEmpty.isEmpty)

        let empty: [String] = []
        XCTAssert(empty.isEmpty)
    }

    func test_isEmpty_extensionPlaysNicelyWithStandardLib_Dict() {
        let notEmpty: [String: Int] = ["Foo": 1]
        XCTAssertFalse(notEmpty.isEmpty)

        let empty: [String: Int] = [:]
        XCTAssert(empty.isEmpty)
    }

    func test_isEmpty_String() {
        let notEmpty: String = "Foo"
        XCTAssertFalse(notEmpty.isEmpty)

        let empty: String = ""
        XCTAssert(empty.isEmpty)

        let notEmptyOptional: String? = "Foo"
        XCTAssertFalse(notEmptyOptional.isEmpty)

        let emptyOptional: String? = ""
        XCTAssert(emptyOptional.isEmpty)

        let nilOptional: String? = nil
        XCTAssert(nilOptional.isEmpty)
    }

    func test_isEmpty_Array() {
        let notEmpty: [String] = ["Foo"]
        XCTAssertFalse(notEmpty.isEmpty)

        let empty: [String] = []
        XCTAssert(empty.isEmpty)

        let notEmptyOptional: [String]? = ["Foo"]
        XCTAssertFalse(notEmptyOptional.isEmpty)

        let emptyOptional: [String]? = []
        XCTAssert(emptyOptional.isEmpty)

        let nilOptional: [String]? = nil
        XCTAssert(nilOptional.isEmpty)
    }

    func test_isEmpty_Dict() {
        let notEmpty: [String: Int] = ["Foo": 1]
        XCTAssertFalse(notEmpty.isEmpty)

        let empty: [String: Int] = [:]
        XCTAssert(empty.isEmpty)

        let notEmptyOptional: [String: Int]? = ["Foo": 1]
        XCTAssertFalse(notEmptyOptional.isEmpty)

        let emptyOptional: [String: Int]? = [:]
        XCTAssert(emptyOptional.isEmpty)

        let nilOptional: [String: Int]? = nil
        XCTAssert(nilOptional.isEmpty)
    }

}
