//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import XCTest

@testable import AWSAppSync
@testable import AWSAppSyncTestCommon

class MutationQueueTests: XCTestCase {

    var cacheConfiguration: AWSAppSyncCacheConfiguration!

    override func setUp() {
        let tempDir = FileManager.default.temporaryDirectory
        let rootDirectory = tempDir.appendingPathComponent("MutationQueueTests-\(UUID().uuidString)")
        cacheConfiguration = try! AWSAppSyncCacheConfiguration(withRootDirectory: rootDirectory)
    }

    override func tearDown() {
        MockReachabilityProvidingFactory.clearShared()
        NetworkReachabilityNotifier.clearShared()
    }

    func testMutationIsPerformed_WithBackingDatabase() throws {
        let addPost = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation

        let mockHTTPTransport = MockAWSNetworkTransport()
        mockHTTPTransport.sendOperationHandlerResponseBody = UnitTestHelpers.makeAddPostResponseBody(withId: "TestPostID", for: addPost)

        let appSyncClient = try UnitTestHelpers.makeAppSyncClient(using: mockHTTPTransport, cacheConfiguration: AWSAppSyncCacheConfiguration())

        let mutationPerformed = expectation(description: "Post added")
        appSyncClient.perform(mutation: addPost) { result, error in
            XCTAssertEqual(result?.data?.createPostWithoutFileUsingParameters?.id, "TestPostID")
            mutationPerformed.fulfill()
        }

        wait(for: [mutationPerformed], timeout: 1.0)
    }

    func testMutationIsPerformed_WithoutBackingDatabase() throws {
        let addPost = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation

        let mockHTTPTransport = MockAWSNetworkTransport()
        mockHTTPTransport.sendOperationHandlerResponseBody = UnitTestHelpers.makeAddPostResponseBody(withId: "TestPostID", for: addPost)

        let appSyncClient = try UnitTestHelpers.makeAppSyncClient(using: mockHTTPTransport, cacheConfiguration: nil)

        let mutationPerformed = expectation(description: "Post added")
        appSyncClient.perform(mutation: addPost) { result, error in
            XCTAssertEqual(result?.data?.createPostWithoutFileUsingParameters?.id, "TestPostID")
            mutationPerformed.fulfill()
        }

        wait(for: [mutationPerformed], timeout: 1.0)
    }

    // Tests that an appsync client is still released if destroyed while there are in-process operations. NOTE: This does not
    // assert that the operations are cancelled without executing, only that the appsync client is properly released.
    func testAppSyncClientProperlyReleasedIfDestroyedWithInProgressOperations() throws {
        let secondsToWait = 1

        // To test this case, we'll set up a long-running mutation, and ensure that stuck behind it in the queue do not execute
        let addPost = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation
        let mockHTTPTransport = MockAWSNetworkTransport()

        // First add a response block that delays response, to give the expectations a chance to ensure the second one doesn't
        // proceed until the first is done.
        let delayedResponseBody = UnitTestHelpers.makeAddPostResponseBody(withId: "DelayedTestPostID", for: addPost)

        let delayedMutationInvoked = expectation(description: "Delayed mutation invoked")
        let delayedMutationResponseDispatched = expectation(description: "Delayed mutation response dispatched")

        let delayedResponseBlock: SendOperationResponseBlock<CreatePostWithoutFileUsingParametersMutation> = {
            operation, completionHandler in
            delayedMutationInvoked.fulfill()
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .seconds(secondsToWait)) {
                delayedMutationResponseDispatched.fulfill()
                let response = GraphQLResponse(operation: operation, body: delayedResponseBody)
                completionHandler(response, nil)
            }
        }

        mockHTTPTransport.sendOperationResponseQueue.append(delayedResponseBlock)

        let queuedResponseBody = UnitTestHelpers.makeAddPostResponseBody(withId: "QueuedTestPostID", for: addPost)
        mockHTTPTransport.sendOperationResponseQueue.append(queuedResponseBody)

        let appSyncClientReleased = expectation(description: "AppSyncClient was properly released")
        var appSyncClient: DeinitNotifiableAppSyncClient? = try UnitTestHelpers.makeAppSyncClient(using: mockHTTPTransport, cacheConfiguration: nil)
        appSyncClient?.deinitCalled = {
            appSyncClientReleased.fulfill()
        }

        // Based on our `responseBlock` configuration above, we don't expect the result handler to be invoked for about 1.0 sec
        appSyncClient?.perform(mutation: addPost) { _, _ in }

        appSyncClient?.perform(mutation: addPost) { _, _ in }

        wait(for: [delayedMutationInvoked], timeout: 0.5)

        // `send(operation:)` has been invoked, which means the system is set up & processing mutations. It is now safe to
        // destroy the client and assert that operations are cancelled
        appSyncClient = nil

        wait(for: [delayedMutationResponseDispatched, appSyncClientReleased], timeout: Double(secondsToWait) + 1.0)
    }

    func testMutationIsAttemptedIfAddedWhileNoNetwork() throws {
        let reachability = MockReachabilityProvidingFactory.instance
        try reachability.startNotifier()
        reachability.connection = .none

        NetworkReachabilityNotifier.setupShared(
            host: "http://www.amazon.com",
            allowsCellularAccess: true,
            reachabilityFactory: MockReachabilityProvidingFactory.self)

        let addPost = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation
        let mockHTTPTransport = MockAWSNetworkTransport()

        let sendWasInvoked = expectation(description: "HTTPTransport.send was not invoked while host was unreachable")
        let queuedResponseBlock: SendOperationResponseBlock<CreatePostWithoutFileUsingParametersMutation> = { _, _ in
            sendWasInvoked.fulfill()
        }

        mockHTTPTransport.sendOperationResponseQueue.append(queuedResponseBlock)

        let appSyncClient = try UnitTestHelpers.makeAppSyncClient(using: mockHTTPTransport, cacheConfiguration: nil)

        appSyncClient.perform(mutation: addPost) { _, _ in }

        wait(for: [sendWasInvoked], timeout: 0.5)
    }

    func testMutationErrorDeliveredToCompletionHandler() throws {
        let addPost = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation

        let mockHTTPTransport = MockAWSNetworkTransport()
        mockHTTPTransport.sendOperationHandlerResponseBody = UnitTestHelpers.makeAddPostResponseBody(withId: "ErrorPostID", for: addPost)

        // Now that we've set up the responses, we'll add an error to be returned each time the "addPost" mutation gets called
        let addPostError: Error = "AddPostError"
        mockHTTPTransport.sendOperationHandlerError = addPostError

        let appSyncClient = try UnitTestHelpers.makeAppSyncClient(using: mockHTTPTransport, cacheConfiguration: nil)

        // Allow the result handler for the errored mutation to be invoked multiple times since it is retriable
        let attemptedMutationWithError = expectation(description: "Attempted mutation with error")

        appSyncClient.perform(mutation: addPost) { result, error in
            attemptedMutationWithError.fulfill()
            XCTAssertNil(result)
            XCTAssertEqual(error?.localizedDescription, addPostError.localizedDescription)
        }

        wait(for: [attemptedMutationWithError], timeout: 1.0)
    }

    func testQueueProcessesMutationsInOrder() throws {
        let numberOfMutationsToPerform = 50
        let addPost = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation

        let mockHTTPTransport = MockAWSNetworkTransport()

        var mutationPerformedExpectations = [XCTestExpectation]()

        let appSyncClient = try UnitTestHelpers.makeAppSyncClient(using: mockHTTPTransport, cacheConfiguration: nil)

        // After this block, the mockHTTPTransport will have `numberOfMutationsToPerform` blocks to perform, in sequence,
        // to be invoked on subsequent invocations of `send`
        for i in 0 ..< numberOfMutationsToPerform {
            // Note that our ID is simply the string of the index, to make it easy to inspect & assert during fulfillment
            let responseBody = UnitTestHelpers.makeAddPostResponseBody(withId: "\(i)", for: addPost)
            mockHTTPTransport.sendOperationResponseQueue.append(responseBody)
            let mutationPerformed = expectation(description: "Post \(i) added")
            mutationPerformedExpectations.append(mutationPerformed)
        }

        var expectedMutationIndex = 0
        for i in 0 ..< numberOfMutationsToPerform {
            appSyncClient.perform(mutation: addPost) { result, error in
                guard let id = result?.data?.createPostWithoutFileUsingParameters?.id else {
                    XCTFail("Invalid result for mutation \(i): \(String(describing: result))")
                    return
                }

                guard let indexFromId = Int(id) else {
                    XCTFail("Invalid id format for mutation \(i): \(id)")
                    return
                }

                XCTAssertEqual(indexFromId,
                               expectedMutationIndex,
                               "Mutation invoked out of order. expectedMutationIndex=\(expectedMutationIndex); indexFromId=\(indexFromId)")

                mutationPerformedExpectations[indexFromId].fulfill()
                expectedMutationIndex += 1
            }
        }

        wait(for: mutationPerformedExpectations, timeout: 5.0)
    }

    func testQueueProcessesOnlyOneMutationConcurrently() throws {
        let addPost = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation
        let mockHTTPTransport = MockAWSNetworkTransport()

        // First add a response block that delays response, to give the expectations a chance to ensure the second one doesn't
        // proceed until the first is done.
        let delayedResponseBody = UnitTestHelpers.makeAddPostResponseBody(withId: "DelayedTestPostID", for: addPost)

        var delayedMutationHasNotYetBeenPerformed = true

        let delayedMutationInvoked = expectation(description: "Delayed mutation invoked")
        let delayedMutationResponseDispatched = expectation(description: "Delayed mutation response dispatched")

        let delayedResponseBlock: SendOperationResponseBlock<CreatePostWithoutFileUsingParametersMutation> = {
            operation, completionHandler in
            delayedMutationInvoked.fulfill()
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .milliseconds(500)) {
                delayedMutationHasNotYetBeenPerformed = false
                delayedMutationResponseDispatched.fulfill()
                let response = GraphQLResponse(operation: operation, body: delayedResponseBody)
                completionHandler(response, nil)
            }
        }

        mockHTTPTransport.sendOperationResponseQueue.append(delayedResponseBlock)

        // Now set up a response block that asserts it wasn't invoked until after the delayed mutation was completed
        let queuedResponseBody = UnitTestHelpers.makeAddPostResponseBody(withId: "QueuedTestPostID", for: addPost)
        let queuedMutationInvokedPrematurely = expectation(description: "Queued mutation invoked before delayed mutation response was ready")
        queuedMutationInvokedPrematurely.isInverted = true

        let queuedMutationInvokedAtCorrectTime = expectation(description: "Queued mutation invoked after the delayed mutation is complete")

        let queuedResponseBlock: SendOperationResponseBlock<CreatePostWithoutFileUsingParametersMutation> = {
            operation, completionHandler in
            if delayedMutationHasNotYetBeenPerformed {
                queuedMutationInvokedPrematurely.fulfill()
            } else {
                queuedMutationInvokedAtCorrectTime.fulfill()
            }

            DispatchQueue.global().async {
                let response = GraphQLResponse(operation: operation, body: queuedResponseBody)
                completionHandler(response, nil)
            }
        }

        mockHTTPTransport.sendOperationResponseQueue.append(queuedResponseBlock)

        let appSyncClient = try UnitTestHelpers.makeAppSyncClient(using: mockHTTPTransport, cacheConfiguration: nil)

        // Mutation 1 invokes the delayed response block
        appSyncClient.perform(mutation: addPost) { _, _ in }

        // Mutation 2 invokes the block to assert it has not been invoked too early
        appSyncClient.perform(mutation: addPost) { _, _ in }

        wait(for: [delayedMutationInvoked,
                   delayedMutationResponseDispatched,
                   queuedMutationInvokedPrematurely,
                   queuedMutationInvokedAtCorrectTime],
             timeout: 1.0)
    }

    func testQueueResumesWhenNetworkStarts() throws {
        // Queue a mutation that will not be performed because network is not available
        let reachability = MockReachabilityProvidingFactory.instance
        try reachability.startNotifier()
        reachability.connection = .none

        NetworkReachabilityNotifier.setupShared(
            host: "http://www.amazon.com",
            allowsCellularAccess: true,
            reachabilityFactory: MockReachabilityProvidingFactory.self)

        let addPost = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation
        let mockHTTPTransport = MockAWSNetworkTransport()

        // Now set up a response block that asserts it wasn't invoked until after the network state was changed
        var networkStateHasBeenChanged = false
        let queuedResponseBody = UnitTestHelpers.makeAddPostResponseBody(withId: "QueuedTestPostID", for: addPost)
        let queuedMutationInvokedPrematurely = expectation(description: "Queued mutation invoked before network status was changed")
        queuedMutationInvokedPrematurely.isInverted = true

        let queuedMutationInvokedAtCorrectTime = expectation(description: "Queued mutation invoked after network status was changed")

        let queuedResponseBlock: SendOperationResponseBlock<CreatePostWithoutFileUsingParametersMutation> = {
            operation, completionHandler in
            if networkStateHasBeenChanged {
                queuedMutationInvokedAtCorrectTime.fulfill()
            } else {
                queuedMutationInvokedPrematurely.fulfill()
            }

            DispatchQueue.global().async {
                let response = GraphQLResponse(operation: operation, body: queuedResponseBody)
                completionHandler(response, nil)
            }
        }

        mockHTTPTransport.sendOperationResponseQueue.append(queuedResponseBlock)

        let appSyncClient = try UnitTestHelpers.makeAppSyncClient(using: mockHTTPTransport, cacheConfiguration: nil)

        // When this method returns, the mutation will be added to the operation queue, and should be added to the persistent
        // database.
        appSyncClient.perform(mutation: addPost) { _, _ in }

        networkStateHasBeenChanged = true
        reachability.connection = .wifi

        // We now expect send to be invoked, indicating that the queued mutation was read from persistent storage
        wait(for: [queuedMutationInvokedPrematurely, queuedMutationInvokedAtCorrectTime], timeout: 1.0)
    }

    func testQueueResumesWhenNetworkResumes() throws {
        let reachability = MockReachabilityProvidingFactory.instance
        try reachability.startNotifier()
        reachability.connection = .wifi

        NetworkReachabilityNotifier.setupShared(
            host: "http://www.amazon.com",
            allowsCellularAccess: true,
            reachabilityFactory: MockReachabilityProvidingFactory.self)

        let addPost = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation
        let mockHTTPTransport = MockAWSNetworkTransport()

        // Now set up a response block that asserts it wasn't invoked until after the network state was changed
        enum TestNetworkState {
            case initiallyOn
            case disabledByTest
            case reenabledByTest
        }

        var networkState = TestNetworkState.initiallyOn

        let delayingResponseBody = UnitTestHelpers.makeAddPostResponseBody(withId: "DelayingTestPostID", for: addPost)
        let delayingResponseHandlerInvoked = expectation(description: "Delaying response handler invoked")
        let delayingResponseDispatched = expectation(description: "Delaying response dispatched")

        let delayingResponseBlock: SendOperationResponseBlock<CreatePostWithoutFileUsingParametersMutation> = {
            operation, completionHandler in
            delayingResponseHandlerInvoked.fulfill()
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .milliseconds(500)) {
                delayingResponseDispatched.fulfill()
                let response = GraphQLResponse(operation: operation, body: delayingResponseBody)
                completionHandler(response, nil)
            }
        }

        mockHTTPTransport.sendOperationResponseQueue.append(delayingResponseBlock)

        let queuedResponseBody = UnitTestHelpers.makeAddPostResponseBody(withId: "QueuedTestPostID", for: addPost)

        let queuedMutationShouldNotBeInvokedBeforeNetworkStateHasChanged = expectation(description: "Queued mutation incorrectly invoked before network status was changed")
        queuedMutationShouldNotBeInvokedBeforeNetworkStateHasChanged.isInverted = true

        let queuedMutationShouldNotBeInvokedWhenNetworkIsDisabled = expectation(description: "Queued mutation incorrectly invoked network was disabled")
        queuedMutationShouldNotBeInvokedWhenNetworkIsDisabled.isInverted = true

        let queuedMutationInvokedAtCorrectTime = expectation(description: "Queued mutation invoked after network was reenabled")

        let queuedResponseBlock: SendOperationResponseBlock<CreatePostWithoutFileUsingParametersMutation> = {
            operation, completionHandler in

            switch networkState {
            case .initiallyOn:
                queuedMutationShouldNotBeInvokedBeforeNetworkStateHasChanged.fulfill()
            case .disabledByTest:
                queuedMutationShouldNotBeInvokedWhenNetworkIsDisabled.fulfill()
            case .reenabledByTest:
                queuedMutationInvokedAtCorrectTime.fulfill()
            }

            DispatchQueue.global().async {
                let response = GraphQLResponse(operation: operation, body: queuedResponseBody)
                completionHandler(response, nil)
            }
        }

        mockHTTPTransport.sendOperationResponseQueue.append(queuedResponseBlock)

        let appSyncClient = try UnitTestHelpers.makeAppSyncClient(using: mockHTTPTransport, cacheConfiguration: nil)

        // Queue the delaying mutation
        appSyncClient.perform(mutation: addPost) { _, _ in }

        // Queue the asserting mutation
        appSyncClient.perform(mutation: addPost) { _, _ in }

        networkState = .disabledByTest
        reachability.connection = .none

        wait(for: [delayingResponseHandlerInvoked], timeout: 1.0)

        networkState = .reenabledByTest
        reachability.connection = .wifi

        // We now expect send to be invoked, indicating that the queued mutation was read from persistent storage
        wait(for: [delayingResponseDispatched,
                   queuedMutationShouldNotBeInvokedWhenNetworkIsDisabled,
                   queuedMutationShouldNotBeInvokedBeforeNetworkStateHasChanged,
                   queuedMutationInvokedAtCorrectTime],
             timeout: 1.0)
    }

    // Because this tests the offline mutation queue, it will use `AWSNetworkTransport.send(data:completionHandler:)` rather
    // than `AWSNetworkTransport.send(operation:completionHandler:)`
    func testMutationQueueResumesWhenNewClientIsCreated_WithBackingDatabase() throws {
        // Queue a mutation that will not be performed because network is not available
        let reachability = MockReachabilityProvidingFactory.instance
        try reachability.startNotifier()
        reachability.connection = .none

        NetworkReachabilityNotifier.setupShared(
            host: "http://www.amazon.com",
            allowsCellularAccess: true,
            reachabilityFactory: MockReachabilityProvidingFactory.self)

        let addPost = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation
        let mockHTTPTransport = MockAWSNetworkTransport()

        let sendWasInvoked = expectation(description: "HTTPTransport.send was invoked")
        let queuedResponseBlock: SendDataResponseBlock = { _, _ in
            sendWasInvoked.fulfill()
        }

        mockHTTPTransport.sendDataResponseQueue.append(queuedResponseBlock)

        var appSyncClient: DeinitNotifiableAppSyncClient? = try UnitTestHelpers.makeAppSyncClient(using: mockHTTPTransport, cacheConfiguration: AWSAppSyncCacheConfiguration())

        let deinitCalled = expectation(description: "AppSyncClient deinitialized")
        appSyncClient?.deinitCalled = {
            deinitCalled.fulfill()
        }

        // When this method returns, the mutation will be added to the operation queue, and should be added to the persistent
        // database.
        appSyncClient?.perform(mutation: addPost) { _, _ in }

        // Now we clear the existing client and recreate a new one with a valid network connection
        appSyncClient = nil
        wait(for: [deinitCalled], timeout: 0.5)

        reachability.connection = .wifi
        appSyncClient = try UnitTestHelpers.makeAppSyncClient(using: mockHTTPTransport, cacheConfiguration: AWSAppSyncCacheConfiguration())

        // We now expect send to be invoked, indicating that the queued mutation was read from persistent storage
        wait(for: [sendWasInvoked], timeout: 0.5)
    }

    func testCancelingMutationAllowsQueueToProceed() throws {
        // Set up a queue of mutations: delay the first one, cancel the second one, assert the third one still gets invoked

        let addPost = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation
        let mockHTTPTransport = MockAWSNetworkTransport()

        let delayedResponseBody = UnitTestHelpers.makeAddPostResponseBody(withId: "DelayedTestPostID", for: addPost)
        let delayedMutationInvoked = expectation(description: "Delayed mutation invoked")
        let delayedMutationResponseDispatched = expectation(description: "Delayed mutation response dispatched")

        let delayedResponseBlock: SendOperationResponseBlock<CreatePostWithoutFileUsingParametersMutation> = {
            operation, completionHandler in
            delayedMutationInvoked.fulfill()
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .milliseconds(500)) {
                delayedMutationResponseDispatched.fulfill()
                let response = GraphQLResponse(operation: operation, body: delayedResponseBody)
                completionHandler(response, nil)
            }
        }

        mockHTTPTransport.sendOperationResponseQueue.append(delayedResponseBlock)

        let cancelledResponseBody = UnitTestHelpers.makeAddPostResponseBody(withId: "CancelledTestPostID", for: addPost)
        mockHTTPTransport.sendOperationResponseQueue.append(cancelledResponseBody)

        let queuedResponseBody = UnitTestHelpers.makeAddPostResponseBody(withId: "QueuedTestPostID", for: addPost)
        mockHTTPTransport.sendOperationResponseQueue.append(queuedResponseBody)

        let appSyncClient = try UnitTestHelpers.makeAppSyncClient(using: mockHTTPTransport, cacheConfiguration: nil)

        // Queue mutation that has a delay built in
        appSyncClient.perform(mutation: addPost) { _, _ in }

        // Queue mutation that will be cancelled after the delayed mutation is invoked but before it is fulfilled
        let cancelledMutationShouldNotBePerformed = expectation(description: "Cancelled mutation should not be performed")
        cancelledMutationShouldNotBePerformed.isInverted = true
        let cancelTrigger = appSyncClient.perform(mutation: addPost) { _, _ in
            cancelledMutationShouldNotBePerformed.fulfill()
        }

        // Queue mutation to be performed after the cancelled one returns
        let queuedMutationShouldBePerformed = expectation(description: "Queued mutation should be performed")
        appSyncClient.perform(mutation: addPost) { _, _ in
            queuedMutationShouldBePerformed.fulfill()
        }

        wait(for: [delayedMutationInvoked], timeout: 0.5)

        cancelTrigger.cancel()

        wait(for: [delayedMutationResponseDispatched, cancelledMutationShouldNotBePerformed, queuedMutationShouldBePerformed], timeout: 1)
    }

    func testMutationWithoutParametersWithoutBackingDatabase() throws {
        let mutationWithoutParameters = TestMutationWithoutParametersMutation()
        let mockHTTPTransport = MockAWSNetworkTransport()
        mockHTTPTransport.sendOperationHandlerResponseBody = makeTestMutationWithoutParametersResponseBody(withValue: true)

        let appSyncClient = try UnitTestHelpers.makeAppSyncClient(using: mockHTTPTransport, cacheConfiguration: nil)

        let mutationWasPerformed = expectation(description: "Mutation without parameters was performed")
        appSyncClient.perform(mutation: mutationWithoutParameters) { response, error in
            defer {
                mutationWasPerformed.fulfill()
            }

            guard error == nil else {
                XCTFail("Error is not nil: \(error.debugDescription)")
                return
            }

            guard let response = response, let resultValue = response.data?.testMutationWithoutParameters else {
                XCTFail("Response unexpectedly nil")
                return
            }

            XCTAssert(resultValue)
        }

        wait(for: [mutationWasPerformed], timeout: 1.0)
    }

    func testMutationWithoutParametersWithBackingDatabase() throws {
        let mutationWithoutParameters = TestMutationWithoutParametersMutation()
        let mockHTTPTransport = MockAWSNetworkTransport()
        mockHTTPTransport.sendOperationHandlerResponseBody = makeTestMutationWithoutParametersResponseBody(withValue: true)

        let appSyncClient = try UnitTestHelpers.makeAppSyncClient(using: mockHTTPTransport, cacheConfiguration: AWSAppSyncCacheConfiguration())

        let mutationWasPerformed = expectation(description: "Mutation without parameters was performed")
        appSyncClient.perform(mutation: mutationWithoutParameters) { response, error in
            defer {
                mutationWasPerformed.fulfill()
            }

            guard error == nil else {
                XCTFail("Error is not nil: \(error.debugDescription)")
                return
            }

            guard let response = response, let resultValue = response.data?.testMutationWithoutParameters else {
                XCTFail("Response unexpectedly nil")
                return
            }

            XCTAssert(resultValue)
        }

        wait(for: [mutationWasPerformed], timeout: 1.0)
    }

    func testResultHandlerIsInvokedOnSpecifiedQueueWithBackingDatabase() throws {
        let queue = DispatchQueue(label: "Mutation result handler queue")

        let key = DispatchSpecificKey<Void>()
        queue.setSpecific(key: key, value: ())

        let mutationWithoutParameters = TestMutationWithoutParametersMutation()
        let mockHTTPTransport = MockAWSNetworkTransport()
        mockHTTPTransport.sendOperationHandlerResponseBody = makeTestMutationWithoutParametersResponseBody(withValue: true)

        let appSyncClient = try UnitTestHelpers.makeAppSyncClient(using: mockHTTPTransport,
                                                                  cacheConfiguration: AWSAppSyncCacheConfiguration())

        let mutationWasPerformed = expectation(description: "Mutation without parameters was performed")
        appSyncClient.perform(mutation: mutationWithoutParameters, queue: queue) { response, error in
            defer {
                mutationWasPerformed.fulfill()
            }
            XCTAssertNotNil(DispatchQueue.getSpecific(key: key))
        }

        wait(for: [mutationWasPerformed], timeout: 1.0)
    }

    func testResultHandlerIsInvokedOnSpecifiedQueueWithoutBackingDatabase() throws {
        let queue = DispatchQueue(label: "Mutation result handler queue")

        let key = DispatchSpecificKey<Void>()
        queue.setSpecific(key: key, value: ())

        let mutationWithoutParameters = TestMutationWithoutParametersMutation()
        let mockHTTPTransport = MockAWSNetworkTransport()
        mockHTTPTransport.sendOperationHandlerResponseBody = makeTestMutationWithoutParametersResponseBody(withValue: true)

        let appSyncClient = try UnitTestHelpers.makeAppSyncClient(using: mockHTTPTransport,
                                                                  cacheConfiguration: nil)

        let mutationWasPerformed = expectation(description: "Mutation without parameters was performed")
        appSyncClient.perform(mutation: mutationWithoutParameters, queue: queue) { response, error in
            defer {
                mutationWasPerformed.fulfill()
            }
            XCTAssertNotNil(DispatchQueue.getSpecific(key: key))
        }

        wait(for: [mutationWasPerformed], timeout: 1.0)
    }
    
    func testCancelingOfflineMutationRemovesFromQueue() throws {
        
        let reachability = MockReachabilityProvidingFactory.instance
        try reachability.startNotifier()
        reachability.connection = .none
        
        NetworkReachabilityNotifier.setupShared(
            host: "http://www.amazon.com",
            allowsCellularAccess: true,
            reachabilityFactory: MockReachabilityProvidingFactory.self)
        
        let addPost = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation
        let mockHTTPTransport = MockAWSNetworkTransport()
        
        let persistentCache = try AWSMutationCache(fileURL: cacheConfiguration.offlineMutations!)
        let n0 = try persistentCache.getStoredMutationRecordsInQueue().await().count
        let appSyncClient = try UnitTestHelpers.makeAppSyncClient(using: mockHTTPTransport, cacheConfiguration: cacheConfiguration)
        let cancellable = appSyncClient.perform(mutation: addPost) { _, _ in }
        let n1 = try persistentCache.getStoredMutationRecordsInQueue().await().count
        XCTAssertEqual(n0, n1 - 1 )
        cancellable.cancel()
        let n2 = try persistentCache.getStoredMutationRecordsInQueue().await().count
        XCTAssertEqual(n0, n2)
    }

    func testCancelAllMutations() throws {
        let addPost = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation

        let mockHTTPTransport = MockAWSNetworkTransport()
        mockHTTPTransport.operationResponseDelay = 5
        mockHTTPTransport.sendOperationHandlerResponseBody = UnitTestHelpers.makeAddPostResponseBody(withId: "TestPostID", for: addPost)

        let appSyncClient = try UnitTestHelpers.makeAppSyncClient(using: mockHTTPTransport, cacheConfiguration: AWSAppSyncCacheConfiguration())

        let mutationPerformed = expectation(description: "Post added")
        appSyncClient.perform(mutation: addPost) { result, error in
            XCTAssertEqual(result?.data?.createPostWithoutFileUsingParameters?.id, "TestPostID")
            mutationPerformed.fulfill()
        }
        for _ in 0...9 {
            appSyncClient.perform(mutation: addPost) { result, error in
                XCTAssertEqual(result?.data?.createPostWithoutFileUsingParameters?.id, "TestPostID")
            }
        }

        try appSyncClient.clearCaches(options: ClearCacheOptions(clearMutations: true))

        wait(for: [mutationPerformed], timeout: 6.0)

        XCTAssertEqual(appSyncClient.queuedMutationCount, 0)

        mockHTTPTransport.operationResponseDelay = 0

        let furtherMutationPerformed = expectation(description: "Further post added")
        appSyncClient.perform(mutation: addPost) { result, error in
            XCTAssertEqual(result?.data?.createPostWithoutFileUsingParameters?.id, "TestPostID")
            furtherMutationPerformed.fulfill()
        }

        wait(for: [furtherMutationPerformed], timeout: 1.0)
    }

    // MARK: - Utility methods

    func makeTestMutationWithoutParametersResponseBody(withValue value: Bool) -> JSONObject {
        return ["data": ["testMutationWithoutParameters": value]]
    }

}
