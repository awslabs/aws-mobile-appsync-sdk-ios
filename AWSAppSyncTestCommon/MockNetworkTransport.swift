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

class MockNetworkTransport: AWSNetworkTransport {
    // MARK: - send(data:completionHandler:)

    /// The result to be returned in the `completionHandler` of `send(data:completionHandler:)`
    var sendDataHandlerResult: JSONObject?

    /// The error to be returned in the `completionHandler` of `send(data:completionHandler:)`
    var sendDataHandlerError: Error?

    /// When invoked, calls `completionHandler` asynchronously on the global queue
    func send(data: Data, completionHandler: ((JSONObject?, Error?) -> Void)?) {
        DispatchQueue.global().async {
            completionHandler?(self.sendDataHandlerResult, self.sendDataHandlerError)
        }
    }

    // MARK: - sendSubscriptionRequest(operation:completionHandler:)

    /// The error to be thrown upon invocation of `sendSubscriptionRequest(operation:completionHandler:)`
    var sendSubscriptionErrorToThrow: Error?

    /// The result to be returned in the `completionHandler` of `sendSubscriptionRequest(operation:completionHandler:)`
    var sendSubscriptionHandlerResult: JSONObject?

    /// The error to be returned in the `completionHandler` of `sendSubscriptionRequest(operation:completionHandler:)`
    var sendSubscriptionHandlerError: Error?

    /// A cancellable to be the return value of `sendSubscriptionRequest(operation:completionHandler:)`
    var sendSubscriptionCancellable: Cancellable = MockCancellable()

    /// When invoked, calls `completionHandler` asynchronously on the global queue
    func sendSubscriptionRequest<Operation>(operation: Operation, completionHandler: @escaping (JSONObject?, Error?) -> Void) throws -> Cancellable {
        if let errorToThrow = sendSubscriptionErrorToThrow {
            throw errorToThrow
        }

        DispatchQueue.global().async {
            completionHandler(self.sendSubscriptionHandlerResult, self.sendSubscriptionHandlerError)
        }

        return sendSubscriptionCancellable
    }

    // MARK: - send(operation:completionHandler:)

    /// The result to be returned in the `completionHandler` of `send(operation:completionHandler:)`
    var sendOperationHandlerResult: Any?

    /// The error to be returned in the `completionHandler` of `send(operation:completionHandler:)`
    var sendOperationHandlerError: Error?

    /// A cancellable to be the return value of `send(operation:completionHandler:)`
    var sendOperationCancellable = MockCancellable()

    /// When invoked, calls `completionHandler` asynchronously on the global queue
    func send<Operation: GraphQLOperation>(operation: Operation, completionHandler: @escaping (GraphQLResponse<Operation>?, Error?) -> Void) -> Cancellable {

        let result = sendOperationHandlerResult as? GraphQLResponse<Operation>
        DispatchQueue.global().async {
            completionHandler(result, self.sendOperationHandlerError)
        }

        return sendOperationCancellable
    }

}
