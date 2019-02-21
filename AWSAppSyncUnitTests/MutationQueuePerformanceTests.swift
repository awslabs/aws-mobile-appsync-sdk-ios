//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import XCTest
@testable import AWSAppSync
@testable import AWSAppSyncTestCommon

class MutationQueuePerformanceTests: XCTestCase {
    var cacheConfiguration: AWSAppSyncCacheConfiguration!

    // Setting this up as a concurrent queue for maximum throughput on the result side--we're interested in measuring
    // the performance of the enqueue & perform side up through invocation of the handler
    let mutationHandlerQueue = DispatchQueue(label: "com.amazonaws.MutationQueuePerformanceTests",
                                             attributes: .concurrent)

    override func setUp() {
        let tempDir = FileManager.default.temporaryDirectory
        let rootDirectory = tempDir.appendingPathComponent("MutationQueuePerformanceTests-\(UUID().uuidString)")
        cacheConfiguration = try! AWSAppSyncCacheConfiguration(withRootDirectory: rootDirectory)
    }

    override func tearDown() {
        MockReachabilityProvidingFactory.clearShared()
        NetworkReachabilityNotifier.clearShared()
    }

    func test50ConcurrentlyPerformedMutationsWithBackingDatabase() throws {
        try doMutationQueuePerformanceTest(numberOfMutations: 50,
                                           performConcurrently: true,
                                           cacheConfiguration: cacheConfiguration)
    }

    func test50SeriallyPerformedMutationsWithBackingDatabase() throws {
        try doMutationQueuePerformanceTest(numberOfMutations: 50,
                                           performConcurrently: false,
                                           cacheConfiguration: cacheConfiguration)
    }

    func test100ConcurrentlyPerformedMutationsWithBackingDatabase() throws {
        try doMutationQueuePerformanceTest(numberOfMutations: 100,
                                           performConcurrently: true,
                                           cacheConfiguration: cacheConfiguration)
    }

    func test100SeriallyPerformedMutationsWithBackingDatabase() throws {
        try doMutationQueuePerformanceTest(numberOfMutations: 100,
                                           performConcurrently: false,
                                           cacheConfiguration: cacheConfiguration)
    }

    func test500ConcurrentlyPerformedMutationsWithBackingDatabase() throws {
        try doMutationQueuePerformanceTest(numberOfMutations: 500,
                                           performConcurrently: true,
                                           cacheConfiguration: cacheConfiguration)
    }

    func test500SeriallyPerformedMutationsWithBackingDatabase() throws {
        try doMutationQueuePerformanceTest(numberOfMutations: 500,
                                           performConcurrently: false,
                                           cacheConfiguration: cacheConfiguration)
    }

    func test1000ConcurrentlyPerformedMutationsWithBackingDatabase() throws {
        try doMutationQueuePerformanceTest(numberOfMutations: 1000,
                                           performConcurrently: true,
                                           cacheConfiguration: cacheConfiguration)
    }

    func test1000SeriallyPerformedMutationsWithBackingDatabase() throws {
        try doMutationQueuePerformanceTest(numberOfMutations: 1000,
                                           performConcurrently: false,
                                           cacheConfiguration: cacheConfiguration)
    }

    func test50ConcurrentlyPerformedMutationsWithoutBackingDatabase() throws {
        try doMutationQueuePerformanceTest(numberOfMutations: 50,
                                           performConcurrently: true,
                                           cacheConfiguration: nil)
    }

    func test50SeriallyPerformedMutationsWithoutBackingDatabase() throws {
        try doMutationQueuePerformanceTest(numberOfMutations: 50,
                                           performConcurrently: false,
                                           cacheConfiguration: nil)
    }

    func test100ConcurrentlyPerformedMutationsWithoutBackingDatabase() throws {
        try doMutationQueuePerformanceTest(numberOfMutations: 100,
                                           performConcurrently: true,
                                           cacheConfiguration: nil)
    }

    func test100SeriallyPerformedMutationsWithoutBackingDatabase() throws {
        try doMutationQueuePerformanceTest(numberOfMutations: 100,
                                           performConcurrently: false,
                                           cacheConfiguration: nil)
    }

    func test500ConcurrentlyPerformedMutationsWithoutBackingDatabase() throws {
        try doMutationQueuePerformanceTest(numberOfMutations: 500,
                                           performConcurrently: true,
                                           cacheConfiguration: nil)
    }

    func test500SeriallyPerformedMutationsWithoutBackingDatabase() throws {
        try doMutationQueuePerformanceTest(numberOfMutations: 500,
                                           performConcurrently: false,
                                           cacheConfiguration: nil)
    }

    func test1000ConcurrentlyPerformedMutationsWithoutBackingDatabase() throws {
        try doMutationQueuePerformanceTest(numberOfMutations: 1000,
                                           performConcurrently: true,
                                           cacheConfiguration: nil)
    }

    func test1000SeriallyPerformedMutationsWithoutBackingDatabase() throws {
        try doMutationQueuePerformanceTest(numberOfMutations: 1000,
                                           performConcurrently: false,
                                           cacheConfiguration: nil)
    }

    // MARK: - Utility methods
    func doMutationQueuePerformanceTest(numberOfMutations: Int,
                                        performConcurrently: Bool,
                                        cacheConfiguration: AWSAppSyncCacheConfiguration?) throws {
        let mockHTTPTransport = MockAWSNetworkTransport()
        mockHTTPTransport.sendOperationHandlerResponseBody = makeTestMutationWithoutParametersResponseBody(withValue: true)

        let appSyncClient = try UnitTestHelpers.makeAppSyncClient(using: mockHTTPTransport,
                                                                  cacheConfiguration: cacheConfiguration)

        let operationQueue = OperationQueue()
        operationQueue.name = "Perform mutations"

        operationQueue.maxConcurrentOperationCount =
            performConcurrently
            ? OperationQueue.defaultMaxConcurrentOperationCount
            : 1

        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            operationQueue.isSuspended = true

            for _ in 0 ..< numberOfMutations {
                let mutation = TestMutationWithoutParametersMutation()

                operationQueue.addOperation {
                    let semaphore = DispatchSemaphore(value: numberOfMutations)
                    appSyncClient.perform(mutation: mutation, queue: self.mutationHandlerQueue) { _, _ in
                        semaphore.signal()
                    }
                    let _ = semaphore.wait(timeout: DispatchTime.now() + .seconds(60))
                }
            }

            // Sanity check
            XCTAssertEqual(operationQueue.operationCount, numberOfMutations)

            startMeasuring()
            operationQueue.isSuspended = false
            operationQueue.waitUntilAllOperationsAreFinished()

            // Sanity check
            XCTAssertEqual(operationQueue.operationCount, 0)
        }
    }

    func makeTestMutationWithoutParametersResponseBody(withValue value: Bool) -> JSONObject {
        return ["data": ["testMutationWithoutParameters": value]]
    }

}
