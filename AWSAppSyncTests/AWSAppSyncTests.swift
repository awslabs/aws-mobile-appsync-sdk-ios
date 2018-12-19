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
@testable import AWSCore

/// The test class uses the `EventsApp` starter schema from AWS AppSync Console which can be created easily by selecting an option in the console. It uses AWS_IAM for auth.
class AWSAppSyncTests: XCTestCase {
    
    var appSyncClient: AWSAppSyncClient!
    
    let EventName = "Testing Event"
    let EventTime = "July 26 2018, 12:30"
    let EventLocation = "Seattle, WA"
    let EventDescription = "Event Description"

    // Set to `true` in tests that add items to the backing store, so that tests that run afterward start from
    // a known empty state
    var shouldDeleteDuringTearDown = false

    override func setUp() {
        super.setUp()
        do {
            appSyncClient = try AppSyncClientTestHelper(with: .cognitoIdentityPools).appSyncClient
        } catch {
            XCTFail(error.localizedDescription)
        }
        XCTAssertNotNil(appSyncClient, "AppSyncClient should not be nil")
    }

    override func tearDown() {
        super.tearDown()

        guard shouldDeleteDuringTearDown else {
            return
        }

        let query = ListEventsQuery(limit: 99)
        let successfulExpectation = expectation(description: "Fetch done successfully.")

        appSyncClient.fetch(query: query, cachePolicy: .fetchIgnoringCacheData) { (result, error) in
            XCTAssertNil(error, "Error expected to be nil, but is not.")
            XCTAssertNotNil(result?.data?.listEvents?.items, "Items array should not be nil.")
            guard let events = result?.data?.listEvents?.items else { return }

            for event in events {
                self.appSyncClient.perform(mutation: DeleteEventMutation(id: event!.id))
            }
            successfulExpectation.fulfill()
        }

        // Wait for the mutations(delete event actions) to complete.
        wait(for: [successfulExpectation], timeout: 5.0)
    }

    func testAppSynClientConfigurationApiKeyAuthProvider() throws {
        let appSyncClient =
            try AppSyncClientTestHelper(with: .apiKey).appSyncClient
        XCTAssertNotNil(appSyncClient, "AppSyncClient should not be nil when initialized using API Key auth type")
    }

    func testAppSynClientConfigurationOidcAuthProvider() throws {
        let appSyncClient =
            try AppSyncClientTestHelper(with: .invalidOIDC).appSyncClient
        XCTAssertNotNil(appSyncClient, "AppSyncClient should not be nil when initialized using OIDC auth type")
    }

    func testQuery() {
        shouldDeleteDuringTearDown = true
        let successfulMutationEventExpectation = expectation(description: "Mutation done successfully.")
        
        let addEvent = AddEventMutation(name: EventName,
                                        when: EventTime,
                                        where: EventLocation,
                                        description: EventDescription)
        
        appSyncClient.perform(mutation: addEvent) { (result, error) in
            XCTAssertNil(error, "Error expected to be nil, but is not.")
            XCTAssertNotNil(result?.data?.createEvent?.id, "Expected service to return a UUID.")
            XCTAssertEqual(self.EventName, result?.data?.createEvent?.name, "Event names should match.")
            successfulMutationEventExpectation.fulfill()
        }
        
        wait(for: [successfulMutationEventExpectation], timeout: 5.0)

        let query = ListEventsQuery()
        
        let successfullistEventExpectation = expectation(description: "Mutation done successfully.")
        
        appSyncClient.fetch(query: query, cachePolicy: .fetchIgnoringCacheData) { (result, error) in
            XCTAssertNil(error, "Error expected to be nil, but is not.")
            XCTAssertNotNil(result?.data?.listEvents?.items, "Items array should not be empty.")
            XCTAssertGreaterThan(result?.data?.listEvents?.items?.count ?? 0, 0, "Expected service to return at least 1 event.")
            successfullistEventExpectation.fulfill()
        }
        
        wait(for: [successfullistEventExpectation], timeout: 5.0)
    }

    func testMutation() {
        shouldDeleteDuringTearDown = true
        let successfulMutationEventExpectation = expectation(description: "Mutation done successfully.")
        
        let addEvent = AddEventMutation(name: EventName,
                                        when: EventTime,
                                        where: EventLocation,
                                        description: EventDescription)
        
        appSyncClient.perform(mutation: addEvent) { (result, error) in
            XCTAssertNil(error, "Error expected to be nil, but is not.")
            XCTAssertNotNil(result?.data?.createEvent?.id, "Expected service to return a UUID.")
            XCTAssertEqual(self.EventName, result?.data?.createEvent?.name, "Event names should match.")
            successfulMutationEventExpectation.fulfill()
        }
        
        wait(for: [successfulMutationEventExpectation], timeout: 5.0)
    }
    
    func testSubscription() throws {
        shouldDeleteDuringTearDown = true

        var subscription: AWSAppSyncSubscriptionWatcher<NewCommentOnEventSubscription>?

        defer {
            subscription?.cancel()
        }

        let successfulSubscriptionExpectation = expectation(description: "Mutation done successfully.")
        let receivedSubscriptionExpectation = self.expectation(description: "Subscription received successfully.")
        
        let addEvent = AddEventMutation(name: EventName,
                                        when: EventTime,
                                        where: EventLocation,
                                        description: EventDescription)
        var eventIdHolder: GraphQLID?
        appSyncClient.perform(mutation: addEvent) { (result, error) in
            XCTAssertNil(error, "Error expected to be nil, but is not.")
            XCTAssertNotNil(result?.data?.createEvent?.id, "Expected service to return a UUID.")
            XCTAssertEqual(result?.data?.createEvent?.name, self.EventName, "Event names should match.")
            print("Received create event mutation response.")
            
            eventIdHolder = result?.data?.createEvent?.id
            
            successfulSubscriptionExpectation.fulfill()
            
        }
        wait(for: [successfulSubscriptionExpectation], timeout: 10.0)

        guard let eventId = eventIdHolder else {
            XCTAssertNotNil(eventIdHolder, "Expected vent ID from add event mutation")
            return
        }

        subscription = try self.appSyncClient.subscribe(subscription: NewCommentOnEventSubscription(eventId: eventId)) {
            (result, _, error) in
            XCTAssertNil(error, "Error expected to be nil, but is not.")
            print("Received new comment subscription response.")
            receivedSubscriptionExpectation.fulfill()
        }
        XCTAssertNotNil(subscription, "Subscription expected to be non nil.")

        // Currently, subscriptions don't have a good way to inspect that they have been registered on the service.
        // We'll check for `getTopics` returning a non-empty value to stand in for a completion handler
        let subscriptionIsRegisteredExpectation = expectation(description: "New comments subscription should have a non-empty topics list")
        let subscriptionGetTopicsTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) {
            _ in
            guard let subscription = subscription else {
                return
            }

            let topics = subscription.getTopics()

            guard !topics.isEmpty else {
                return
            }

            subscriptionIsRegisteredExpectation.fulfill()
        }
        wait(for: [subscriptionIsRegisteredExpectation], timeout: 10.0)
        subscriptionGetTopicsTimer.invalidate()

        print("Sleeping a few seconds to wait for server to begin delivering subscriptions")
        sleep(5)

        let commentOnEventPerformed = expectation(description: "Commented on event")
        self.appSyncClient.perform(mutation: CommentOnEventMutation(eventId: eventId, content: "content", createdAt: "2 pm")) {
            (result, error) in
            XCTAssertNil(error, "Error expected to be nil, but is not.")
            XCTAssertNotNil(result?.data?.commentOnEvent?.commentId, "Expected service to return a UUID.")
            print("Received create comment mutation response.")
            commentOnEventPerformed.fulfill()
        }

        wait(for: [commentOnEventPerformed, receivedSubscriptionExpectation], timeout: 10.0)
    }
    
    func testOptimisticWriteWithQueryParameter() {
        shouldDeleteDuringTearDown = true
        let initialMutationOperationCompleted = expectation(description: "Initial mutation operation completed")
        let successfulMutationEvent2Expectation = expectation(description: "Mutation done successfully.")
        let successfulOptimisticWriteExpectation = expectation(description: "Optimisitc write done successfully.")
        let successfulQueryFetchExpectation = expectation(description: "Query fetch should success.")
        let successfulLocalQueryFetchExpectation = expectation(description: "Local query fetch should success.")
        
        let addEvent = AddEventMutation(name: EventName,
                                        when: EventTime,
                                        where: EventLocation,
                                        description: EventDescription)
        
        appSyncClient.perform(mutation: addEvent) { (result, error) in
            XCTAssertNil(error, "Error expected to be nil, but is not.")
            XCTAssertNotNil(result?.data?.createEvent?.id, "Expected service to return a UUID.")
            XCTAssertEqual(self.EventName, result?.data?.createEvent?.name, "Event names should match.")
            initialMutationOperationCompleted.fulfill()
        }
        
        wait(for: [initialMutationOperationCompleted], timeout: 5.0)
        
        let fetchQuery = ListEventsQuery(limit: 10)
        
        var cacheCount = 0
        
        appSyncClient.fetch(query: fetchQuery, cachePolicy: .fetchIgnoringCacheData, resultHandler: { (result, error) in
            XCTAssertNil(error, "Error expected to be nil, but is not.")
            XCTAssertNotNil(result?.data?.listEvents?.items, "Items array should not be empty.")
            XCTAssertGreaterThan(result?.data?.listEvents?.items?.count ?? 0, 0, "Expected service to return at least 1 event.")
            cacheCount = result?.data?.listEvents?.items?.count ?? 0
            successfulQueryFetchExpectation.fulfill()
        })
        
        wait(for: [successfulQueryFetchExpectation], timeout: 5.0)
        
        appSyncClient.perform(mutation: addEvent, optimisticUpdate: { (transaction) in
            do {
            try transaction?.update(query: fetchQuery, { (data) in
                data.listEvents?.items?.append(ListEventsQuery.Data.ListEvent.Item.init(id: "RandomId", description: self.EventDescription, name: self.EventName, when: self.EventTime, where: self.EventLocation, comments: nil))
            })
            successfulOptimisticWriteExpectation.fulfill()
            } catch {
                
            }
        }, resultHandler: { (result, error) in
            XCTAssertNil(error, "Error expected to be nil, but is not.")
            XCTAssertNotNil(result?.data?.createEvent?.id, "Expected service to return a UUID.")
            XCTAssertEqual(self.EventName, result?.data?.createEvent?.name, "Event names should match.")
            successfulMutationEvent2Expectation.fulfill()
        })
        
        wait(for: [successfulOptimisticWriteExpectation, successfulMutationEvent2Expectation], timeout: 5.0)
        
        appSyncClient.fetch(query: fetchQuery, cachePolicy: .returnCacheDataDontFetch, resultHandler: { (result, error) in
            XCTAssertNil(error, "Error expected to be nil, but is not.")
            XCTAssertNotNil(result?.data?.listEvents?.items, "Items array should not be empty.")
            XCTAssertGreaterThan(result?.data?.listEvents?.items?.count ?? 0, 0, "Expected cache to return at least 1 event.")
            XCTAssertEqual(result?.data?.listEvents?.items?.count ?? 0, cacheCount + 1)
            successfulLocalQueryFetchExpectation.fulfill()
        })
        
        wait(for: [successfulLocalQueryFetchExpectation], timeout: 5.0)
    }
    
    func testSubscription_Stress() {
        shouldDeleteDuringTearDown = true
        guard let appSyncClient = appSyncClient else {
            XCTFail("appSyncClient must not be nil")
            return
        }

        let subscriptionStressTestHelper = SubscriptionStressTestHelper()
        subscriptionStressTestHelper.stressTestSubscriptions(withAppSyncClient: appSyncClient)
    }
    
    func testInvalidAPIKeyAuth() throws {
        let badlyConfiguredAppSyncClient =
            try AppSyncClientTestHelper(with: .invalidAPIKey).appSyncClient
        XCTAssertNotNil(badlyConfiguredAppSyncClient, "AppSyncClient cannot be nil")
        assertConnectGeneratesAuthError(with: badlyConfiguredAppSyncClient)
    }
    
    func testInvalidOIDCProvider() throws {
        let badlyConfiguredAppSyncClient =
            try AppSyncClientTestHelper(with: .invalidOIDC).appSyncClient
        XCTAssertNotNil(badlyConfiguredAppSyncClient, "AppSyncClient cannot be nil")
        assertConnectGeneratesAuthError(with: badlyConfiguredAppSyncClient)
    }
    
    func testInvalidCredentials() throws {
        let badlyConfiguredAppSyncClient =
            try AppSyncClientTestHelper(with: .invalidOIDC).appSyncClient
        XCTAssertNotNil(badlyConfiguredAppSyncClient, "AppSyncClient cannot be nil")
        assertConnectGeneratesAuthError(with: badlyConfiguredAppSyncClient)
    }

    func testClientDeinit() throws {
        let e = expectation(description: "AWSAppSyncClient deinitialized")
        var deinitNotifiableAppSyncClient: DeinitNotifiableAppSyncClient? =
            try AppSyncClientTestHelper(with: .cognitoIdentityPools).appSyncClient

        deinitNotifiableAppSyncClient!.deinitCalled = { e.fulfill() }
            
        DispatchQueue.global(qos: .background).async { deinitNotifiableAppSyncClient = nil }

        waitForExpectations(timeout: 5)
    }

    // MARK: - Utilities

    // Asserts that the AWSAppSyncClient can connect to the server, thus validating URL and authentication
    func assertCanConnectSuccessfully(with client: AWSAppSyncClient, file: StaticString = #file, line: UInt = #line) {
        let result = simpleFetch(with: client)
        switch result {
        case .failure(let error):
            XCTFail("Failed to connect successfully: \(error.localizedDescription)", file: file, line: line)
        case .success(_):
            break
        }
    }

    func assertConnectGeneratesAuthError(with client: AWSAppSyncClient, file: StaticString = #file,line: UInt = #line) {
        let result = simpleFetch(with: client)

        guard case .failure(let error) = result else {
            XCTFail("Connect successfully but expected auth error", file: file, line: line)
            return
        }

        guard let appSyncError = error as? AWSAppSyncClientError else {
            XCTFail("Received unexpected error type during fetch: \(error.localizedDescription)", file: file, line: line)
            return
        }

        // Can't use enum pattern matching in the XCTAssert macros, so we'll have a bogus "XCTAssertTrue"
        if case .authenticationError = appSyncError {
            XCTAssertTrue(true, "Received authentication error as expected")
        } else if case .requestFailed(_, let response, _) = appSyncError {
            XCTAssertTrue(response?.statusCode == 401 || response?.statusCode == 403, "Expected invalid error code to be either 401 or 403, got \(String(describing: response?.statusCode))")
        } else {
            XCTFail("Received something other than authentication error during fetch: \(error.localizedDescription)", file: file, line: line)
        }
    }

    func simpleFetch(with client: AWSAppSyncClient) -> Result<Void> {
        let queryDidComplete = expectation(description: "ListEventsQuery did complete")
        let query = ListEventsQuery(limit: 99)

        var fetchResult: Result<Void> = .failure("Fetch didn't complete before timeout")

        client.fetch(query: query) {
            (result, error) in

            if let error = error {
                fetchResult = .failure(error)
            } else if result == nil {
                fetchResult = .failure("The result was nil")
            } else {
                fetchResult = .success(())
            }

            queryDidComplete.fulfill()
        }

        wait(for: [queryDidComplete], timeout: 5.0)

        return fetchResult
    }
}

// Conform String to error for this module so we can easily use bare strings in Result failures
extension String: Error {}
