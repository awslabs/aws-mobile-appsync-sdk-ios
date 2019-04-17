//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import XCTest
@testable import AWSAppSync
@testable import AWSAppSyncTestCommon

extension AWSS3ObjectProtocol {
    var asOnUpvotePostFile: OnUpvotePostSubscription.Data.OnUpvotePost.File {
        let result = OnUpvotePostSubscription.Data.OnUpvotePost.File(
            bucket: getBucketName(),
            key: getKeyName(),
            region: getRegion()
        )
        return result
    }
}

class SubscriptionMessagesQueueStressTests: XCTestCase {

    func makeSubscriptionResultItem(id: GraphQLID = UUID().uuidString,
                                    author: String = "PostAuthor",
                                    title: String = "",
                                    content: String = "",
                                    url: String = "",
                                    ups: Int = 0,
                                    downs: Int = 0,
                                    file: S3Object? = nil,
                                    createdDate: String? = nil,
                                    awsDs: DeltaAction? = nil) -> GraphQLResult<OnUpvotePostSubscription.Data> {
        let onUpvotePost = OnUpvotePostSubscription.Data.OnUpvotePost(
            id: id,
            author: author,
            title: title,
            content: content,
            url: url,
            ups: ups,
            downs: downs,
            file: file?.asOnUpvotePostFile,
            createdDate: createdDate,
            awsDs: awsDs
        )

        let data = OnUpvotePostSubscription.Data(onUpvotePost: onUpvotePost)
        let result = GraphQLResult<OnUpvotePostSubscription.Data>(
            data: data,
            errors: nil,
            source: .server,
            dependentKeys: nil
        )
        return result
    }

    // Sets the queue with 5,000 items, which we see above takes > 10 seconds, and then immediately attempt
    // to add an item. We expect the newly added item to be delivered once the
    func test_itemAddedToDrainingQueueWillEventuallyBeDelivered() {
        var messageDeliveredExpectations = [XCTestExpectation]()

        let messagesQueue = SubscriptionMessagesQueue<OnUpvotePostSubscription>(for: "testOperation1") { (result, _, _) in
            guard let id = result.data?.onUpvotePost?.id else {
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

    // We don't currently publish a limit on the size of the queued subscriptions, so this test arbitrarily
    // sets the queue size to 5,000 items.
    func test_canDrainLargeQueue() {
        var messageDeliveredExpectations = [XCTestExpectation]()

        let messagesQueue = SubscriptionMessagesQueue<OnUpvotePostSubscription>(for: "testOperation1") { (result, _, _) in
            guard let id = result.data?.onUpvotePost?.id else {
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

}
