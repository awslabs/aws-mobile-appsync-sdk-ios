//
// Copyright 2010-2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
@testable import AWSAppSyncTestCommon

class MutationOptimisticUpdateTests: XCTestCase {
    static let fetchQueue = DispatchQueue(label: "MutationOptimisticUpdateTests.fetch")
    static let mutationQueue = DispatchQueue(label: "MutationOptimisticUpdateTests.mutations")

    var cacheConfiguration: AWSAppSyncCacheConfiguration!
    let mockHTTPTransport = MockAWSNetworkTransport()

    // Set up a new DB for each test
    override func setUp() {
        let tempDir = FileManager.default.temporaryDirectory
        let rootDirectory = tempDir.appendingPathComponent("MutationOptimisticUpdateTests-\(UUID().uuidString)")
        cacheConfiguration = try! AWSAppSyncCacheConfiguration(withRootDirectory: rootDirectory)
    }

    override func tearDown() {
        MockReachabilityProvidingFactory.clearShared()
        NetworkReachabilityNotifier.clearShared()
    }

    func testMutation_WithOptimisticUpdate_UpdatesEmptyPersistentCache() throws {
        try doMutationWithOptimisticUpdate(usingBackingDatabase: true, afterClearingCaches: false)
    }

    func testMutation_WithOptimisticUpdate_UpdatesEmptyInMemoryCache() throws {
        try doMutationWithOptimisticUpdate(usingBackingDatabase: false, afterClearingCaches: false)
    }

    func testMutation_WithOptimisticUpdate_UpdatesEmptyPersistentCacheAfterClearingCaches() throws {
        try doMutationWithOptimisticUpdate(usingBackingDatabase: true, afterClearingCaches: true)
    }

    func testMutation_WithOptimisticUpdate_UpdatesEmptyInMemoryCacheAfterClearingCaches() throws {
        try doMutationWithOptimisticUpdate(usingBackingDatabase: false, afterClearingCaches: true)
    }

    func testMutation_WithoutOptimisticUpdate_DoesNotUpdateEmptyCache() throws {
        let addPost = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation

        // We will set up a response block that never actually invokes the completion handler. This allows us to
        // examine the state of the local cache before any return values are processed
        let nonDispatchingResponseBlockInvoked = expectation(description: "Non dispatching response block invoked")

        let nonDispatchingResponseBlock: SendOperationResponseBlock<CreatePostWithoutFileUsingParametersMutation> = {
            _, _ in
            nonDispatchingResponseBlockInvoked.fulfill()
        }

        mockHTTPTransport.sendOperationResponseQueue.append(nonDispatchingResponseBlock)

        let appSyncClient = try UnitTestHelpers.makeAppSyncClient(using: mockHTTPTransport, cacheConfiguration: nil)

        appSyncClient.perform(mutation: addPost, queue: MutationOptimisticUpdateTests.mutationQueue)

        let cacheDoesNotHaveOptimisticUpdateResult = expectation(description: "Cache does not return optimistic update result")

        appSyncClient.fetch(
            query: ListPostsQuery(),
            cachePolicy: .returnCacheDataDontFetch,
            queue: MutationOptimisticUpdateTests.fetchQueue
        ) { result, error in
            guard error == nil else {
                XCTFail("Unexpected error querying cache: \(error.debugDescription)")
                return
            }

            guard result?.data?.listPosts == nil else {
                XCTFail("Result unexpectedly not-nil querying optimistically updated cache: \(result.debugDescription)")
                return
            }

            cacheDoesNotHaveOptimisticUpdateResult.fulfill()
        }

        wait(
            for: [
                nonDispatchingResponseBlockInvoked,
                cacheDoesNotHaveOptimisticUpdateResult
            ],
            timeout: 1.0)
    }

    func testMutation_WithOptimisticUpdate_UpdatesPopulatedCache() throws {
        let addPost = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation

        // First response should be a query response from the "server" that will populate the local cache.
        let idFromServer = "FROM-SERVER-\(UUID().uuidString)"
        let serverResponse = UnitTestHelpers.makeListPostsResponseBody(withId: idFromServer)
        mockHTTPTransport.sendOperationResponseQueue.append(serverResponse)

        // We will set up a response block that never actually invokes the completion handler. This allows us to
        // examine the state of the local cache before any return values are processed
        let nonDispatchingResponseBlockInvoked = expectation(description: "Non dispatching response block invoked")

        let nonDispatchingResponseBlock: SendOperationResponseBlock<CreatePostWithoutFileUsingParametersMutation> = {
            _, _ in
            nonDispatchingResponseBlockInvoked.fulfill()
        }

        mockHTTPTransport.sendOperationResponseQueue.append(nonDispatchingResponseBlock)

        let appSyncClient = try UnitTestHelpers.makeAppSyncClient(using: mockHTTPTransport, cacheConfiguration: nil)

        let initialQueryPerformed = expectation(description: "Initial listPosts query performed")
        // Note that we specify a `.fetchIgnoringCacheData` policy to ensure we only get our mocked response,
        // which Apoll will write to the cache
        appSyncClient.fetch(query: ListPostsQuery(), cachePolicy: .fetchIgnoringCacheData, queue: MutationOptimisticUpdateTests.fetchQueue) { result, error in
            defer {
                initialQueryPerformed.fulfill()
            }
            guard error == nil else {
                XCTFail("Unexpected error performing initial query: \(error!.localizedDescription)")
                return
            }

        }

        wait(for: [initialQueryPerformed], timeout: 1.0)

        let idFromOptimisticUpdate = "TEMPORARY-\(UUID().uuidString)"
        let newPost = ListPostsQuery.Data.ListPost(
            id: idFromOptimisticUpdate,
            author: addPost.author,
            title: addPost.title,
            content: addPost.content,
            ups: addPost.ups ?? 0,
            downs: addPost.downs ?? 0)

        let optimisticUpdatePerformed = expectation(description: "Optimistic update performed")
        appSyncClient.perform(
            mutation: addPost,
            queue: MutationOptimisticUpdateTests.mutationQueue,
            optimisticUpdate: { transaction in
                guard let transaction = transaction else {
                    XCTFail("Optimistic update transaction unexpectedly nil")
                    return
                }

                do {
                    try transaction.update(query: ListPostsQuery()) { data in
                        guard var listPosts = data.listPosts else {
                            XCTFail("listPosts unexpectedly nil in optimistic update--expecting results of initial query")
                            return
                        }
                        listPosts.append(newPost)
                        data.listPosts = listPosts
                    }
                    // The `update` is synchronous, so we can fulfill after the block completes
                    optimisticUpdatePerformed.fulfill()
                } catch {
                    XCTFail("Unexpected error performing optimistic update: \(error)")
                }
        })

        let fetchFromCacheComplete = expectation(description: "Fetch from cache is complete")

        appSyncClient.fetch(
            query: ListPostsQuery(),
            cachePolicy: .returnCacheDataDontFetch,
            queue: MutationOptimisticUpdateTests.fetchQueue
        ) { result, error in
            defer {
                fetchFromCacheComplete.fulfill()
            }

            guard error == nil else {
                XCTFail("Unexpected error querying optimistically updated cache: \(error.debugDescription)")
                return
            }

            guard
                let listPosts = result?.data?.listPosts
                else {
                    XCTFail("Result unexpectedly nil querying optimistically updated cache")
                    return
            }

            let posts = listPosts.compactMap({$0})
            // Don't assert the order;
            XCTAssertNotNil(posts.first { $0.id == idFromServer })
            XCTAssertNotNil(posts.first { $0.id == idFromOptimisticUpdate })
        }

        wait(
            for: [
                nonDispatchingResponseBlockInvoked,
                optimisticUpdatePerformed,
                fetchFromCacheComplete
            ],
            timeout: 1.0)
    }

    // MARK - Utility methods

    func doMutationWithOptimisticUpdate(usingBackingDatabase: Bool,
                                        afterClearingCaches: Bool) throws {
        let addPost = DefaultTestPostData.defaultCreatePostWithoutFileUsingParametersMutation

        // We will set up a response block that never actually invokes the completion handler. This allows us to
        // examine the state of the local cache before any return values are processed
        let nonDispatchingResponseBlockInvoked = expectation(description: "Non dispatching response block invoked")

        let nonDispatchingResponseBlock: SendOperationResponseBlock<CreatePostWithoutFileUsingParametersMutation> = {
            _, _ in
            nonDispatchingResponseBlockInvoked.fulfill()
        }

        mockHTTPTransport.sendOperationResponseQueue.append(nonDispatchingResponseBlock)

        let resolvedCacheConfiguration: AWSAppSyncCacheConfiguration? = usingBackingDatabase
            ? cacheConfiguration
            : nil

        let appSyncClient = try UnitTestHelpers.makeAppSyncClient(using: mockHTTPTransport, cacheConfiguration: resolvedCacheConfiguration)

        if afterClearingCaches {
            try appSyncClient.clearCaches()
        }

        let newPost = ListPostsQuery.Data.ListPost(
            id: "TEMPORARY-\(UUID().uuidString)",
            author: addPost.author,
            title: addPost.title,
            content: addPost.content,
            ups: addPost.ups ?? 0,
            downs: addPost.downs ?? 0)

        let optimisticUpdatePerformed = expectation(description: "Optimistic update performed")
        appSyncClient.perform(
            mutation: addPost,
            queue: MutationOptimisticUpdateTests.mutationQueue,
            optimisticUpdate: { transaction in
                guard let transaction = transaction else {
                    XCTFail("Optimistic update transaction unexpectedly nil")
                    return
                }
                do {
                    try transaction.update(query: ListPostsQuery()) { data in
                        var listPosts: [ListPostsQuery.Data.ListPost?] = data.listPosts ?? []
                        listPosts.append(newPost)
                        data.listPosts = listPosts
                    }
                    // The `update` is synchronous, so we can fulfill after the block completes
                    optimisticUpdatePerformed.fulfill()
                } catch {
                    XCTFail("Unexpected error performing optimistic update: \(error)")
                }
        })

        wait(
            for: [
                optimisticUpdatePerformed
            ],
            timeout: 1.0)

        let cacheHasOptimisticUpdateResult = expectation(description: "Cache returns optimistic update result")

        appSyncClient.fetch(
            query: ListPostsQuery(),
            cachePolicy: .returnCacheDataDontFetch,
            queue: MutationOptimisticUpdateTests.fetchQueue
        ) { result, error in
            guard error == nil else {
                XCTFail("Unexpected error querying optimistically updated cache: \(error.debugDescription)")
                return
            }

            guard
                let listPosts = result?.data?.listPosts
                else {
                    XCTFail("Result unexpectedly nil querying optimistically updated cache")
                    return
            }

            let posts = listPosts.compactMap({$0})
            guard let firstPost = posts.first else {
                XCTFail("No posts in optimistically updated cache result")
                return
            }

            XCTAssertEqual(firstPost.id, newPost.id)
            cacheHasOptimisticUpdateResult.fulfill()
        }

        wait(
            for: [
                nonDispatchingResponseBlockInvoked,
                cacheHasOptimisticUpdateResult
            ],
            timeout: 1.0)
    }

}
