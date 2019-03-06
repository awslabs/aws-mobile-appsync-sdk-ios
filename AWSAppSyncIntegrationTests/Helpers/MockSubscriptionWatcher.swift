//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
@testable import AWSAppSync

class MockSubscriptionWatcher: MQTTSubscriptionWatcher, CustomStringConvertible {

    let identifier: Int
    let topics: [String]
    let messageCallbackBlock: ((Data) -> Void)?
    let disconnectCallbackBlock: ((Error) -> Void)?
    let deallocBlock: ((MQTTSubscriptionWatcher) -> Void)?
    let statusChangeCallbackBlock: ((AWSIoTMQTTStatus) -> Void)?
    let subscriptionAcknowledgementCallbackBlock: (() -> Void)?

    init(topics: [String],
         deallocBlock:((MQTTSubscriptionWatcher) -> Void)? = nil,
         messageCallbackBlock:((Data) -> Void)? = nil,
         disconnectCallbackBlock:((Error) -> Void)? = nil,
         statusChangeCallbackBlock: ((AWSIoTMQTTStatus) -> Void)? = nil,
         subscriptionAcknowledgementCallbackBlock: (() -> Void)? = nil
        ) {
        self.identifier = NSUUID().hash
        self.topics = topics
        self.deallocBlock = deallocBlock
        self.messageCallbackBlock = messageCallbackBlock
        self.disconnectCallbackBlock = disconnectCallbackBlock
        self.statusChangeCallbackBlock = statusChangeCallbackBlock
        self.subscriptionAcknowledgementCallbackBlock = subscriptionAcknowledgementCallbackBlock
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

    func statusChangeDelegate(status: AWSIoTMQTTStatus) {
        statusChangeCallbackBlock?(status)
    }

    func subscriptionAcknowledgementDelegate() {
        subscriptionAcknowledgementCallbackBlock?()
    }

    @available(*, deprecated, message: "This will be removed when we remove connectedCallbackDelegate from MQTTSubscriptionWatcher")
    func connectedCallbackDelegate() {
    }

    var description: String {
        return "\(type(of: self)): \(getIdentifier())"
    }
}
