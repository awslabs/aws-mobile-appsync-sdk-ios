//
//  SubscriptionMessagesQueueTests.swift
//  AWSAppSyncTests
//
//  Created by Schmelter, Tim on 12/13/18.
//  Copyright © 2018 Amazon Web Services. All rights reserved.
//

import XCTest
@testable import AWSAppSync
@testable import AWSAppSyncTestCommon

extension AWSS3ObjectProtocol {
    var asCreatePostWithFileUsingInputTypeMutationFile: CreatePostWithFileUsingInputTypeMutation.Data.CreatePostWithFileUsingInputType.File {
        let result = CreatePostWithFileUsingInputTypeMutation.Data.CreatePostWithFileUsingInputType.File(
            bucket: getBucketName(),
            key: getKeyName(),
            region: getRegion()
        )
        return result
    }

    var asOnDeltaPostFile: OnDeltaPostSubscription.Data.OnDeltaPost.File {
        let result = OnDeltaPostSubscription.Data.OnDeltaPost.File(
            bucket: getBucketName(),
            key: getKeyName(),
            region: getRegion()
        )
        return result
    }

    var asUpdatePostWithFileUsingInputTypeMutationFile: UpdatePostWithFileUsingInputTypeMutation.Data.UpdatePostWithFileUsingInputType.File {
        let result = UpdatePostWithFileUsingInputTypeMutation.Data.UpdatePostWithFileUsingInputType.File(
            bucket: getBucketName(),
            key: getKeyName(),
            region: getRegion()
        )
        return result
    }
}

class SubscriptionMessagesQueueTests: XCTestCase {

    func makeSubscriptionResultItem(id: GraphQLID = UUID().uuidString,
                                    author: String = "PostAuthor",
                                    title: String = "",
                                    content: String = "",
                                    url: String = "",
                                    ups: Int? = nil,
                                    downs: Int? = nil,
                                    file: S3Object? = nil,
                                    createdDate: String? = nil,
                                    awsDs: DeltaAction? = nil) -> GraphQLResult<OnDeltaPostSubscription.Data> {
        let onDeltaPost = OnDeltaPostSubscription.Data.OnDeltaPost(
            id: id,
            author: author,
            title: title,
            content: content,
            url: url,
            ups: ups,
            downs: downs,
            file: file?.asOnDeltaPostFile,
            createdDate: createdDate,
            awsDs: awsDs
        )

        let data = OnDeltaPostSubscription.Data(onDeltaPost: onDeltaPost)
        let result = GraphQLResult<OnDeltaPostSubscription.Data>(
            data: data,
            errors: nil,
            source: .server,
            dependentKeys: nil
        )
        return result
    }

    func test_itemAddedToStoppedQueueIsNotDelivered() {
        let messageNotDelivered = expectation(description: "Message should not be delivered while queue is stopped")
        messageNotDelivered.isInverted = true

        let messagesQueue = SubscriptionMessagesQueue<OnDeltaPostSubscription>(for: "testOperation1") { (_, _, _) in
            messageNotDelivered.fulfill()
        }

        messagesQueue.stopDelivery()

        let item = makeSubscriptionResultItem()
        messagesQueue.append(item, transaction: nil)

        wait(for: [messageNotDelivered], timeout: 1)
    }

    func test_itemAddedToStartedQueueIsDelivered() {
        let messageDelivered = expectation(description: "Message should be delivered while queue is started")

        let messagesQueue = SubscriptionMessagesQueue<OnDeltaPostSubscription>(for: "testOperation1") { (_, _, _) in
            messageDelivered.fulfill()
        }

        messagesQueue.startDelivery()

        let item = makeSubscriptionResultItem(id: "Item 1")
        messagesQueue.append(item, transaction: nil)

        wait(for: [messageDelivered], timeout: 1)
    }

    func test_itemAddedToStoppedQueueIsDeliveredWhenQueueIsStarted() {
        let messageNotDeliveredWhileQueueIsStopped = expectation(description: "Message should not be delivered while queue is stopped")
        messageNotDeliveredWhileQueueIsStopped.isInverted = true

        let messageDeliveredWhenQueueIsStarted = expectation(description: "Message should be delivered after queue is started")

        let messagesQueue = SubscriptionMessagesQueue<OnDeltaPostSubscription>(for: "testOperation1") { (_, _, _) in
            messageNotDeliveredWhileQueueIsStopped.fulfill()
            messageDeliveredWhenQueueIsStarted.fulfill()
        }

        messagesQueue.stopDelivery()

        let item = makeSubscriptionResultItem(id: "Item 1")
        messagesQueue.append(item, transaction: nil)

        wait(for: [messageNotDeliveredWhileQueueIsStopped], timeout: 1)

        messagesQueue.startDelivery()

        wait(for: [messageDeliveredWhenQueueIsStarted], timeout: 1)
    }

    // We don't currently publish a limit on the size of the queued subscriptions, so this test arbitrarily
    // sets the queue size to 5,000 items.
    func test_canDrainLargeQueue() {
        var messageDeliveredExpectations = [XCTestExpectation]()

        let messagesQueue = SubscriptionMessagesQueue<OnDeltaPostSubscription>(for: "testOperation1") { (result, _, _) in
            guard let id = result.data?.onDeltaPost?.id else {
                XCTFail("Id unexpectedly nil")
                return
            }

            let index = Int(id)!
            messageDeliveredExpectations[index].fulfill()
        }

        messagesQueue.stopDelivery()

        // Note that the id is simply the string value of the index, to make it easier to assert which
        // expectation we need to fulfill
        for i in 0 ..< 5_000 {
            let item = makeSubscriptionResultItem(id: "\(i)")
            messageDeliveredExpectations.append(expectation(description: "Delivered message \(i)"))
            messagesQueue.append(item, transaction: nil)
        }

        messagesQueue.startDelivery()

        // This shouldn't take 2 full minutes, but depending on the speed of the system this test is running on,
        // it might take > 10 wallclock seconds.
        wait(for: messageDeliveredExpectations, timeout: 120)
    }

    func test_resultHandlerIsInvokedInOrder() {
        var messageDeliveredInOrderExpectations = [XCTestExpectation]()

        var expectedIndex = 0
        let messagesQueue = SubscriptionMessagesQueue<OnDeltaPostSubscription>(for: "testOperation1") { (result, _, _) in
            guard let id = result.data?.onDeltaPost?.id else {
                XCTFail("id unexpectedly nil")
                return
            }

            let index = Int(id)!

            if index == expectedIndex {
                messageDeliveredInOrderExpectations[index].fulfill()
            } else {
                XCTFail("Result handler invoked out of order for \(index)")
            }
            expectedIndex += 1
        }

        messagesQueue.stopDelivery()

        // Note that the id is simply the string value of the index, to make it easier to assert which
        // expectation we need to fulfill
        for i in 0 ..< 50 {
            let item = makeSubscriptionResultItem(id: "\(i)")
            messageDeliveredInOrderExpectations.append(expectation(description: "Result handler invoked in order for \(i)"))
            messagesQueue.append(item, transaction: nil)
        }

        messagesQueue.startDelivery()

        wait(for: messageDeliveredInOrderExpectations, timeout: 10)

    }

    // Sets the queue with 5,000 items, which we see above takes > 10 seconds, and then immediately attempt
    // to add an item. We expect the newly added item to be delivered once the
    func test_itemAddedToDrainingQueueWillEventuallyBeDelivered() {
        var messageDeliveredExpectations = [XCTestExpectation]()

        let messagesQueue = SubscriptionMessagesQueue<OnDeltaPostSubscription>(for: "testOperation1") { (result, _, _) in
            guard let id = result.data?.onDeltaPost?.id else {
                XCTFail("Id unexpectedly nil")
                return
            }

            let index = Int(id)!
            messageDeliveredExpectations[index].fulfill()
        }

        messagesQueue.stopDelivery()

        // Note that the id is simply the string value of the index, to make it easier to assert which
        // expectation we need to fulfill
        for i in 0 ..< 5_000 {
            let item = makeSubscriptionResultItem(id: "\(i)")
            messageDeliveredExpectations.append(expectation(description: "Delivered message \(i)"))
            messagesQueue.append(item, transaction: nil)
        }

        // Add the last expectation to be the item added while the queue is draining
        let expectationCount = messageDeliveredExpectations.count
        let itemAddedWhileQueueIsDraining = makeSubscriptionResultItem(id: "\(expectationCount)")

        let itemAddedWhileQueueIsDrainingShouldBeDelivered = expectation(description: "Item added while queue is draining should be delivered")
        messageDeliveredExpectations.append(itemAddedWhileQueueIsDrainingShouldBeDelivered)

        messagesQueue.startDelivery()

        messagesQueue.append(itemAddedWhileQueueIsDraining, transaction: nil)

        // This shouldn't take 2 full minutes, but depending on the speed of the system this test is running on,
        // it might take > 10 wallclock seconds.
        wait(for: messageDeliveredExpectations, timeout: 120)
    }
}
