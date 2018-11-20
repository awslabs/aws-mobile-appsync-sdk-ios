//
//  AWSAppSyncAPIKeyAuthTests.swift
//  AWSAppSyncTests
//
import XCTest
@testable import AWSAppSync
@testable import AWSCore

class AWSAppSyncAPIKeyAuthTests: XCTestCase {
    
    var AppSyncRegion: AWSRegionType = .USEast1
    var AppSyncEndpointURL: URL = URL(string: "https://localhost")! // Your AppSync endpoint here.
    var apiKey = "YOUR_API_KEY"
    let database_name = "appsync-local-db"
    var appSyncClient: AWSAppSyncClient?
    
    static let ENDPOINT_KEY = "AppSyncEndpointAPIKey"
    static let API_KEY = "AppSyncAPIKey"
    static let REGION_KEY = "AppSyncEndpointAPIKeyRegion"
    
    let TestSetupErrorMessage = """
    Could not load appsync_test_credentials.json which is required to run the tests in this class.\n
    To run this test class, please add a file named appsync_test_credentials.json in AWSAppSyncTests folder of this project. You can alternatively update `AppSyncEndpointURL` and `CognitoIdentityPoolId` values to use inline values. \n\n
    Format of the config file:
    {
       "AppSyncEndpoint": "https://abc2131absc.appsync-api.us-east-1.amazonaws.com/graphql",
       "AppSyncRegion": "us-east-1",
       "CognitoIdentityPoolId": "us-east-1:abc123-1234-123a-a123-12345fe123",
       "CognitoIdentityPoolRegion": "us-east-1",
       "AppSyncEndpointAPIKey": "https://apikeybasedendpoint.appsync-api.us-east-1.amazonaws.com/graphql",
       "AppSyncEndpointAPIKeyRegion": "us-east-1",
       "AppSyncAPIKey": "da2-sad3lkh23422"
    }

    The test uses 2 different backend setups for tests.
        - the events starter schema with AWS_IAM(Cognito Identity) auth which can be created from AWSAppSync Console.
        - the events starter schema with API_KEY auth which can be created from AWSAppSyncConsole.
    """
    
    override func setUp() {
        super.setUp()
        
        // Read credentials from appsync_test_credentials.json
        if let credentialsPath: String = Bundle.init(for: self.classForCoder).path(forResource: "appsync_test_credentials", ofType: "json"), let credentialsData = try? Data.init(contentsOf: URL(fileURLWithPath: credentialsPath)) {
            print("json path: \(credentialsPath)")
            let json = try? JSONSerialization.jsonObject(with: credentialsData, options: JSONSerialization.ReadingOptions.allowFragments)
            
            guard let jsonObject = json as? JSONObject else {
                XCTFail(TestSetupErrorMessage)
                return
            }

            let endpoint = jsonObject[AWSAppSyncAPIKeyAuthTests.ENDPOINT_KEY]! as! String
            let apiKeyValue = jsonObject[AWSAppSyncAPIKeyAuthTests.API_KEY]! as! String
            AppSyncEndpointURL = URL(string: endpoint)!
            apiKey = apiKeyValue
            AppSyncRegion = (jsonObject[AWSAppSyncAPIKeyAuthTests.REGION_KEY]! as! String).aws_regionTypeValue()
        } else if (apiKey != "YOUR_API_KEY" && AppSyncEndpointURL.absoluteString != "https://localhost" ) {
            XCTFail(TestSetupErrorMessage)
            return
        } else {
            XCTFail(TestSetupErrorMessage)
            return
        }
        
        // You can choose your database location, accessible by the SDK
        let databaseURL = URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent(database_name)
        
        do {
            AWSDDLog.sharedInstance.logLevel = .error
            AWSDDLog.add(AWSDDTTYLogger.sharedInstance)
            // Create AWSApiKeyAuthProvider
            class BasicAWSAPIKeyAuthProvider: AWSAPIKeyAuthProvider {
                var apiKey: String
                public init(key: String) {
                    apiKey = key
                }
                func getAPIKey() -> String {
                    return self.apiKey
                }
            }
            let apiKeyAuthProvider = BasicAWSAPIKeyAuthProvider(key: apiKey)
            // Initialize the AWS AppSync configuration
            let appSyncConfig = try AWSAppSyncClientConfiguration(url: AppSyncEndpointURL,
                                                                  serviceRegion: AppSyncRegion,
                                                                  apiKeyAuthProvider: apiKeyAuthProvider,
                                                                  databaseURL:databaseURL)
            // Initialize the AWS AppSync client
            appSyncClient = try AWSAppSyncClient(appSyncConfig: appSyncConfig)
            // Set id as the cache key for objects
            appSyncClient?.apolloClient?.cacheKeyForObject = { $0["id"] }
        } catch {
            print("Error initializing appsync client. \(error)")
        }
    }
    
    override func tearDown() {
        super.tearDown()
        deleteAll()
    }

    func deleteAll() {
        guard let appSyncClient = appSyncClient else {
            return
        }

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

            let deleteExpectation = self.expectation(description: "Delete event \(event.id)")
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

    // TODO: Unstable test
    func testSubscription() {
        let successfulSubscriptionExpectation = expectation(description: "Mutation done successfully.")
        let receivedSubscriptionExpectation = self.expectation(description: "Subscription received successfully.")
        
        let addEvent = AddEventMutation(name: DefaultEventTestData.EventName,
                                        when: DefaultEventTestData.EventTime,
                                        where: DefaultEventTestData.EventLocation,
                                        description: DefaultEventTestData.EventDescription)
        var eventId: GraphQLID?
        appSyncClient?.perform(mutation: addEvent) { (result, error) in
            XCTAssertNil(error, "Error expected to be nil, but is not.")
            XCTAssertNotNil(result?.data?.createEvent?.id, "Expected service to return a UUID.")
            XCTAssert(DefaultEventTestData.EventName == result!.data!.createEvent!.name!, "Event names should match.")
            print("Received create event mutation response.")
            
            eventId = result!.data!.createEvent!.id
            
            successfulSubscriptionExpectation.fulfill()
            
        }
        wait(for: [successfulSubscriptionExpectation], timeout: 10.0)
        
        let subscription = try! self.appSyncClient?.subscribe(subscription: NewCommentOnEventSubscription(eventId: eventId!)) { (result, _, error) in
            XCTAssertNil(error, "Error expected to be nil, but is not.")
            print("Received new comment subscription response.")
            receivedSubscriptionExpectation.fulfill()
        }
        XCTAssertNotNil(subscription, "Subscription expected to be non nil.")
        
        // Wait 2 seconds to ensure subscription is active
        DispatchQueue.global().async {
            sleep(2)
            self.appSyncClient?.perform(mutation: CommentOnEventMutation(eventId: eventId!, content: "content", createdAt: "2 pm")) { (result, error) in
                XCTAssertNil(error, "Error expected to be nil, but is not.")
                XCTAssertNotNil(result?.data?.commentOnEvent?.commentId, "Expected service to return a UUID.")
                print("Received create comment mutation response.")
            }
        }
        
        wait(for: [receivedSubscriptionExpectation], timeout: 10.0)
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
    
    /// The test validates if the base query callback gets called 3 times and subscription callback gets called 1 time.
    /// This happens since we have a refresh interval of 10 seconds and the base query is always called from cache in sync.
    /// Then, we cancel the sync operation which has an updated `lasySync` time in the cache.
    /// Once we restart this cancelled sync operation, we call the same sync operation again, and this time it calls the delta query 1 time and the base 2 times, instead of calling base query 3 times.
    func testSyncOperation() {
        deleteAll()
        guard let appSyncClient = appSyncClient else {
            XCTFail("appSyncClient must not be nil")
            return
        }
        
        let successfulMutationExpectation = expectation(description: "Mutation done successfully.")
        
        let addEvent = AddEventMutation(name: DefaultEventTestData.EventName,
                                        when: DefaultEventTestData.EventTime,
                                        where: DefaultEventTestData.EventLocation,
                                        description: DefaultEventTestData.EventDescription)
        var eventId: GraphQLID?
        appSyncClient.perform(mutation: addEvent) { (result, error) in
            XCTAssertNil(error, "Error expected to be nil, but is not.")
            XCTAssertNotNil(result?.data?.createEvent?.id, "Expected service to return a UUID.")
            XCTAssert(DefaultEventTestData.EventName == result!.data!.createEvent!.name!, "Event names should match.")
            print("Received create event mutation response.")
            eventId = result!.data!.createEvent!.id
            successfulMutationExpectation.fulfill()
        }
        wait(for: [successfulMutationExpectation], timeout: 10.0)
        
        let subscriptionExpectation = self.expectation(description: "Subscription callback received successfully.")
        let baseQueryCallback1Expectation = expectation(description: "Base Query 1.1 callback received successfully.")
        let baseQueryCallback2Expectation = expectation(description: "Base Query 1.2 callback received successfully.")
        let baseQueryCallback3Expectation = expectation(description: "Base Query 1.3 callback received successfully.")
        
        let query = ListEventsQuery()
        var counter = 0
        
        var syncWatcher = appSyncClient.sync(baseQuery: query, baseQueryResultHandler: { (result, error) in
            if (counter == 0) {
                baseQueryCallback1Expectation.fulfill()
            } else if counter == 1 {
                baseQueryCallback2Expectation.fulfill()
            } else if counter == 2 {
                baseQueryCallback3Expectation.fulfill()
            } else {
                XCTFail("Expecting only 3 callbacks for sync operation. But got more.")
            }
            counter += 1
        }, subscription: NewCommentOnEventSubscription(eventId: eventId!),
           subscriptionResultHandler: { (result, transaction, error) in
            subscriptionExpectation.fulfill()
        }, deltaQuery: query, deltaQueryResultHandler: { (result, transaction, error) in
            // set up sync configuration to be 10 seconds to test if base query gets called again.
        }, syncConfiguration: SyncConfiguration(baseRefreshIntervalInSeconds: 10))
        
        XCTAssertNotNil(syncWatcher, "sync watcher expected to be non nil.")
        
        // Wait 3 seconds to ensure sync is active
        DispatchQueue.global().async {
            sleep(3)
            self.appSyncClient?.perform(mutation: CommentOnEventMutation(eventId: eventId!, content: "content", createdAt: "2 pm")) { (result, error) in
                XCTAssertNil(error, "Error expected to be nil, but is not.")
                XCTAssertNotNil(result?.data?.commentOnEvent?.commentId, "Expected service to return a UUID.")
                print("Received create comment mutation response.")
            }
        }
        
        XCTAssertNotNil(syncWatcher, "Subscription expected to be non nil.")
        
        wait(for: [baseQueryCallback1Expectation, baseQueryCallback2Expectation, baseQueryCallback3Expectation, subscriptionExpectation], timeout: 20.0)
        
        syncWatcher.cancel()
        
        let restartSubscriptionExpectation = self.expectation(description: "Subscription callback received successfully.")
        let restartBaseQueryCallback1Expectation = expectation(description: "Delta callback received successfully.")
        let restartBaseQueryCallback2Expectation = expectation(description: "Base Query 2.1 callback received successfully.")
        let deltaQueryCallbackExpectation = expectation(description: "Base Query 2.2 callback received successfully.")
        
        counter = 0
        
        syncWatcher = appSyncClient.sync(baseQuery: query, baseQueryResultHandler: { (result, error) in
            if (counter == 0) {
                restartBaseQueryCallback1Expectation.fulfill()
            } else if counter == 1 {
                restartBaseQueryCallback2Expectation.fulfill()
            } else {
                XCTFail("Expecting only 2 callbacks for sync operation. But got more.")
            }
            counter += 1
        }, subscription: NewCommentOnEventSubscription(eventId: eventId!),
           subscriptionResultHandler: { (result, transaction, error) in
            restartSubscriptionExpectation.fulfill()
        }, deltaQuery: query, deltaQueryResultHandler: { (result, transaction, error) in
            // set up sync configuration to be 10 seconds to test if base query gets called again.
            deltaQueryCallbackExpectation.fulfill()
        }, syncConfiguration: SyncConfiguration(baseRefreshIntervalInSeconds: 15))
        
        XCTAssertNotNil(syncWatcher, "sync watcher expected to be non nil.")
        
        // Wait 3 seconds to ensure sync is active
        DispatchQueue.global().async {
            sleep(3)
            self.appSyncClient?.perform(mutation: CommentOnEventMutation(eventId: eventId!, content: "content", createdAt: "2 pm")) { (result, error) in
                XCTAssertNil(error, "Error expected to be nil, but is not.")
                XCTAssertNotNil(result?.data?.commentOnEvent?.commentId, "Expected service to return a UUID.")
                print("Received create comment mutation response.")
            }
        }
        
        XCTAssertNotNil(syncWatcher, "Subscription expected to be non nil.")
        
        wait(for: [restartBaseQueryCallback1Expectation, restartBaseQueryCallback2Expectation, deltaQueryCallbackExpectation, restartSubscriptionExpectation], timeout: 20.0)
    }
}
