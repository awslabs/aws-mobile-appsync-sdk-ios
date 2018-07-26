//
//  AWSAppSyncTests.swift
//  AWSAppSyncTests
//

import XCTest
@testable import AWSAppSync
@testable import AWSCore

/// The test class uses the `EventsApp` starter schema from AWS AppSync Console which can be created easily by selecting an option in the console. It uses AWS_IAM for auth.
class AWSAppSyncTests: XCTestCase {
    
    static let CognitoIdentityPoolId = "YOUR_COGNITO_IDENTITY_POOL_ID"
    static let CognitoIdentityRegion: AWSRegionType = .USEast1
    static let AppSyncRegion: AWSRegionType = .USEast1
    static let AppSyncEndpointURL: URL = URL(string: "YOUR_GRAPHQL_ENDPOINT")!
    static let database_name = "appsync-local-db"
    static var appSyncClient: AWSAppSyncClient?
    
    static let EventName = "Testing Event"
    static let EventTime = "July 26 2018, 12:30"
    static let EventLocation = "Seattle, WA"
    static let EventDescription = "Event Description"
    
    override class func setUp() {
        superclass()?.setUp()
        // Set up Amazon Cognito credentials
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: CognitoIdentityRegion,
                                                                identityPoolId: CognitoIdentityPoolId)
        // You can choose your database location, accessible by the SDK
        let databaseURL = URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent(database_name)
        
        do {
            // Initialize the AWS AppSync configuration
            let appSyncConfig = try AWSAppSyncClientConfiguration(url: AppSyncEndpointURL,
                                                                  serviceRegion: AppSyncRegion,
                                                                  credentialsProvider: credentialsProvider,
                                                                  databaseURL:databaseURL)
            // Initialize the AWS AppSync client
            appSyncClient = try AWSAppSyncClient(appSyncConfig: appSyncConfig)
            // Set id as the cache key for objects
            appSyncClient?.apolloClient?.cacheKeyForObject = { $0["id"] }
            
            AWSDDLog.sharedInstance.logLevel = .verbose
            AWSDDLog.add(AWSDDTTYLogger.sharedInstance) // TTY = Xcode console
        } catch {
            print("Error initializing appsync client. \(error)")
        }
    }
    
    override class func tearDown() {
        superclass()?.tearDown()
        let query = ListEventsQuery(limit: 99)
        AWSAppSyncTests.appSyncClient?.fetch(query: query, cachePolicy: .fetchIgnoringCacheData) { (result, error) in
            XCTAssertNil(error, "Error expected to be nil, but is not.")
            XCTAssertNotNil(result?.data?.listEvents?.items, "Items array should not be empty.")
            XCTAssertTrue(result!.data!.listEvents!.items!.count > 0, "Expected service to return at least 1 event.")
            guard let events = result?.data?.listEvents?.items else { return }
            
            for event in events {
                AWSAppSyncTests.appSyncClient?.perform(mutation: DeleteEventMutation(id: event!.id))
            }
        }
        // Wait for the mutations(delete event actions) to complete.
        sleep(5)
    }
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testQuery() {
        let successfulMutationEventExpectation = expectation(description: "Mutation done successfully.")
        
        let addEvent = AddEventMutation(name: AWSAppSyncTests.EventName,
                                        when: AWSAppSyncTests.EventTime,
                                        where: AWSAppSyncTests.EventLocation,
                                        description: AWSAppSyncTests.EventDescription)
        
        AWSAppSyncTests.appSyncClient?.perform(mutation: addEvent) { (result, error) in
            XCTAssertNil(error, "Error expected to be nil, but is not.")
            XCTAssertNotNil(result?.data?.createEvent?.id, "Expected service to return a UUID.")
            XCTAssert(AWSAppSyncTests.EventName == result!.data!.createEvent!.name!, "Event names should match.")
            successfulMutationEventExpectation.fulfill()
        }
        
        wait(for: [successfulMutationEventExpectation], timeout: 5.0)
        
        let query = ListEventsQuery()
        
        let successfullistEventExpectation = expectation(description: "Mutation done successfully.")
        
        AWSAppSyncTests.appSyncClient?.fetch(query: query, cachePolicy: .fetchIgnoringCacheData) { (result, error) in
            XCTAssertNil(error, "Error expected to be nil, but is not.")
            XCTAssertNotNil(result?.data?.listEvents?.items, "Items array should not be empty.")
            XCTAssertTrue(result!.data!.listEvents!.items!.count > 0, "Expected service to return at least 1 event.")
            successfullistEventExpectation.fulfill()
        }
        
        wait(for: [successfullistEventExpectation], timeout: 5.0)
    }
    
    func testMutation() {
        let successfulMutationEventExpectation = expectation(description: "Mutation done successfully.")
        
        let addEvent = AddEventMutation(name: AWSAppSyncTests.EventName,
                                        when: AWSAppSyncTests.EventTime,
                                        where: AWSAppSyncTests.EventLocation,
                                        description: AWSAppSyncTests.EventDescription)
        
        AWSAppSyncTests.appSyncClient?.perform(mutation: addEvent) { (result, error) in
            XCTAssertNil(error, "Error expected to be nil, but is not.")
            XCTAssertNotNil(result?.data?.createEvent?.id, "Expected service to return a UUID.")
            XCTAssert(AWSAppSyncTests.EventName == result!.data!.createEvent!.name!, "Event names should match.")
            successfulMutationEventExpectation.fulfill()
        }
        
        wait(for: [successfulMutationEventExpectation], timeout: 5.0)
    }
    
    func testSubscription() {
        let successfulSubscriptionExpectation = expectation(description: "Mutation done successfully.")
        let receivedSubscriptioExpectation = self.expectation(description: "Subscription received successfully.")
        
        let addEvent = AddEventMutation(name: AWSAppSyncTests.EventName,
                                        when: AWSAppSyncTests.EventTime,
                                        where: AWSAppSyncTests.EventLocation,
                                        description: AWSAppSyncTests.EventDescription)
        
        AWSAppSyncTests.appSyncClient?.perform(mutation: addEvent) { (result, error) in
            XCTAssertNil(error, "Error expected to be nil, but is not.")
            XCTAssertNotNil(result?.data?.createEvent?.id, "Expected service to return a UUID.")
            XCTAssert(AWSAppSyncTests.EventName == result!.data!.createEvent!.name!, "Event names should match.")
            print("Received create event mutation response.")
            
            let eventId = result!.data!.createEvent!.id
            
            let _ = try? AWSAppSyncTests.appSyncClient?.subscribe(subscription: NewCommentOnEventSubscription(eventId: eventId)) { (result, _, error) in
                XCTAssertNil(error, "Error expected to be nil, but is not.")
                print("Received new comment subscription response.")
                receivedSubscriptioExpectation.fulfill()
            }
            // Wait 2 seconds to ensure subscription is active
            sleep(2)
            AWSAppSyncTests.appSyncClient?.perform(mutation: CommentOnEventMutation(eventId: eventId, content: "content", createdAt: "2 pm")) { (result, error) in
                XCTAssertNil(error, "Error expected to be nil, but is not.")
                XCTAssertNotNil(result?.data?.commentOnEvent?.commentId, "Expected service to return a UUID.")
                print("Received create comment mutation response.")
            }
            successfulSubscriptionExpectation.fulfill()
        }
        
        wait(for: [successfulSubscriptionExpectation, receivedSubscriptioExpectation], timeout: 10.0)
    }
    
    func testSubscription_Stress() {
        let m1 = expectation(description: "Mutation done successfully.")
        let m2 = expectation(description: "Mutation done successfully.")
        let m3 = expectation(description: "Mutation done successfully.")
        let m4 = expectation(description: "Mutation done successfully.")
        let m5 = expectation(description: "Mutation done successfully.")
        let m6 = expectation(description: "Mutation done successfully.")
        let m7 = expectation(description: "Mutation done successfully.")
        let m8 = expectation(description: "Mutation done successfully.")
        let m9 = expectation(description: "Mutation done successfully.")
        let m10 = expectation(description: "Mutation done successfully.")
        let m11 = expectation(description: "Mutation done successfully.")
        let m12 = expectation(description: "Mutation done successfully.")
        let m13 = expectation(description: "Mutation done successfully.")
        let m14 = expectation(description: "Mutation done successfully.")
        let m15 = expectation(description: "Mutation done successfully.")
        let m16 = expectation(description: "Mutation done successfully.")
        let m17 = expectation(description: "Mutation done successfully.")
        let m18 = expectation(description: "Mutation done successfully.")
        let expectations = [m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15, m16, m17, m18]
        var eventsCreated: [GraphQLID] = []
        
        for i in 0..<expectations.count {
            let expectationNum = i
            let addEvent = AddEventMutation(name: AWSAppSyncTests.EventName,
                                            when: AWSAppSyncTests.EventTime,
                                            where: AWSAppSyncTests.EventLocation,
                                            description: AWSAppSyncTests.EventDescription)
            AWSAppSyncTests.appSyncClient?.perform(mutation: addEvent) { (result, error) in
                XCTAssertNil(error, "Error expected to be nil, but is not.")
                XCTAssertNotNil(result?.data?.createEvent?.id, "Expected service to return a UUID.")
                XCTAssert(AWSAppSyncTests.EventName == result!.data!.createEvent!.name!, "Event names should match.")
                eventsCreated.append(result!.data!.createEvent!.id)
                expectations[expectationNum].fulfill()
            }
        }
        
        waitForExpectations(timeout: 20.0) { (error) in
            XCTAssertNil(error)
        }
        
        XCTAssertTrue(eventsCreated.count == 18)
        
        let subsExpectation = expectation(description: "18 subs")
        
        var receivedComments: [GraphQLID] = []
        
        for i in 0..<eventsCreated.count {
            let expectationNum = i
            let _ = try? AWSAppSyncTests.appSyncClient?.subscribe(subscription: NewCommentOnEventSubscription(eventId: eventsCreated[i])) { (result, _, error) in
                XCTAssertNil(error, "Error expected to be nil, but is not.")
                print("Received new comment subscription response. \(expectationNum)")
                receivedComments.append(result!.data!.subscribeToEventComments!.eventId)
                if receivedComments.count == 18 {
                    subsExpectation.fulfill()
                }
            }
            print("Started subscription \(i)")
            sleep(1)
        }
        sleep(10)
        
        for i in 0..<eventsCreated.count {
            let expectationNum = i
            AWSAppSyncTests.appSyncClient?.perform(mutation: CommentOnEventMutation(eventId: eventsCreated[i],
                                                                                    content: "content",
                                                                                    createdAt: "2 pm")) { (result, error) in
                XCTAssertNil(error, "Error expected to be nil, but is not.")
                XCTAssertNotNil(result?.data?.commentOnEvent?.commentId, "Expected service to return a UUID.")
                print("Received create comment mutation response. \(expectationNum)")
            }
            print("Performed Mutation: \(i)")
        }
        
        wait(for: [subsExpectation], timeout: 20.0)
        
        XCTAssertTrue(receivedComments.count == 18, "Expected 18 but was \(receivedComments.count)")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
