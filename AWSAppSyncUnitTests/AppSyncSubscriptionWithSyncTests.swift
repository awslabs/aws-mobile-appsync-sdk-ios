//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import XCTest
@testable import AWSAppSync
@testable import AWSAppSyncTestCommon

class AppSyncSubscriptionWithSyncTests: XCTestCase {
    
    var appsyncClient: AWSAppSyncClient!
    let queue = DispatchQueue(label: "com.amazon.aws.test")
    let syncConfiguration = SyncConfiguration(baseRefreshIntervalInSeconds: 2)
    
    let emptyQuery = AWSAppSyncClient.EmptyQuery()
    let emptyQueryHandler: OperationResultHandler<AWSAppSyncClient.EmptyQuery> = {(_, _) in}
    
    let listPostsQuery = ListPostsQuery()
    let listQueryHandler: OperationResultHandler<ListPostsQuery> = {(_, _) in}
    
    private let getQuery = GraphGetQuery(id: "2")
    private let getQueryHandler: OperationResultHandler<GraphGetQuery> = {(_, _) in}
    
    let deltaQueryHandler: DeltaQueryResultHandler<ListPostsQuery> = {(_, _, _) in}
    let emptyDeltaQueryHandler: DeltaQueryResultHandler<AWSAppSyncClient.EmptyQuery> = {(_, _, _) in}
    
    let subscription = OnUpvotePostSubscription(id: UUID().uuidString)
    let subscriptionResultHandler: SubscriptionResultHandler<OnUpvotePostSubscription> = { (_, _, _) in }
    
    let emptySubscription = AWSAppSyncClient.EmptySubscription.init()
    let emptySubscriptionResultHandler: SubscriptionResultHandler<AWSAppSyncClient.EmptySubscription> = { (_, _, _) in }
    
    override func setUp() {
        do {
            let mockHTTPTransport = MockAWSNetworkTransport()
            appsyncClient = try UnitTestHelpers.makeAppSyncClient(
                using: mockHTTPTransport,
                cacheConfiguration: AWSAppSyncCacheConfiguration())
        } catch {
            XCTFail("Error thrown during initialization: \(error)")
        }
    }
    
    func testWithAllValuesFilled() {
        
        let subscriptionWithSync = AppSyncSubscriptionWithSync(
            appSyncClient: appsyncClient,
            baseQuery: listPostsQuery,
            deltaQuery: listPostsQuery,
            subscription: subscription,
            baseQueryHandler: listQueryHandler,
            deltaQueryHandler: deltaQueryHandler,
            subscriptionResultHandler: subscriptionResultHandler,
            subscriptionMetadataCache: nil,
            syncConfiguration: syncConfiguration,
            handlerQueue: queue)
        let result = subscriptionWithSync.getOperationHash()
        XCTAssertNotNil(result, "Should produce a non nil hash when all fields are present.")
    }
    
    func testWithOneEmptyValue() {
        
        let syncWithEmptyBaseQuery = AppSyncSubscriptionWithSync(
            appSyncClient: appsyncClient,
            baseQuery: emptyQuery,
            deltaQuery: listPostsQuery,
            subscription: subscription,
            baseQueryHandler: emptyQueryHandler,
            deltaQueryHandler: deltaQueryHandler,
            subscriptionResultHandler: subscriptionResultHandler,
            subscriptionMetadataCache: nil,
            syncConfiguration: syncConfiguration,
            handlerQueue: queue)
        
        let syncWithEmptyDeltaQuery = AppSyncSubscriptionWithSync(
            appSyncClient: appsyncClient,
            baseQuery: listPostsQuery,
            deltaQuery: emptyQuery,
            subscription: subscription,
            baseQueryHandler: listQueryHandler,
            deltaQueryHandler: emptyDeltaQueryHandler,
            subscriptionResultHandler: subscriptionResultHandler,
            subscriptionMetadataCache: nil,
            syncConfiguration: syncConfiguration,
            handlerQueue: queue)
        
        let syncWithEmptySubscription = AppSyncSubscriptionWithSync(
            appSyncClient: appsyncClient,
            baseQuery: listPostsQuery,
            deltaQuery: listPostsQuery,
            subscription: emptySubscription,
            baseQueryHandler: listQueryHandler,
            deltaQueryHandler: deltaQueryHandler,
            subscriptionResultHandler: emptySubscriptionResultHandler,
            subscriptionMetadataCache: nil,
            syncConfiguration: syncConfiguration,
            handlerQueue: queue)
        
        let emptyBaseQueryResult = syncWithEmptyBaseQuery.getOperationHash()
        let emptyDeltaQueryResult = syncWithEmptyDeltaQuery.getOperationHash()
        let emptySubscriptionResult = syncWithEmptySubscription.getOperationHash()
        
        XCTAssertNotEqual(emptyBaseQueryResult, emptyDeltaQueryResult, "Hash value should be different for the two sync operation")
        XCTAssertNotEqual(emptyBaseQueryResult, emptySubscriptionResult, "Hash value should be different for the two sync operation")
        XCTAssertNotEqual(emptyDeltaQueryResult, emptySubscriptionResult, "Hash value should be different for the two sync operation")
    }
    
    func testWithTwoEmptyValues() {
        
        let syncWithBaseQueryNonNull = AppSyncSubscriptionWithSync(
            appSyncClient: appsyncClient,
            baseQuery: listPostsQuery,
            deltaQuery: emptyQuery,
            subscription: emptySubscription,
            baseQueryHandler: listQueryHandler,
            deltaQueryHandler: emptyDeltaQueryHandler,
            subscriptionResultHandler: emptySubscriptionResultHandler,
            subscriptionMetadataCache: nil,
            syncConfiguration: syncConfiguration,
            handlerQueue: queue)
        
        let syncWithDeltaQueryNonNull = AppSyncSubscriptionWithSync(
            appSyncClient: appsyncClient,
            baseQuery: emptyQuery,
            deltaQuery: listPostsQuery,
            subscription: emptySubscription,
            baseQueryHandler: emptyQueryHandler,
            deltaQueryHandler: deltaQueryHandler,
            subscriptionResultHandler: emptySubscriptionResultHandler,
            subscriptionMetadataCache: nil,
            syncConfiguration: syncConfiguration,
            handlerQueue: queue)
        
        let syncWithSubscriptionNonNull = AppSyncSubscriptionWithSync(
            appSyncClient: appsyncClient,
            baseQuery: emptyQuery,
            deltaQuery: emptyQuery,
            subscription: subscription,
            baseQueryHandler: emptyQueryHandler,
            deltaQueryHandler: emptyDeltaQueryHandler,
            subscriptionResultHandler: subscriptionResultHandler,
            subscriptionMetadataCache: nil,
            syncConfiguration: syncConfiguration,
            handlerQueue: queue)
        
        let syncWithBaseQueryNonNullResult = syncWithBaseQueryNonNull.getOperationHash()
        let syncWithDeltaQueryNonNullResult = syncWithDeltaQueryNonNull.getOperationHash()
        let syncWithSubscriptionNonNullResult = syncWithSubscriptionNonNull.getOperationHash()
        
        XCTAssertNotEqual(syncWithBaseQueryNonNullResult, syncWithDeltaQueryNonNullResult, "Hash value should be different for the two sync operation")
        XCTAssertNotEqual(syncWithBaseQueryNonNullResult, syncWithSubscriptionNonNullResult, "Hash value should be different for the two sync operation")
        XCTAssertNotEqual(syncWithDeltaQueryNonNullResult, syncWithSubscriptionNonNullResult, "Hash value should be different for the two sync operation")
    }

    func testWithSameVariablesUnordered() {
        
        let subscriptionWithSync1 = AppSyncSubscriptionWithSync(
            appSyncClient: appsyncClient,
            baseQuery: getQuery,
            deltaQuery: emptyQuery,
            subscription: emptySubscription,
            baseQueryHandler: getQueryHandler,
            deltaQueryHandler: emptyDeltaQueryHandler,
            subscriptionResultHandler: emptySubscriptionResultHandler,
            subscriptionMetadataCache: nil,
            syncConfiguration: syncConfiguration,
            handlerQueue: queue)
        
        let subscriptionWithSync2 = AppSyncSubscriptionWithSync(
            appSyncClient: appsyncClient,
            baseQuery: getQuery,
            deltaQuery: emptyQuery,
            subscription: emptySubscription,
            baseQueryHandler: getQueryHandler,
            deltaQueryHandler: emptyDeltaQueryHandler,
            subscriptionResultHandler: emptySubscriptionResultHandler,
            subscriptionMetadataCache: nil,
            syncConfiguration: syncConfiguration,
            handlerQueue: queue)
        
        let result1 = subscriptionWithSync1.getOperationHash()
        let result2 = subscriptionWithSync2.getOperationHash()
        XCTAssertEqual(result1, result2, "Hash value should be equal for the two sync operation")
    }
    
    func testWithSameBaseDeltaQuery() {
        
        let subscriptionWithSync = AppSyncSubscriptionWithSync(
            appSyncClient: appsyncClient,
            baseQuery: listPostsQuery,
            deltaQuery: listPostsQuery,
            subscription: emptySubscription,
            baseQueryHandler: listQueryHandler,
            deltaQueryHandler: deltaQueryHandler,
            subscriptionResultHandler: emptySubscriptionResultHandler,
            subscriptionMetadataCache: nil,
            syncConfiguration: syncConfiguration,
            handlerQueue: queue)
        
        let result = subscriptionWithSync.getOperationHash()
        XCTAssertNotNil(result, "Should produce a non nil hash when all fields are present.")
    }
}

private class GraphGetQuery: GraphQLQuery {
    public static let operationString = "query GetQuery($id: ID!) {\n  getID(id: $id) {\n __typename\n }\n}"
    public var id: GraphQLID
    
    public init(id: GraphQLID) {
        self.id = id
    }
    
    public var variables: GraphQLMap? {
        return ["id": id, "id2": "2", "time": "123"]
    }
    
    public struct Data: GraphQLSelectionSet {

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
            self.snapshot = snapshot
        }

        public static let selections: [GraphQLSelection] = [
            GraphQLField("getID", arguments: ["id": GraphQLVariable("id")], type: .object(
                [
                    GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
                    GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self)))
                ])),
        ]
    }
}
