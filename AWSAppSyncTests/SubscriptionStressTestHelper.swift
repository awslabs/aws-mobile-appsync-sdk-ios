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

class SubscriptionStressTestHelper: XCTestCase {
    private static let numberOfEventsToTest = 40

    private var appSyncClient: AWSAppSyncClient!
    private var eventIds = [GraphQLID](repeating: "", count: SubscriptionStressTestHelper.numberOfEventsToTest)

    // Hold onto this to retain references to the watchers during the test invocation
    var subscriptionWatchers = [AWSAppSyncSubscriptionWatcher<NewCommentOnEventSubscription>]()

    // MARK: - Public test helper methods

    func stressTestSubscriptions(withAppSyncClient appSyncClient: AWSAppSyncClient) {
        defer {
            subscriptionWatchers.forEach { $0.cancel() }
        }

        self.appSyncClient = appSyncClient

        let allEventsAreAddedExpectations = makeTestEvents()
        wait(for: allEventsAreAddedExpectations, timeout: 30.0)
        XCTAssertEqual(eventIds.count, SubscriptionStressTestHelper.numberOfEventsToTest)

        // Add subscriptions for each of the created events. The expectations will be fulfilled
        // after the mutations from the comments are generated below.
        let allSubscriptionsAreTriggeredExpectations = makeSubscriptions()

        print("Waiting 10s for the server to begin delivering subscriptions")
        sleep(10)

        let commentOnEventsExpectations = makeTestEventComments()

        let combinedExpectations = commentOnEventsExpectations + allSubscriptionsAreTriggeredExpectations
        wait(for: combinedExpectations, timeout: 30.0)
    }

    // MARK: - Private utility methods

    private func makeTestEvents() -> [XCTestExpectation] {
        // Create event records to mutate later
        var addEventsExpectations = [XCTestExpectation]()

        for i in 0 ..< SubscriptionStressTestHelper.numberOfEventsToTest {
            let addEventExpectation = XCTestExpectation(description: "Added event \(i)")
            addEventsExpectations.append(addEventExpectation)
            appSyncClient.perform(mutation: getDefaultAddEventMutation()) {
                (result: GraphQLResult<AddEventMutation.Data>?, error: Error?) in
                XCTAssertNil(error, "Error should be nil")

                guard let result = result, let payload = result.data?.createEvent else {
                    XCTFail("Result & payload should not be nil")
                    return
                }

                XCTAssertEqual(DefaultEventTestData.EventName, payload.name, "Event names should match.")
                let eventId = payload.id
                self.eventIds[i] = eventId
                addEventExpectation.fulfill()
                print("Successful AddEventMutation \(i) (\(eventId))")
            }
            print("Attempting AddEventMutation \(i)")
        }

        return addEventsExpectations
    }

    private func getDefaultAddEventMutation() -> AddEventMutation {
        let addEventMutation = AddEventMutation(name: DefaultEventTestData.EventName,
                                                when: DefaultEventTestData.EventTime,
                                                where: DefaultEventTestData.EventLocation,
                                                description: DefaultEventTestData.EventDescription)
        return addEventMutation
    }

    private func makeSubscriptions() -> [XCTestExpectation] {
        var subscriptionsTriggeredExpectations = [XCTestExpectation]()

        for (i, eventId) in eventIds.enumerated() {
            let subscriptionTriggeredExpectation = XCTestExpectation(description: "Subscription triggered for event \(i) (\(eventId))")
            subscriptionsTriggeredExpectations.append(subscriptionTriggeredExpectation)

            let subscription: NewCommentOnEventSubscription = NewCommentOnEventSubscription(eventId: eventId)
            let optionalSubscriptionWatcher = try! appSyncClient.subscribe(subscription: subscription) {
                (result, _, error) in
                XCTAssertNil(error, "Error should be nil")

                guard let payload = result?.data?.subscribeToEventComments else {
                    XCTFail("Result & payload should not be nil")
                    return
                }

                let eventIdFromPayload = payload.eventId

                subscriptionTriggeredExpectation.fulfill()
                print("Triggered NewCommentOnEventSubscription \(i) (\(eventIdFromPayload))")
            }
            print("Attempting NewCommentOnEventSubscription \(i) (\(eventId))")

            guard let subscriptionWatcher = optionalSubscriptionWatcher else {
                XCTFail("Subscription watcher \(i) (\(eventId)) should not be nil")
                continue
            }

            subscriptionWatchers.append(subscriptionWatcher)
        }

        waitForRegistration(of: subscriptionWatchers)

        return subscriptionsTriggeredExpectations
    }

    typealias UnregisteredWatcherExpectation = (subscriptionWatcher: AWSAppSyncSubscriptionWatcher<NewCommentOnEventSubscription>, expectation: XCTestExpectation)

    // Currently, `AWSAppSyncClient.subscribe(subscription:queue:resultHandler:)` doesn't have a
    // good way to inspect that the subscription has been registered on the service. We'll check
    // for `getTopics` returning a non-empty value to stand in for a completion handler
    private func waitForRegistration(of subscriptionWatchers: [AWSAppSyncSubscriptionWatcher<NewCommentOnEventSubscription>]) {

        var subscriptionWatcherRegisteredExpectations = [XCTestExpectation]()

        var unregisteredWatcherExpectationsByIndex = [Int: UnregisteredWatcherExpectation]()
        for (i, watcher) in subscriptionWatchers.enumerated() {
            let expectation = XCTestExpectation(description: "Subscription watcher \(i) is registered")
            subscriptionWatcherRegisteredExpectations.append(expectation)
            unregisteredWatcherExpectationsByIndex[i] = (subscriptionWatcher: watcher, expectation: expectation)
        }

        // Wait until subscriptions are all registered
        let subscriptionWatcherRegistrationTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) {
            _ in
            var indexesToDelete = Set<Int>()
            for index in unregisteredWatcherExpectationsByIndex.keys {
                guard let (subscriptionWatcher, expectation) = unregisteredWatcherExpectationsByIndex[index] else {
                    continue
                }
                let isRegistered = !subscriptionWatcher.getTopics().isEmpty
                if isRegistered {
                    expectation.fulfill()
                    indexesToDelete.insert(index)
                    print("Registered NewCommentOnEventSubscription \(index)")
                }
            }

            for index in indexesToDelete {
                unregisteredWatcherExpectationsByIndex.removeValue(forKey: index)
            }
        }

        // Wait for all subscriptions to be registered
        let timeToWait = Double(eventIds.count)
        wait(for: subscriptionWatcherRegisteredExpectations, timeout: timeToWait)
        subscriptionWatcherRegistrationTimer.invalidate()

        XCTAssertTrue(unregisteredWatcherExpectationsByIndex.isEmpty, "All subscriptions should have been registered by now")
    }

    private func makeTestEventComments() -> [XCTestExpectation] {
        // Mutate the watched objects by commenting on them. This should fire each associated subscription
        // We set up mutation expectations so that, if the test fails, we can tell whether it was the
        // mutation that failed to complete, or the subscription that failed to trigger
        var commentExpectations = [XCTestExpectation]()
        for (i, eventId) in eventIds.enumerated() {
            let commentExpectation = XCTestExpectation(description: "Commented on event \(i) (\(eventId))")
            commentExpectations.append(commentExpectation)

            let mutation = CommentOnEventMutation(eventId: eventId, content: "content \(i) (\(eventId))", createdAt: "\(Date())")

            appSyncClient.perform(mutation:mutation) {
                (result, error) in
                XCTAssertNil(error, "Error should be nil")

                guard let result = result, let _ = result.data?.commentOnEvent else {
                    XCTFail("Result & payload should not be nil")
                    return
                }
                commentExpectation.fulfill()
                print("Successful CommentOnEventMutation \(i) (\(eventId))")
            }
            print("Attempting CommentOnEventMutation \(i) (\(eventId))")
        }
        return commentExpectations
    }

}
