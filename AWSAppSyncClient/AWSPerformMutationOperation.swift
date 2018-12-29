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

final class AWSPerformMutationOperation<Mutation: GraphQLMutation>: AsynchronousOperation, Cancellable {

    private let appSyncClient: AWSAppSyncClient
    private let handlerQueue: DispatchQueue
    private let mutation: Mutation
    private let mutationConflictHandler: MutationConflictHandler<Mutation>?
    private let mutationResultHandler: OperationResultHandler<Mutation>?

    var identifier: String?
    var operationCompletionBlock: ((AWSPerformMutationOperation, Error?) -> Void)?

    init(
        appSyncClient: AWSAppSyncClient,
        handlerQueue: DispatchQueue,
        mutation: Mutation,
        mutationConflictHandler: MutationConflictHandler<Mutation>?,
        mutationResultHandler: OperationResultHandler<Mutation>?) {
        self.appSyncClient = appSyncClient
        self.handlerQueue = handlerQueue
        self.mutation = mutation
        self.mutationConflictHandler = mutationConflictHandler
        self.mutationResultHandler = mutationResultHandler
    }

    private var networkTask: Cancellable?

    private func _send(
        _ resultHandler: OperationResultHandler<Mutation>?) -> Cancellable? {
        if let s3Object = AWSRequestBuilder.s3Object(from: mutation.variables) {
            appSyncClient.performMutationWithS3Object(
                operation: mutation,
                s3Object: s3Object,
                conflictResolutionBlock: mutationConflictHandler,
                dispatchGroup: nil,
                handlerQueue: handlerQueue,
                resultHandler: resultHandler)

            return nil
        } else {
            return appSyncClient.send(
                operation: mutation,
                context: nil,
                conflictResolutionBlock: mutationConflictHandler,
                dispatchGroup: nil,
                handlerQueue: handlerQueue,
                resultHandler: resultHandler)
        }
    }

    private func _notifyCompletion(_ result: GraphQLResult<Mutation.Data>?, error: Error?) {
        operationCompletionBlock?(self, error)

        if let mutationResultHandler = mutationResultHandler {
            handlerQueue.async {
                mutationResultHandler(result, error)
            }
        }
    }

    // MARK: Operation

    override func start() {
        if isCancelled {
            state = .finished
            return
        }

        state = .executing

        networkTask = _send { (result, error) in
            if error == nil {
                self._notifyCompletion(result, error: nil)
                self.state = .finished

                return
            }

            if self.isCancelled {
                self.state = .finished
                return
            }

            self._notifyCompletion(result, error: error)
            self.state = .finished
        }
    }

    // MARK: Cancellable

    override func cancel() {
        super.cancel()
        networkTask?.cancel()
    }

    // MARK: - CustomStringConvertible

    override var description: String {
        var desc: String = "<\(self):\(mutation.self)"
        desc.append("\toffline identifier: \(identifier ?? "NA")")
        desc.append("\tstate: \(state)")
        desc.append(">")

        return desc
    }
}
