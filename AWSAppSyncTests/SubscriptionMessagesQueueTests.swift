//
//  SubscriptionMessagesQueueTests.swift
//  AWSAppSyncTests
//
//  Created by Schmelter, Tim on 12/13/18.
//  Copyright © 2018 Amazon Web Services. All rights reserved.
//

import XCTest
@testable import AWSAppSync

class SubscriptionMessagesQueueTests: XCTestCase {

    func makeComment(eventId: String, commentId: String) -> NewCommentOnEventSubscription.Data.SubscribeToEventComment {
        let comment = NewCommentOnEventSubscription.Data.SubscribeToEventComment(
            eventId: eventId,
            commentId: commentId,
            content: "Comment \(commentId)",
            createdAt: Date().description
        )
        return comment
    }

    func makeResultItem(eventId: String, commentId: String) -> GraphQLResult<NewCommentOnEventSubscription.Data> {
        let comment = makeComment(eventId: eventId, commentId: commentId)
        let data = NewCommentOnEventSubscription.Data(subscribeToEventComments: comment)
        let result = GraphQLResult<NewCommentOnEventSubscription.Data>(
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

        let messagesQueue = SubscriptionMessagesQueue<NewCommentOnEventSubscription>(for: "testOperation1") { (_, _, _) in
            messageNotDelivered.fulfill()
        }

        messagesQueue.stopDelivery()

        let item = makeResultItem(eventId: "Item 1", commentId: "Comment 1")
        messagesQueue.append(item, transaction: nil)

        wait(for: [messageNotDelivered], timeout: 1)
    }

    func test_itemAddedToStartedQueueIsDelivered() {
        let messageDelivered = expectation(description: "Message should be delivered while queue is started")

        let messagesQueue = SubscriptionMessagesQueue<NewCommentOnEventSubscription>(for: "testOperation1") { (_, _, _) in
            messageDelivered.fulfill()
        }

        messagesQueue.startDelivery()

        let item = makeResultItem(eventId: "Item 1", commentId: "Comment 1")
        messagesQueue.append(item, transaction: nil)

        wait(for: [messageDelivered], timeout: 1)
    }

    func test_itemAddedToStoppedQueueIsDeliveredWhenQueueIsStarted() {
        let messageNotDeliveredWhileQueueIsStopped = expectation(description: "Message should not be delivered while queue is stopped")
        messageNotDeliveredWhileQueueIsStopped.isInverted = true

        let messageDeliveredWhenQueueIsStarted = expectation(description: "Message should be delivered after queue is started")

        let messagesQueue = SubscriptionMessagesQueue<NewCommentOnEventSubscription>(for: "testOperation1") { (_, _, _) in
            messageNotDeliveredWhileQueueIsStopped.fulfill()
            messageDeliveredWhenQueueIsStarted.fulfill()
        }

        messagesQueue.stopDelivery()

        let item = makeResultItem(eventId: "Item 1", commentId: "Comment 1")
        messagesQueue.append(item, transaction: nil)

        wait(for: [messageNotDeliveredWhileQueueIsStopped], timeout: 1)

        messagesQueue.startDelivery()

        wait(for: [messageDeliveredWhenQueueIsStarted], timeout: 1)
    }

    // We don't currently publish a limit on the size of the queued subscriptions, so this test arbitrarily
    // sets the queue size to 5,000 items.
    func test_canDrainLargeQueue() {
        var messageDeliveredExpectations = [XCTestExpectation]()

        let messagesQueue = SubscriptionMessagesQueue<NewCommentOnEventSubscription>(for: "testOperation1") { (result, _, _) in
            guard let eventId = result.data?.subscribeToEventComments?.eventId else {
                XCTFail("EventId unexpectedly nil")
                return
            }

            let index = Int(eventId)!
            messageDeliveredExpectations[index].fulfill()
        }

        messagesQueue.stopDelivery()

        // Note that the eventId is simply the string value of the index, to make it easier to assert which
        // expectation we need to fulfill
        for i in 0 ..< 5_000 {
            let item = makeResultItem(eventId: "\(i)", commentId: "Comment \(i)")
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
        let messagesQueue = SubscriptionMessagesQueue<NewCommentOnEventSubscription>(for: "testOperation1") { (result, _, _) in
            guard let eventId = result.data?.subscribeToEventComments?.eventId else {
                XCTFail("EventId unexpectedly nil")
                return
            }

            let index = Int(eventId)!

            if index == expectedIndex {
                messageDeliveredInOrderExpectations[index].fulfill()
            } else {
                XCTFail("Result handler invoked out of order for \(index)")
            }
            expectedIndex += 1
        }

        messagesQueue.stopDelivery()

        // Note that the eventId is simply the string value of the index, to make it easier to assert which
        // expectation we need to fulfill
        for i in 0 ..< 50 {
            let item = makeResultItem(eventId: "\(i)", commentId: "Comment \(i)")
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

        let messagesQueue = SubscriptionMessagesQueue<NewCommentOnEventSubscription>(for: "testOperation1") { (result, _, _) in
            guard let eventId = result.data?.subscribeToEventComments?.eventId else {
                XCTFail("EventId unexpectedly nil")
                return
            }

            let index = Int(eventId)!
            messageDeliveredExpectations[index].fulfill()
        }

        messagesQueue.stopDelivery()

        // Note that the eventId is simply the string value of the index, to make it easier to assert which
        // expectation we need to fulfill
        for i in 0 ..< 5_000 {
            let item = makeResultItem(eventId: "\(i)", commentId: "Comment \(i)")
            messageDeliveredExpectations.append(expectation(description: "Delivered message \(i)"))
            messagesQueue.append(item, transaction: nil)
        }

        // Add the last expectation to be the item added while the queue is draining
        let expectationCount = messageDeliveredExpectations.count
        let itemAddedWhileQueueIsDraining = makeResultItem(eventId: "\(expectationCount)", commentId: "This item was added while the queue was draining")

        let itemAddedWhileQueueIsDrainingShouldBeDelivered = expectation(description: "Item added while queue is draining should be delivered")
        messageDeliveredExpectations.append(itemAddedWhileQueueIsDrainingShouldBeDelivered)

        messagesQueue.startDelivery()

        messagesQueue.append(itemAddedWhileQueueIsDraining, transaction: nil)

        // This shouldn't take 2 full minutes, but depending on the speed of the system this test is running on,
        // it might take > 10 wallclock seconds.
        wait(for: messageDeliveredExpectations, timeout: 120)
    }
}
