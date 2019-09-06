//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import XCTest
@testable import AWSAppSync
@testable import AWSCore
@testable import AWSAppSyncTestCommon

class SubscriptionLifecycleTests: XCTestCase {

    // MARK: - Properties

    /// Use this as our timeout value for any operation that hits the network. Note that this may need to be higher
    /// than you think, to account for CI systems running in shared environments
    private static let networkOperationTimeout = 180.0

    private static let mutationQueue = DispatchQueue(label: "com.amazonaws.appsync.SubscriptionLifecycleTests.mutationQueue")
    private static let subscriptionAndFetchQueue = DispatchQueue(label: "com.amazonaws.appsync.SubscriptionLifecycleTests.subscriptionAndFetchQueue")

    /// This will be automatically instantiated in `performDefaultSetUpSteps`
    var appSyncClient: AWSAppSyncClient?

    let authType = AppSyncClientTestHelper.AuthenticationType.apiKey

    override func setUp() {
        super.setUp()

        AWSDDLog.sharedInstance.logLevel = .verbose
        AWSDDTTYLogger.sharedInstance.logFormatter = AWSAppSyncClientLogFormatter()
        AWSDDLog.sharedInstance.add(AWSDDTTYLogger.sharedInstance)

        do {
            appSyncClient = try SubscriptionLifecycleTests.makeAppSyncClient(authType: authType)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // MARK: - Tests

    // Given: an active subscription without DeltaSync behavior
    // When: the subscription is cancelled
    // Then: the statusChangeHandler callback is not invoked
    func testCancellationDoesNotInvokeCallback() throws {
        let postCreated = expectation(description: "Post created successfully.")
        let addPost = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation

        var idHolder: GraphQLID?
        appSyncClient?.perform(mutation: addPost, queue: SubscriptionLifecycleTests.mutationQueue) { result, error in
            print("CreatePost result handler invoked")
            idHolder = result?.data?.createPostWithoutFileUsingParameters?.id
            postCreated.fulfill()
        }
        wait(for: [postCreated], timeout: SubscriptionLifecycleTests.networkOperationTimeout)

        guard let id = idHolder else {
            XCTFail("Expected ID from addPost mutation")
            return
        }

        let subscriptionIsActive = expectation(description: "Upvote subscription should be connected")
        let disconnectStatusReceived = expectation(description: "Should not receive a disconnect notification for a customer-initiated disconnect")
        disconnectStatusReceived.isInverted = true
        let statusChangeHandler: SubscriptionStatusChangeHandler = { status in
            switch status {
            case .connected:
                subscriptionIsActive.fulfill()
            case .disconnected:
                disconnectStatusReceived.fulfill()
            default:
                break
            }
        }

        let subscriptionResultHandlerInvoked = expectation(description: "Subscription callback should not be invoked")
        subscriptionResultHandlerInvoked.isInverted = true
        let subscriptionOptional = try self.appSyncClient?.subscribe(
            subscription: OnUpvotePostSubscription(id: id),
            queue: SubscriptionLifecycleTests.subscriptionAndFetchQueue,
            statusChangeHandler: statusChangeHandler) { _, _, error in
                print("Subscription result handler invoked")
                if let error = error {
                    XCTFail("Unexpected error in subscription: \(error)")
                    return
                }
                subscriptionResultHandlerInvoked.fulfill()
        }

        guard let subscription = subscriptionOptional else {
            XCTFail("Subscription unexpectedly nil")
            return
        }

        wait(for: [subscriptionIsActive], timeout: SubscriptionLifecycleTests.networkOperationTimeout)

        let subscriptionCancelled = expectation(description: "Subscription is cancelled")
        DispatchQueue.main.async {
            subscription.cancel()
            subscriptionCancelled.fulfill()
        }

        wait(for: [subscriptionCancelled], timeout: SubscriptionLifecycleTests.networkOperationTimeout)

        wait(for: [subscriptionResultHandlerInvoked, disconnectStatusReceived], timeout: 2.0)
    }

    // MARK: - Utilities

    static func makeAppSyncClient(authType: AppSyncClientTestHelper.AuthenticationType,
                                  cacheConfiguration: AWSAppSyncCacheConfiguration? = nil) throws -> DeinitNotifiableAppSyncClient {

        let testBundle = Bundle(for: SubscriptionLifecycleTests.self)
        let helper = try AppSyncClientTestHelper(
            with: authType,
            cacheConfiguration: cacheConfiguration,
            testBundle: testBundle
        )
        return helper.appSyncClient
    }

}
