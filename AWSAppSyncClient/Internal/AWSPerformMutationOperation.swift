//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

final class AWSPerformMutationOperation<Mutation: GraphQLMutation>: AsynchronousOperation, Cancellable {
    private weak var appSyncClient: AWSAppSyncClient?
    private let handlerQueue: DispatchQueue
    private let mutation: Mutation
    private let mutationConflictHandler: MutationConflictHandler<Mutation>?
    private let mutationResultHandler: OperationResultHandler<Mutation>?

    var identifier: String?
    var operationCompletionBlock: ((AWSPerformMutationOperation, Error?) -> Void)?

    init(
        appSyncClient: AWSAppSyncClient?,
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

    private func send(_ resultHandler: OperationResultHandler<Mutation>?) -> Cancellable? {
        guard let appSyncClient = appSyncClient else {
            return nil
        }

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

    private func notifyCompletion(_ result: GraphQLResult<Mutation.Data>?, error: Error?) {
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

        networkTask = send { (result, error) in
            if error == nil {
                self.notifyCompletion(result, error: nil)
                self.state = .finished

                return
            }

            if self.isCancelled {
                self.state = .finished
                return
            }

            self.notifyCompletion(result, error: error)
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
