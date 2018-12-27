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
