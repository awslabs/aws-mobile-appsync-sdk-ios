//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
@testable import AWSAppSync

typealias SendDataResponseBlock = (Data, SendDataCompletionHandler?) -> Void
typealias SendDataCompletionHandler = (JSONObject?, Error?) -> Void

typealias SendOperationResponseBlock<Operation: GraphQLOperation> = (Operation, @escaping SendOperationCompletionHandler<Operation>) -> Void
typealias SendOperationCompletionHandler<Operation: GraphQLOperation> = (GraphQLResponse<Operation>?, Error?) -> Void

class MockAWSNetworkTransport: AWSNetworkTransport {
    // MARK: - send(data:completionHandler:)

    /// Subsequent invocations of `send(data:completionHandler:)` will respond using the next item in the queue, regardless
    /// of the values in `sendOperationHandlerResultData` or `sendOperationHandlerError`.
    ///
    /// Note: This queue is not thread-safe
    ///
    /// Valid types to add to the queue are:
    /// - Error: Causes the next `send` operation to invoke `completionHandler(nil, error)`
    /// - JSONObject: Causes the next `send` operation to invoke
    ///   `completionHandler(GraphQLResponse(operation: operation, body: jsonObject), nil)`
    /// - SendOperationResponseBlock: Causes the next `send` operation to invoke
    ///   `sendOperationBlock(operation, completionHandler)`
    var sendDataResponseQueue = [Any]()

    /// The body of the result to be returned in the `completionHandler` of `send(data:completionHandler:)` if no items are
    /// in `sendOperationResponseQueue`
    var sendDataHandlerResponseBody: JSONObject? = nil

    /// The error to be returned in the `completionHandler` of `send(data:completionHandler:)` if no items are in
    /// `sendOperationResponseQueue`
    var sendDataHandlerError: Error? = nil

    /// A cancellable to be the return value of `send(operation:completionHandler:)`
    var sendDataCancellable = MockCancellable()

    /// When invoked, calls `completionHandler` asynchronously on the global queue
    func send(data: Data, completionHandler: SendDataCompletionHandler?) {
        if sendDataResponseQueue.count > 0 {
            completeSendDataWithResponseQueue(data: data, completionHandler: completionHandler)
        } else {
            completeSendDataWithLocalProperties(completionHandler: completionHandler)
        }
    }

    private func completeSendDataWithResponseQueue(data: Data, completionHandler: SendDataCompletionHandler?) {
        let item = sendDataResponseQueue.removeFirst()

        switch item {
        case let error as Error:
            DispatchQueue.global().async {
                completionHandler?(nil, error)
            }

        case let responseBody as JSONObject:
            DispatchQueue.global().async {
                completionHandler?(responseBody, nil)
            }

        case let sendDataHandlerBlock as SendDataResponseBlock:
            sendDataHandlerBlock(data, completionHandler)

        default:
            // Do nothing
            print("Unknown type in response queue")
        }
    }

    private func completeSendDataWithLocalProperties(completionHandler: SendDataCompletionHandler?) {
        guard let completionHandler = completionHandler else {
            return
        }

        if let error = sendDataHandlerError {
            DispatchQueue.global().async {
                completionHandler(nil, error)
            }
        } else if let sendDataHandlerResponseBody = sendDataHandlerResponseBody {
            DispatchQueue.global().async {
                completionHandler(sendDataHandlerResponseBody, nil)
            }
        } else {
            completionHandler(nil, nil)
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

    /// Delay to simulate slow network or otherwise block calls
    var operationResponseDelay: UInt32 = 0

    /// Subsequent invocations of `send(operation:completionHandler:)` will respond using the next item in the queue, regardless
    /// of the values in `sendOperationHandlerResultData` or `sendOperationHandlerError`.
    ///
    /// Note: This queue is not thread-safe
    ///
    /// Valid types to add to the queue are:
    /// - Error: Causes the next `send` operation to invoke `completionHandler(nil, error)`
    /// - JSONObject: Causes the next `send` operation to invoke
    ///   `completionHandler(GraphQLResponse(operation: operation, body: jsonObject), nil)`
    /// - SendOperationResponseBlock: Causes the next `send` operation to invoke
    ///   `sendOperationBlock(operation, completionHandler)`
    var sendOperationResponseQueue = [Any]()

    /// The body of the result to be returned in the `completionHandler` of `send(operation:completionHandler:)` if no items are
    /// in `sendOperationResponseQueue`
    var sendOperationHandlerResponseBody: JSONObject? = nil

    /// The error to be returned in the `completionHandler` of `send(operation:completionHandler:)` if no items are in
    /// `sendOperationResponseQueue`
    var sendOperationHandlerError: Error? = nil

    /// A cancellable to be the return value of `send(operation:completionHandler:)`
    var sendOperationCancellable = MockCancellable()

    /// When invoked, calls `completionHandler` asynchronously on the global queue
    func send<Operation: GraphQLOperation>(operation: Operation, completionHandler: @escaping SendOperationCompletionHandler<Operation>) -> Cancellable {

        sleep(operationResponseDelay)

        if sendOperationResponseQueue.count > 0 {
            completeSendOperationWithResponseQueue(operation: operation, completionHandler: completionHandler)
        } else {
            completeSendOperationWithLocalProperties(operation: operation, completionHandler: completionHandler)
        }

        return sendOperationCancellable
    }

    private func completeSendOperationWithResponseQueue<Operation: GraphQLOperation>(
        operation: Operation,
        completionHandler: @escaping SendOperationCompletionHandler<Operation>) {

        let item = sendOperationResponseQueue.removeFirst()

        switch item {
        case let error as Error:
            DispatchQueue.global().async {
                completionHandler(nil, error)
            }

        case let responseBody as JSONObject:
            let response = GraphQLResponse<Operation>(operation: operation, body: responseBody)
            DispatchQueue.global().async {
                completionHandler(response, nil)
            }

        case let sendOperationHandlerBlock as SendOperationResponseBlock<Operation>:
            sendOperationHandlerBlock(operation, completionHandler)

        default:
            // Do nothing
            print("Unknown type in response queue")
        }
    }

    private func completeSendOperationWithLocalProperties<Operation: GraphQLOperation>(
        operation: Operation,
        completionHandler: @escaping SendOperationCompletionHandler<Operation>) {

        if let error = sendOperationHandlerError {
            DispatchQueue.global().async {
                completionHandler(nil, error)
            }
            return
        }

        let body = sendOperationHandlerResponseBody ?? [:]
        let response = GraphQLResponse<Operation>(operation: operation, body: body)
        DispatchQueue.global().async {
            completionHandler(response, nil)
        }
    }

}
