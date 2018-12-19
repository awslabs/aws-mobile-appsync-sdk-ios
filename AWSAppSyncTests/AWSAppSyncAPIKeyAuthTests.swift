//
//  AWSAppSyncAPIKeyAuthTests.swift
//  AWSAppSyncTests
//
import XCTest
@testable import AWSAppSync
@testable import AWSCore

class AWSAppSyncAPIKeyAuthTests: XCTestCase {
    var appSyncClient: AWSAppSyncClient!

    let EventName = "Testing Event"
    let EventTime = "July 26 2018, 12:30"
    let EventLocation = "Seattle, WA"
    let EventDescription = "Event Description"

    override func setUp() {
        super.setUp()
        do {
            appSyncClient = try makeAppSyncClient()
        } catch {
            XCTFail(error.localizedDescription)
        }
        XCTAssertNotNil(appSyncClient, "AppSyncClient should not be nil")
    }

    func makeAppSyncClient(using databaseURL: URL? = nil) throws -> AWSAppSyncClient {
        let helper = try AppSyncClientTestHelper(with: .apiKey, databaseURL: databaseURL)
        return helper.appSyncClient
    }

    override func tearDown() {
        super.tearDown()
        deleteAll()
    }

    func deleteAll() {
        let query = ListEventsQuery(limit: 99)
        let listEventsExpectation = expectation(description: "Fetch done successfully.")

        var events: [ListEventsQuery.Data.ListEvent.Item?]?

        appSyncClient.fetch(query: query, cachePolicy: .fetchIgnoringCacheData) { (result, error) in
            XCTAssertNil(error, "Error expected to be nil, but is not.")
            XCTAssertNotNil(result?.data?.listEvents?.items, "Items array should not be nil.")
            events = result?.data?.listEvents?.items
            listEventsExpectation.fulfill()
        }

        // Wait for the list to complete
        wait(for: [listEventsExpectation], timeout: 5.0)

        guard let eventsToDelete = events else {
            return
        }

        var deleteExpectations = [XCTestExpectation]()
        for event in eventsToDelete {
            guard let event = event else {
                continue
            }

            let deleteExpectation = expectation(description: "Delete event \(event.id)")
            deleteExpectations.append(deleteExpectation)

            appSyncClient.perform(
                mutation: DeleteEventMutation(id: event.id),
                queue: DispatchQueue.main,
                optimisticUpdate: nil,
                conflictResolutionBlock: nil,
                resultHandler: {
                    (result, error) in
                    guard let _ = result else {
                        if let error = error {
                            XCTFail(error.localizedDescription)
                        } else {
                            XCTFail("Error deleting \(event.id)")
                        }
                        return
                    }
                    deleteExpectation.fulfill()
                }
            )
        }

        wait(for: deleteExpectations, timeout: 5.0)
    }

    func testQuery() {
        let successfulMutationEventExpectation = expectation(description: "Mutation done successfully.")
        
        let addEvent = AddEventMutation(name: DefaultEventTestData.EventName,
                                        when: DefaultEventTestData.EventTime,
                                        where: DefaultEventTestData.EventLocation,
                                        description: DefaultEventTestData.EventDescription)
        
        appSyncClient?.perform(mutation: addEvent) { (result, error) in
            XCTAssertNil(error, "Error expected to be nil, but is not.")
            XCTAssertNotNil(result?.data?.createEvent?.id, "Expected service to return a UUID.")
            XCTAssert(DefaultEventTestData.EventName == result!.data!.createEvent!.name!, "Event names should match.")
            successfulMutationEventExpectation.fulfill()
        }
        
        wait(for: [successfulMutationEventExpectation], timeout: 5.0)
        
        let query = ListEventsQuery()
        
        let successfullistEventExpectation = expectation(description: "Mutation done successfully.")
        
        appSyncClient?.fetch(query: query, cachePolicy: .fetchIgnoringCacheData) { (result, error) in
            XCTAssertNil(error, "Error expected to be nil, but is not.")
            XCTAssertNotNil(result?.data?.listEvents?.items, "Items array should not be empty.")
            XCTAssertTrue(result!.data!.listEvents!.items!.count > 0, "Expected service to return at least 1 event.")
            successfullistEventExpectation.fulfill()
        }
        
        wait(for: [successfullistEventExpectation], timeout: 5.0)
    }
    
    func testMutation() {
        let successfulMutationEventExpectation = expectation(description: "Mutation done successfully.")
        
        let addEvent = AddEventMutation(name: DefaultEventTestData.EventName,
                                        when: DefaultEventTestData.EventTime,
                                        where: DefaultEventTestData.EventLocation,
                                        description: DefaultEventTestData.EventDescription)
        
        appSyncClient?.perform(mutation: addEvent) { (result, error) in
            XCTAssertNil(error, "Error expected to be nil, but is not.")
            XCTAssertNotNil(result?.data?.createEvent?.id, "Expected service to return a UUID.")
            XCTAssert(DefaultEventTestData.EventName == result!.data!.createEvent!.name!, "Event names should match.")
            successfulMutationEventExpectation.fulfill()
        }
        
        wait(for: [successfulMutationEventExpectation], timeout: 5.0)
    }

    func testSubscription_Stress() {
        deleteAll()
        guard let appSyncClient = appSyncClient else {
            XCTFail("appSyncClient must not be nil")
            return
        }

        let subscriptionStressTestHelper = SubscriptionStressTestHelper()
        subscriptionStressTestHelper.stressTestSubscriptions(withAppSyncClient: appSyncClient)
    }

    // Validates that queries are invoked and returned as expected during initial setup and reconnection flows
    func testSyncOperationAtSetupAndReconnect() throws {
        enum SyncWatcherLifecyclePhase {
            case setUp
            case monitoring
        }

        // Let result handlers inspect the current phase of the sync watcher's "lifecycle" so they can properly fulfill
        // expectations
        var _currentSyncWatcherLifecyclePhase = SyncWatcherLifecyclePhase.setUp
        func currentSyncWatcherLifecyclePhase() -> SyncWatcherLifecyclePhase {
            return _currentSyncWatcherLifecyclePhase
        }

        // This tests needs a physical DB for the SubscriptionMetadataCache to properly return a "lastSynced" value.
        let databaseURL = URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent("testSyncOperationAtSetupAndReconnect-appsync-local-db")
        try? FileManager.default.removeItem(at: databaseURL)

        let appSyncClient = try makeAppSyncClient(using: databaseURL)

        var syncWatcher: Cancellable?
        defer {
            syncWatcher?.cancel()
        }

        let baseRefreshIntervalInSeconds = 86_400

        deleteAll()

        let addEventExpectation = expectation(description: "Mutation done successfully.")
        let addEvent = AddEventMutation(
            name: DefaultEventTestData.EventName,
            when: DefaultEventTestData.EventTime,
            where: DefaultEventTestData.EventLocation,
            description: DefaultEventTestData.EventDescription
        )

        var eventId: GraphQLID?
        appSyncClient.perform(mutation: addEvent) {
            (result, error) in
            print("AddEventMutation result handler invoked")
            XCTAssertNil(error, "AddEventMutation error expected to be nil, but is not.")
            XCTAssertNotNil(result?.data?.createEvent?.id, "AddEventMutation expected service to return a UUID")
            XCTAssert(DefaultEventTestData.EventName == result!.data!.createEvent!.name!, "AddEventMutation event names should match")
            eventId = result!.data!.createEvent!.id
            addEventExpectation.fulfill()
        }
        wait(for: [addEventExpectation], timeout: 10.0)

        // Set up the expectations for the initial connection (simulates the first time the app was launched)
        let initialBaseQueryHandlerShouldBeInvokedToHydrateFromCache =
            expectation(description: "Initial base query result handler should be invoked to hydrate subscription from cache")

        let initialBaseQueryShouldBeInvokedToPopulateFromService =
            expectation(description: "Initial base query result handler should be invoked to populate subscription from service")

        let initialBaseQueryShouldNotBeInvokedDuringMonitoring =
            expectation(description: "Initial base query result handler should not be invoked during monitoring")
        initialBaseQueryShouldNotBeInvokedDuringMonitoring.isInverted = true

        let initialSubscriptionHandlerShouldNotBeInvokedDuringSetup =
            expectation(description: "Initial subscription query result handler should not be invoked during setup")
        initialSubscriptionHandlerShouldNotBeInvokedDuringSetup.isInverted = true

        let initialSubscriptionHandlerShouldBeInvokedDuringMonitoring =
            expectation(description: "Initial subscription query result handler should be invoked during monitoring")

        let initialDeltaHandlerShouldNotBeInvokedDuringSetup =
            expectation(description: "Initial delta query result handler should not be invoked during setup")
        initialDeltaHandlerShouldNotBeInvokedDuringSetup.isInverted = true

        let initialDeltaHandlerShouldNotBeInvokedDuringMonitoring =
            expectation(description: "Initial delta query result handler should not be invoked during monitoring")
        initialDeltaHandlerShouldNotBeInvokedDuringMonitoring.isInverted = true

        var initialBaseQueryResultHandlerInvocationCount = 0

        let initialBaseQueryResultHandler: (GraphQLResult<ListEventsQuery.Data>?, Error?) -> Void = {
            result, error in
            print("Initial base query result handler invoked")
            XCTAssertNil(error, "Initial base query error should be nil")
            initialBaseQueryResultHandlerInvocationCount += 1

            switch currentSyncWatcherLifecyclePhase() {
            case .setUp:
                if (initialBaseQueryResultHandlerInvocationCount == 1) {
                    initialBaseQueryHandlerShouldBeInvokedToHydrateFromCache.fulfill()
                    XCTAssertNil(result, "Initial base query result from cache should be nil")
                } else if initialBaseQueryResultHandlerInvocationCount == 2 {
                    XCTAssertNotNil(result, "Initial base query result from network should not be nil")
                    initialBaseQueryShouldBeInvokedToPopulateFromService.fulfill()
                } else {
                    XCTFail("Expecting only 2 invocations of base query result operation, but got \(initialBaseQueryResultHandlerInvocationCount).")
                }
            case .monitoring:
                initialBaseQueryShouldNotBeInvokedDuringMonitoring.fulfill()
            }
        }

        let initialSubscriptionResultHandler: (GraphQLResult<NewCommentOnEventSubscription.Data>?, ApolloStore.ReadWriteTransaction?, Error?) -> Void = {
            result, transaction, error in
            print("Initial subscription result handler invoked")
            XCTAssertNotNil(result, "Initial subscription result should not be nil")
            XCTAssertNotNil(transaction, "Initial subscription transaction should not be nil")
            XCTAssertNil(error, "Initial subscription error should be nil")
            switch currentSyncWatcherLifecyclePhase() {
            case .setUp:
                initialSubscriptionHandlerShouldNotBeInvokedDuringSetup.fulfill()
            case .monitoring:
                initialSubscriptionHandlerShouldBeInvokedDuringMonitoring.fulfill()
            }
        }

        let initialDeltaQueryResultHandler: (GraphQLResult<ListEventsQuery.Data>?, ApolloStore.ReadWriteTransaction?, Error?) -> Void = {
            _, _, _ in
            print("Initial delta query result handler invoked unexpectedly")
            switch currentSyncWatcherLifecyclePhase() {
            case .setUp:
                initialDeltaHandlerShouldNotBeInvokedDuringSetup.fulfill()
            case .monitoring:
                initialDeltaHandlerShouldNotBeInvokedDuringMonitoring.fulfill()
            }
        }

        // Refresh interval defaults to one day, but we'll make it explicit here in case that changes in the future
        let syncConfiguration = SyncConfiguration(baseRefreshIntervalInSeconds: baseRefreshIntervalInSeconds)

        let listEventsQuery = ListEventsQuery()
        let eventSubscription = NewCommentOnEventSubscription(eventId: eventId!)

        syncWatcher = appSyncClient.sync(
            baseQuery: listEventsQuery,
            baseQueryResultHandler: initialBaseQueryResultHandler,
            subscription: eventSubscription,
            subscriptionResultHandler: initialSubscriptionResultHandler,
            deltaQuery: listEventsQuery,
            deltaQueryResultHandler: initialDeltaQueryResultHandler,
            syncConfiguration: syncConfiguration
        )
        
        XCTAssertNotNil(syncWatcher, "Initial subscription sync watcher expected to be non nil.")

        // Wait to ensure the new watcher is properly initialized. We don't expect the delta query expectation to be fulfilled
        // during either initialization or subsequent subscription. However, we're only allowed to `wait` on an expectation one
        // time, so we'll wait on the "setup" expectation here, and the "monitoring" expectation below
        wait(
            for: [
                initialBaseQueryHandlerShouldBeInvokedToHydrateFromCache,
                initialBaseQueryShouldBeInvokedToPopulateFromService,
                initialSubscriptionHandlerShouldNotBeInvokedDuringSetup,
                initialDeltaHandlerShouldNotBeInvokedDuringSetup
            ],
            timeout: 10.0
        )

        // Now that we've subscribed, comment on the event, to trigger the subscription
        _currentSyncWatcherLifecyclePhase = .monitoring
        let firstCommentMutation: CommentOnEventMutation = CommentOnEventMutation(eventId: eventId!, content: "First comment", createdAt: "2:00 pm")
        let firstCommentShouldBePosted = expectation(description: "First comment should be posted")

        // Wait 3 seconds to ensure sync/subscription is active, then trigger the mutation
        DispatchQueue.global().async {
            sleep(3)
            self.appSyncClient?.perform(mutation: firstCommentMutation) {
                (result, error) in
                print("Received first create comment mutation response")
                XCTAssertNil(error, "First comment error expected to be nil, but is not")
                XCTAssertNotNil(result?.data?.commentOnEvent?.commentId, "First comment expected service to return a UUID")
                firstCommentShouldBePosted.fulfill()
            }
        }

        wait(
            for: [
                firstCommentShouldBePosted,
                initialBaseQueryShouldNotBeInvokedDuringMonitoring,
                initialSubscriptionHandlerShouldBeInvokedDuringMonitoring,
                initialDeltaHandlerShouldNotBeInvokedDuringMonitoring
            ],
            timeout: 10.0
        )

        // Cancel the syncWatcher to simulate an app restart
        syncWatcher?.cancel()
        _currentSyncWatcherLifecyclePhase = .setUp

        // Now set up the expectations for the "restarted" app
        let restartedBaseQueryHandlerShouldBeInvokedToHydrateFromCache =
            expectation(description: "Restarted base query result handler should be invoked to hydrate subscription from cache")

        let restartedBaseQueryShouldNotBeInvokedToPopulateFromService =
            expectation(description: "Restarted base query result handler should not be invoked to populate subscription from service since it is within deltaSync refresh time")
        restartedBaseQueryShouldNotBeInvokedToPopulateFromService.isInverted = true

        let restartedBaseQueryShouldNotBeInvokedDuringMonitoring =
            expectation(description: "Restarted base query result handler should not be invoked during monitoring")
        restartedBaseQueryShouldNotBeInvokedDuringMonitoring.isInverted = true

        let restartedSubscriptionHandlerShouldNotBeInvokedDuringSetup =
            expectation(description: "Restarted subscription query result handler should not be invoked during setup")
        restartedSubscriptionHandlerShouldNotBeInvokedDuringSetup.isInverted = true

        let restartedSubscriptionHandlerShouldBeInvokedDuringMonitoring =
            expectation(description: "Restarted subscription query result handler should be invoked during monitoring")

        let restartedDeltaHandlerShouldBeInvokedDuringSetup =
            expectation(description: "Restarted delta query result handler should not be invoked during setup")

        let restartedDeltaHandlerShouldNotBeInvokedDuringMonitoring =
            expectation(description: "Restarted delta query result handler should not be invoked during monitoring")
        restartedDeltaHandlerShouldNotBeInvokedDuringMonitoring.isInverted = true

        var restartedBaseQueryResultHandlerInvocationCount = 0

        let restartedBaseQueryResultHandler: (GraphQLResult<ListEventsQuery.Data>?, Error?) -> Void = {
            result, error in
            print("Restarted base query result handler invoked")
            XCTAssertNotNil(result, "Restarted base query result should not be nil")
            XCTAssertNil(error, "Restarted base query error should be nil")

            switch currentSyncWatcherLifecyclePhase() {
            case .setUp:
                restartedBaseQueryResultHandlerInvocationCount += 1
                if (restartedBaseQueryResultHandlerInvocationCount == 1) {
                    restartedBaseQueryHandlerShouldBeInvokedToHydrateFromCache.fulfill()
                } else if restartedBaseQueryResultHandlerInvocationCount == 2 {
                    restartedBaseQueryShouldNotBeInvokedToPopulateFromService.fulfill()
                } else {
                    XCTFail("Expecting only 2 invocations of base query result operation, but got \(restartedBaseQueryResultHandlerInvocationCount).")
                }
            case .monitoring:
                restartedBaseQueryShouldNotBeInvokedDuringMonitoring.fulfill()
            }
        }

        let restartedSubscriptionResultHandler: (GraphQLResult<NewCommentOnEventSubscription.Data>?, ApolloStore.ReadWriteTransaction?, Error?) -> Void = {
            result, transaction, error in
            print("Restarted subscription result handler invoked")
            XCTAssertNotNil(result, "Restarted subscription result should not be nil")
            XCTAssertNotNil(transaction, "Restarted subscription transaction should not be nil")
            XCTAssertNil(error, "Restarted subscription error should be nil")
            switch currentSyncWatcherLifecyclePhase() {
            case .setUp:
                restartedSubscriptionHandlerShouldNotBeInvokedDuringSetup.fulfill()
            case .monitoring:
                restartedSubscriptionHandlerShouldBeInvokedDuringMonitoring.fulfill()
            }
        }

        let restartedDeltaQueryResultHandler: (GraphQLResult<ListEventsQuery.Data>?, ApolloStore.ReadWriteTransaction?, Error?) -> Void = {
            result, transaction, error in
            print("Restarted delta query result handler invoked")
            XCTAssertNotNil(result, "Restarted delta query result should not be nil")
            XCTAssertNotNil(transaction, "Restarted delta query transaction should not be nil")
            XCTAssertNil(error, "Restarted delta query error should be nil")
            switch currentSyncWatcherLifecyclePhase() {
            case .setUp:
                restartedDeltaHandlerShouldBeInvokedDuringSetup.fulfill()
            case .monitoring:
                restartedDeltaHandlerShouldNotBeInvokedDuringMonitoring.fulfill()
            }
        }

        syncWatcher = appSyncClient.sync(
            baseQuery: listEventsQuery,
            baseQueryResultHandler: restartedBaseQueryResultHandler,
            subscription: eventSubscription,
            subscriptionResultHandler: restartedSubscriptionResultHandler,
            deltaQuery: listEventsQuery,
            deltaQueryResultHandler: restartedDeltaQueryResultHandler,
            syncConfiguration: syncConfiguration
        )
        
        XCTAssertNotNil(syncWatcher, "Restart sync watcher expected to be non nil")

        // Wait to ensure the new watcher is properly initialized
        wait(
            for: [
                restartedBaseQueryHandlerShouldBeInvokedToHydrateFromCache,
                restartedBaseQueryShouldNotBeInvokedToPopulateFromService,
                restartedSubscriptionHandlerShouldNotBeInvokedDuringSetup,
                restartedDeltaHandlerShouldBeInvokedDuringSetup
            ],
            timeout: 10.0
        )

        // Trigger the restarted watcher's subscription
        _currentSyncWatcherLifecyclePhase = .monitoring
        let secondCommentMutation: CommentOnEventMutation = CommentOnEventMutation(eventId: eventId!, content: "Second comment", createdAt: "2:01 pm")
        let secondCommentShouldBePosted = expectation(description: "Second comment should be posted")

        // Wait 3 seconds to ensure sync/subscription is active, then trigger the mutation
        DispatchQueue.global().async {
            sleep(3)
            self.appSyncClient?.perform(mutation: secondCommentMutation) {
                (result, error) in
                print("Received second create comment mutation response")
                XCTAssertNil(error, "second comment error expected to be nil, but is not")
                XCTAssertNotNil(result?.data?.commentOnEvent?.commentId, "second comment expected service to return a UUID")
                secondCommentShouldBePosted.fulfill()
            }
        }
        
        wait(
            for: [
                secondCommentShouldBePosted,
                restartedBaseQueryShouldNotBeInvokedDuringMonitoring,
                restartedSubscriptionHandlerShouldBeInvokedDuringMonitoring,
                restartedDeltaHandlerShouldNotBeInvokedDuringMonitoring
            ],
            timeout: 10.0
        )

    }
}
