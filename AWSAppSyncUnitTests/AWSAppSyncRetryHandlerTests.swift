//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import XCTest
@testable import AWSAppSync

class AWSAppSyncRetryHandlerTests: XCTestCase {

    // This exists only to ensure we have coverage of all AWSAppSyncClientError cases. If it fails to compile, add a case to
    // this test's `switch` statement, and add case-specific tests below
    func testSuiteKnowsAboutAllErrorCases() {
        let nilError: AWSAppSyncClientError? = nil
        guard let error = nilError else {
            return
        }

        switch error {
        case .authenticationError(_): break
        case .noData(_): break
        case .parseError(_, _, _): break
        case .requestFailed(_, _, _): break
        }

        XCTAssert(true)
    }

    // MARK: - Error-case specific tests

    func test_doesNotRetry_authenticationError() {
        let retryHandler = AWSAppSyncRetryHandler()
        let error = AWSAppSyncClientError.authenticationError("Error")
        let retryAdvice = retryHandler.shouldRetryRequest(for: error)
        XCTAssertFalse(retryAdvice.shouldRetry)
    }

    func test_doesRetry_noData() {
        let retryHandler = AWSAppSyncRetryHandler()
        let httpResponse = HTTPURLResponse(url: URL(string: "http://www.amazon.com")!,
                                           statusCode: 500,
                                           httpVersion: "1.1",
                                           headerFields: [:])!
        let error = AWSAppSyncClientError.noData(httpResponse)
        let retryAdvice = retryHandler.shouldRetryRequest(for: error)
        XCTAssert(retryAdvice.shouldRetry)
    }

    func test_doesRetry_parseError() {
        let retryHandler = AWSAppSyncRetryHandler()
        let httpResponse = HTTPURLResponse(url: URL(string: "http://www.amazon.com")!,
                                           statusCode: 500,
                                           httpVersion: "1.1",
                                           headerFields: [:])!
        let data = Data(bytes: [])
        let error = AWSAppSyncClientError.parseError(data, httpResponse, nil)
        let retryAdvice = retryHandler.shouldRetryRequest(for: error)
        XCTAssert(retryAdvice.shouldRetry)
    }

    func test_doesNotRetry_requestFailed_noResponse() {
        let retryHandler = AWSAppSyncRetryHandler()
        let error = AWSAppSyncClientError.requestFailed(nil, nil, nil)
        let retryAdvice = retryHandler.shouldRetryRequest(for: error)
        XCTAssertFalse(retryAdvice.shouldRetry)
    }

    func test_doesRetry_requestFailed_withResponse() {
        let retryHandler = AWSAppSyncRetryHandler()
        let httpResponse = HTTPURLResponse(url: URL(string: "http://www.amazon.com")!,
                                           statusCode: 500,
                                           httpVersion: "1.1",
                                           headerFields: [:])
        let error = AWSAppSyncClientError.requestFailed(nil, httpResponse, nil)
        let retryAdvice = retryHandler.shouldRetryRequest(for: error)
        XCTAssert(retryAdvice.shouldRetry)
    }

    // MARK: - General tests

    func test_doesNotRetry_statusCode400() {
        let retryHandler = AWSAppSyncRetryHandler()
        let httpResponse = HTTPURLResponse(url: URL(string: "http://www.amazon.com")!,
                                       statusCode: 400,
                                       httpVersion: "1.1",
                                       headerFields: [:])!
        let error = AWSAppSyncClientError.noData(httpResponse)
        let retryAdvice = retryHandler.shouldRetryRequest(for: error)
        XCTAssertFalse(retryAdvice.shouldRetry)
    }

    func test_doesRetry_statusCode429() {
        let retryHandler = AWSAppSyncRetryHandler()
        let httpResponse = HTTPURLResponse(url: URL(string: "http://www.amazon.com")!,
                                           statusCode: 429,
                                           httpVersion: "1.1",
                                           headerFields: [:])!
        let error = AWSAppSyncClientError.noData(httpResponse)
        let retryAdvice = retryHandler.shouldRetryRequest(for: error)
        XCTAssert(retryAdvice.shouldRetry)
    }

    func test_doesRetry_statusCode500() {
        let retryHandler = AWSAppSyncRetryHandler()
        let httpResponse = HTTPURLResponse(url: URL(string: "http://www.amazon.com")!,
                                           statusCode: 500,
                                           httpVersion: "1.1",
                                           headerFields: [:])!
        let error = AWSAppSyncClientError.noData(httpResponse)
        let retryAdvice = retryHandler.shouldRetryRequest(for: error)
        XCTAssert(retryAdvice.shouldRetry)
    }

    func test_respectsRetryAfterHeaderField() {
        let retryHandler = AWSAppSyncRetryHandler()
        let httpResponse = HTTPURLResponse(url: URL(string: "http://www.amazon.com")!,
                                           statusCode: 500,
                                           httpVersion: "1.1",
                                           headerFields: ["Retry-After": "50"])!
        let error = AWSAppSyncClientError.noData(httpResponse)
        let retryAdvice = retryHandler.shouldRetryRequest(for: error)
        XCTAssertEqual(retryAdvice.retryInterval, .seconds(50))
    }

    func test_doesNotRetryUnreasonably() {
        let retryHandler = AWSAppSyncRetryHandler()
        let httpResponse = HTTPURLResponse(url: URL(string: "http://www.amazon.com")!,
                                           statusCode: 500,
                                           httpVersion: "1.1",
                                           headerFields: [:])!
        let error = AWSAppSyncClientError.noData(httpResponse)

        // Initialize this to `true` so we can assert it eventually moves to `false`
        var retryAdvice = AWSAppSyncRetryAdvice(shouldRetry: true, retryInterval: .seconds(0))

        // We'll arbitrarily define "reasonable" as about 50. In practice, it should stop well before this
        for _ in 1 ... 50 {
            retryAdvice = retryHandler.shouldRetryRequest(for: error)
            if (!retryAdvice.shouldRetry) {
                break
            }
            print("retryAdvice: should retry in \(retryAdvice.retryInterval ?? .seconds(-1))")
        }
        XCTAssertFalse(retryAdvice.shouldRetry)
    }
}
