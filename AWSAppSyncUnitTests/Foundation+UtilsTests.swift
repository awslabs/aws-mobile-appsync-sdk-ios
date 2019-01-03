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
