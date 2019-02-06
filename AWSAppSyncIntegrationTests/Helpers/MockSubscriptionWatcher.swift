//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
@testable import AWSAppSync

class MockSubscriptionWatcher: MQTTSubscriptionWatcher {
    func connectedCallbackDelegate() {
    }

    let identifier: Int
    let topics: [String]
    let messageCallbackBlock: ((Data) -> Void)?
    let disconnectCallbackBlock: ((Error) -> Void)?
    let deallocBlock: ((MQTTSubscriptionWatcher) -> Void)?

    init(topics: [String],
         deallocBlock:((MQTTSubscriptionWatcher) -> Void)? = nil,
         messageCallbackBlock:((Data) -> Void)? = nil,
         disconnectCallbackBlock:((Error) -> Void)? = nil) {
        self.identifier = NSUUID().hash
        self.topics = topics
        self.deallocBlock = deallocBlock
        self.messageCallbackBlock = messageCallbackBlock
        self.disconnectCallbackBlock = disconnectCallbackBlock
    }

    deinit {
        deallocBlock?(self)
    }

    func getIdentifier() -> Int {
        return identifier
    }
    func getTopics() -> [String] {
        return topics
    }
    func messageCallbackDelegate(data: Data) {
        messageCallbackBlock?(data)
    }
    func disconnectCallbackDelegate(error: Error) {
        disconnectCallbackBlock?(error)
    }
}
