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
    
    var CognitoIdentityPoolId = "YOUR_POOL_ID"
    var CognitoIdentityRegion: AWSRegionType = .USEast1
    var AppSyncRegion: AWSRegionType = .USEast1
    var AppSyncEndpointURL: URL = URL(string: "https://localhost")! // Your AppSync endpoint here.
    let apiKey = "YOUR_API_KEY"
    let database_name = "appsync-local-db"
    var appSyncClient: AWSAppSyncClient?
    
    let EventName = "Testing Event"
    let EventTime = "July 26 2018, 12:30"
    let EventLocation = "Seattle, WA"
    let EventDescription = "Event Description"
    
    static let ENDPOINT_KEY = "AppSyncEndpoint"
    static let ENDPOINT_REGION_KEY = "AppSyncRegion"
    static let COGNITO_POOL_ID_KEY = "CognitoIdentityPoolId"
    static let COGNITO_POOL_ID_REGION_KEY = "CognitoIdentityPoolRegion"
    
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
            
            CognitoIdentityPoolId = jsonObject[AWSAppSyncTests.COGNITO_POOL_ID_KEY]! as! String
            CognitoIdentityRegion = (jsonObject[AWSAppSyncTests.COGNITO_POOL_ID_REGION_KEY]! as! String).aws_regionTypeValue()
            let endpoint = jsonObject[AWSAppSyncTests.ENDPOINT_KEY]! as! String
            AppSyncEndpointURL = URL(string: endpoint)!
            AppSyncRegion = (jsonObject[AWSAppSyncTests.ENDPOINT_REGION_KEY]! as! String).aws_regionTypeValue()
            
        } else if (CognitoIdentityPoolId != "YOUR_POOL_ID" && AppSyncEndpointURL.absoluteString != "https://localhost" ) {
                XCTFail(TestSetupErrorMessage)
                return
        } else {
            XCTFail(TestSetupErrorMessage)
            return
        }
        
        // Set up Amazon Cognito credentials
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: CognitoIdentityRegion,
                                                                identityPoolId: CognitoIdentityPoolId)
        credentialsProvider.clearCredentials()
        credentialsProvider.clearKeychain()
        // You can choose your database location, accessible by the SDK
        let databaseURL = URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent(database_name)
        
        do {
            AWSDDLog.sharedInstance.logLevel = .error
            AWSDDLog.add(AWSDDTTYLogger.sharedInstance) 
            
            // Initialize the AWS AppSync configuration
            let appSyncConfig = try AWSAppSyncClientConfiguration(url: AppSyncEndpointURL,
                                                                  serviceRegion: AppSyncRegion,
                                                                  credentialsProvider: credentialsProvider,
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
        let query = ListEventsQuery(limit: 99)
        let successfulExpectation = expectation(description: "Fetch done successfully.")

        appSyncClient?.fetch(query: query, cachePolicy: .fetchIgnoringCacheData) { (result, error) in
            XCTAssertNil(error, "Error expected to be nil, but is not.")
            XCTAssertNotNil(result?.data?.listEvents?.items, "Items array should not be nil.")
            guard let events = result?.data?.listEvents?.items else { return }

            for event in events {
                self.appSyncClient?.perform(mutation: DeleteEventMutation(id: event!.id))
            }
            successfulExpectation.fulfill()
        }

        // Wait for the mutations(delete event actions) to complete.
        wait(for: [successfulExpectation], timeout: 5.0)
    }

    func testAppSynClientConfigurationAwsCredentialsProvider() {
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
            let appSyncClient = try AWSAppSyncClient(appSyncConfig: appSyncConfig)

            XCTAssertNotNil(appSyncConfig, "AppSyncConfig cannot be nil")
            XCTAssertNotNil(appSyncClient, "AppSyncClient cannot be nil")
        } catch {
            print("Error initializing appsync client. \(error)")
        }
    }

    func testAppSynClientConfigurationApiKeyAuthProvider() {
        // You can choose your database location, accessible by the SDK
        let databaseURL = URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent(database_name)

        do {
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
            let appSyncClient = try AWSAppSyncClient(appSyncConfig: appSyncConfig)

            XCTAssertNotNil(appSyncConfig, "AppSyncConfig cannot be nil")
            XCTAssertNotNil(appSyncClient, "AppSyncClient cannot be nil")
        } catch {
            print("Error initializing appsync client. \(error)")
        }
    }

    func testAppSynClientConfigurationOidcAuthProvider() {
        // You can choose your database location, accessible by the SDK
        let databaseURL = URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent(database_name)

        do {
            // Create AWSApiKeyAuthProvider
            class BasicOidcAuthProvider: AWSOIDCAuthProvider {
                func getLatestAuthToken() -> String {
                    return "token"
                }
            }
            let oidcAuthProvider = BasicOidcAuthProvider()

            // Initialize the AWS AppSync configuration
            let appSyncConfig = try AWSAppSyncClientConfiguration(url: AppSyncEndpointURL,
                                                                  serviceRegion: AppSyncRegion,
                                                                  oidcAuthProvider: oidcAuthProvider,
                                                                  databaseURL:databaseURL)
            // Initialize the AWS AppSync client
            let appSyncClient = try AWSAppSyncClient(appSyncConfig: appSyncConfig)

            XCTAssertNotNil(appSyncConfig, "AppSyncConfig cannot be nil")
            XCTAssertNotNil(appSyncClient, "AppSyncClient cannot be nil")
        } catch {
            print("Error initializing appsync client. \(error)")
        }
    }

    func testQuery() {
        let successfulMutationEventExpectation = expectation(description: "Mutation done successfully.")
        
        let addEvent = AddEventMutation(name: EventName,
                                        when: EventTime,
                                        where: EventLocation,
                                        description: EventDescription)
        
        appSyncClient?.perform(mutation: addEvent) { (result, error) in
            XCTAssertNil(error, "Error expected to be nil, but is not.")
            XCTAssertNotNil(result?.data?.createEvent?.id, "Expected service to return a UUID.")
            XCTAssert(self.EventName == result!.data!.createEvent!.name!, "Event names should match.")
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
        
        let addEvent = AddEventMutation(name: EventName,
                                        when: EventTime,
                                        where: EventLocation,
                                        description: EventDescription)
        
        appSyncClient?.perform(mutation: addEvent) { (result, error) in
            XCTAssertNil(error, "Error expected to be nil, but is not.")
            XCTAssertNotNil(result?.data?.createEvent?.id, "Expected service to return a UUID.")
            XCTAssert(self.EventName == result!.data!.createEvent!.name!, "Event names should match.")
            successfulMutationEventExpectation.fulfill()
        }
        
        wait(for: [successfulMutationEventExpectation], timeout: 5.0)
    }
    
    func testSubscription() {
        let successfulSubscriptionExpectation = expectation(description: "Mutation done successfully.")
        let receivedSubscriptionExpectation = self.expectation(description: "Subscription received successfully.")
        
        let addEvent = AddEventMutation(name: EventName,
                                        when: EventTime,
                                        where: EventLocation,
                                        description: EventDescription)
        var eventId: GraphQLID?
        appSyncClient?.perform(mutation: addEvent) { (result, error) in
            XCTAssertNil(error, "Error expected to be nil, but is not.")
            XCTAssertNotNil(result?.data?.createEvent?.id, "Expected service to return a UUID.")
            XCTAssert(self.EventName == result!.data!.createEvent!.name!, "Event names should match.")
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
    
    func testOptimisticWriteWithQueryParameter() {
        let successfulMutationEventExpectation = expectation(description: "Mutation done successfully.")
        let successfulMutationEvent2Expectation = expectation(description: "Mutation done successfully.")
        let successfulOptimisticWriteExpectation = expectation(description: "Optimisitc write done successfully.")
        let successfulQueryFetchExpectation = expectation(description: "Query fetch should success.")
        let successfulLocalQueryFetchExpectation = expectation(description: "Local query fetch should success.")
        
        let addEvent = AddEventMutation(name: EventName,
                                        when: EventTime,
                                        where: EventLocation,
                                        description: EventDescription)
        
        appSyncClient?.perform(mutation: addEvent) { (result, error) in
            XCTAssertNil(error, "Error expected to be nil, but is not.")
            XCTAssertNotNil(result?.data?.createEvent?.id, "Expected service to return a UUID.")
            XCTAssert(self.EventName == result!.data!.createEvent!.name!, "Event names should match.")
            successfulMutationEventExpectation.fulfill()
        }
        
        wait(for: [successfulMutationEventExpectation], timeout: 5.0)
        
        let fetchQuery = ListEventsQuery(limit: 10)
        
        var cacheCount = 0
        
        appSyncClient?.fetch(query: fetchQuery, cachePolicy: .fetchIgnoringCacheData, resultHandler: { (result, error) in
            XCTAssertNil(error, "Error expected to be nil, but is not.")
            XCTAssertNotNil(result?.data?.listEvents?.items, "Items array should not be empty.")
            XCTAssertTrue(result!.data!.listEvents!.items!.count > 0, "Expected service to return at least 1 event.")
            cacheCount = result!.data!.listEvents!.items!.count
            successfulQueryFetchExpectation.fulfill()
        })
        
        wait(for: [successfulQueryFetchExpectation], timeout: 5.0)
        
        appSyncClient?.perform(mutation: addEvent, optimisticUpdate: { (transaction) in
            do {
            try transaction?.update(query: fetchQuery, { (data) in
                data.listEvents?.items!.append(ListEventsQuery.Data.ListEvent.Item.init(id: "RandomId", description: self.EventDescription, name: self.EventName, when: self.EventTime, where: self.EventLocation, comments: nil))
            })
            successfulOptimisticWriteExpectation.fulfill()
            } catch {
                
            }
        }, resultHandler: { (result, error) in
            XCTAssertNil(error, "Error expected to be nil, but is not.")
            XCTAssertNotNil(result?.data?.createEvent?.id, "Expected service to return a UUID.")
            XCTAssert(self.EventName == result!.data!.createEvent!.name!, "Event names should match.")
            successfulMutationEvent2Expectation.fulfill()
        })
        
        wait(for: [successfulOptimisticWriteExpectation, successfulMutationEvent2Expectation], timeout: 5.0)
        
        appSyncClient?.fetch(query: fetchQuery, cachePolicy: .returnCacheDataDontFetch, resultHandler: { (result, error) in
            XCTAssertNil(error, "Error expected to be nil, but is not.")
            XCTAssertNotNil(result?.data?.listEvents?.items, "Items array should not be empty.")
            XCTAssertTrue(result!.data!.listEvents!.items!.count > 0, "Expected cache to return at least 1 event.")
            XCTAssertTrue(result!.data!.listEvents!.items!.count == cacheCount + 1)
            successfulLocalQueryFetchExpectation.fulfill()
        })
        
        wait(for: [successfulLocalQueryFetchExpectation], timeout: 5.0)
    }
    
    func testSubscription_Stress() {
        let mutationsDone = expectation(description: "Mutations done successfully.")
        var eventsCreated: [GraphQLID] = []
        var subsWatchers: [Cancellable] = []
        
        for _ in 0..<18 {
            let addEvent = AddEventMutation(name: EventName,
                                            when: EventTime,
                                            where: EventLocation,
                                            description: EventDescription)
            appSyncClient?.perform(mutation: addEvent) { (result, error) in
                XCTAssertNil(error, "Error expected to be nil, but is not.")
                XCTAssertNotNil(result?.data?.createEvent?.id, "Expected service to return a UUID.")
                XCTAssert(self.EventName == result!.data!.createEvent!.name!, "Event names should match.")
                eventsCreated.append(result!.data!.createEvent!.id)
                if eventsCreated.count == 18 {
                    mutationsDone.fulfill()
                }
            }
        }
        
        wait(for: [mutationsDone], timeout: 20.0)
        XCTAssertTrue(eventsCreated.count == 18)
        
        let subsExpectation = expectation(description: "18 subs should receive messages.")
        var receivedComments: [GraphQLID] = []
        
        for i in 0..<eventsCreated.count {
            let expectationNum = i
            let watcher = try? appSyncClient?.subscribe(subscription: NewCommentOnEventSubscription(eventId: eventsCreated[i])) { (result, _, error) in
                XCTAssertNil(error, "Error expected to be nil, but is not.")
                print("Received new comment subscription response. \(expectationNum)")
                receivedComments.append(result!.data!.subscribeToEventComments!.eventId)
                if receivedComments.count == 18 {
                    subsExpectation.fulfill()
                }
            }
            subsWatchers.append(watcher!!)
            print("Started subscription \(i)")
        }
        sleep(10)
        
        for i in 0..<eventsCreated.count {
            let expectationNum = i
            appSyncClient?.perform(mutation: CommentOnEventMutation(eventId: eventsCreated[i],
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
    
    func testInvalidAPIKeyAuth() {
        let databaseURL = URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent(database_name)
        var invalidConfigAppSyncClient: AWSAppSyncClient?
        do {
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
            invalidConfigAppSyncClient = try AWSAppSyncClient(appSyncConfig: appSyncConfig)
            
            XCTAssertNotNil(appSyncConfig, "AppSyncConfig cannot be nil")
            XCTAssertNotNil(invalidConfigAppSyncClient, "AppSyncClient cannot be nil")
        } catch {
            print("Error initializing appsync client. \(error)")
        }
        let failedMutationEventExpectation = expectation(description: "Mutation failed as expected.")
        
        let addEvent = AddEventMutation(name: EventName,
                                        when: EventTime,
                                        where: EventLocation,
                                        description: EventDescription)
        
        invalidConfigAppSyncClient?.perform(mutation: addEvent) { (result, error) in
            XCTAssertNil(result, "Result expected to be nil, but is not.")
            XCTAssertNotNil(error, "Expected service to return auth error.")
            let appsyncError = error as? AWSAppSyncClientError
            XCTAssertNotNil(appsyncError, "The error should be of type AWSAppSyncError")
            XCTAssertTrue(appsyncError?.response?.statusCode == 403, "Error response should be 403 HTTP Code")
            failedMutationEventExpectation.fulfill()
        }
        
        wait(for: [failedMutationEventExpectation], timeout: 5.0)
    }
    
    func testInvalidOIDCProvider() {
        var invalidConfigAppSyncClient: AWSAppSyncClient?
        // You can choose your database location, accessible by the SDK
        let databaseURL = URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent(database_name)
        
        do {
            // Create AWSApiKeyAuthProvider
            class BasicOidcAuthProvider: AWSOIDCAuthProvider {
                func getLatestAuthToken() -> String {
                    return "token"
                }
            }
            let oidcAuthProvider = BasicOidcAuthProvider()
            
            // Initialize the AWS AppSync configuration
            let appSyncConfig = try AWSAppSyncClientConfiguration(url: AppSyncEndpointURL,
                                                                  serviceRegion: AppSyncRegion,
                                                                  oidcAuthProvider: oidcAuthProvider,
                                                                  databaseURL:databaseURL)
            // Initialize the AWS AppSync client
            invalidConfigAppSyncClient = try AWSAppSyncClient(appSyncConfig: appSyncConfig)
            
            XCTAssertNotNil(appSyncConfig, "AppSyncConfig cannot be nil")
            XCTAssertNotNil(appSyncClient, "AppSyncClient cannot be nil")
        } catch {
            print("Error initializing appsync client. \(error)")
        }
        let failedMutationEventExpectation = expectation(description: "Mutation failed as expected.")
        
        let addEvent = AddEventMutation(name: EventName,
                                        when: EventTime,
                                        where: EventLocation,
                                        description: EventDescription)
        
        invalidConfigAppSyncClient?.perform(mutation: addEvent) { (result, error) in
            XCTAssertNil(result, "Result expected to be nil, but is not.")
            XCTAssertNotNil(error, "Expected service to return auth error.")
            let appsyncError = error as? AWSAppSyncClientError
            XCTAssertNotNil(appsyncError, "The error should be of type AWSAppSyncError")
            XCTAssertTrue(appsyncError?.response?.statusCode == 403, "Error response should be 403 HTTP Code")
            failedMutationEventExpectation.fulfill()
        }
        
        wait(for: [failedMutationEventExpectation], timeout: 5.0)
    }
    
    func testInvalidCredentials() {
        var invalidConfigAppSyncClient: AWSAppSyncClient?
        // Set up invalids static credentials
        let credentialsProvider = AWSStaticCredentialsProvider(accessKey: "AKIAIAMINVALID", secretKey: "ABCDINVALIDSECRETSECRET ")
        // You can choose your database location, accessible by the SDK
        let databaseURL = URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent(database_name)
        
        do {
            // Initialize the AWS AppSync configuration
            let appSyncConfig = try AWSAppSyncClientConfiguration(url: AppSyncEndpointURL,
                                                                  serviceRegion: AppSyncRegion,
                                                                  credentialsProvider: credentialsProvider,
                                                                  databaseURL:databaseURL)
            // Initialize the AWS AppSync client
            invalidConfigAppSyncClient = try AWSAppSyncClient(appSyncConfig: appSyncConfig)
            
            XCTAssertNotNil(appSyncConfig, "AppSyncConfig cannot be nil")
            XCTAssertNotNil(appSyncClient, "AppSyncClient cannot be nil")
        } catch {
            print("Error initializing appsync client. \(error)")
        }
        let failedMutationEventExpectation = expectation(description: "Mutation failed as expected.")
        
        let addEvent = AddEventMutation(name: EventName,
                                        when: EventTime,
                                        where: EventLocation,
                                        description: EventDescription)
        
        invalidConfigAppSyncClient?.perform(mutation: addEvent) { (result, error) in
            XCTAssertNil(result, "Result expected to be nil, but is not.")
            XCTAssertNotNil(error, "Expected service to return auth error.")
            let appsyncError = error as? AWSAppSyncClientError
            XCTAssertNotNil(appsyncError, "The error should be of type AWSAppSyncError")
            XCTAssertTrue(appsyncError?.response?.statusCode == 403, "Error response should be 403 HTTP Code")
            failedMutationEventExpectation.fulfill()
        }
        wait(for: [failedMutationEventExpectation], timeout: 5.0)
    }
}
