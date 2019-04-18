//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

/// This class(operation) is responsible for executing mutations when they are submitted from the application during the current session. If the app is killed and restarted, these operations are reloaded from cache, but their callback context will be lost, and instead the global delegate callback will be invoked with the mutation result. See: `CachedMutationOperation`.
final class SessionMutationOperation<Mutation: GraphQLMutation>: AsynchronousOperation, Cancellable {
    private weak var appSyncClient: AWSAppSyncClient?
    private let handlerQueue: DispatchQueue
    private let mutation: Mutation
    private let mutationConflictHandler: MutationConflictHandler<Mutation>?
    private let mutationResultHandler: OperationResultHandler<Mutation>?
    var currentAttemptNumber = 1
    var mutationNextStep: MutationState = .unknown
    var mutationRetryNotifier: AWSMutationRetryNotifier?

    private var networkTask: Cancellable?

    var identifier: String?
    var operationCompletionBlock: ((SessionMutationOperation, Error?) -> Void)?

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
        super.init()
        resolveInitialMutationState()
    }

    deinit {
        AppSyncLog.verbose("\(identifier ?? "(no identifier)"): deinit")
    }
    
    private func resolveInitialMutationState() {
        if AWSRequestBuilder.s3Object(from: mutation.variables) != nil {
            mutationNextStep = .s3Upload
        } else {
            mutationNextStep = .graphqlOperation
        }
    }

    private func send(_ resultHandler: OperationResultHandler<Mutation>?) -> Cancellable? {
        guard let appSyncClient = appSyncClient else {
            return nil
        }

        AppSyncLog.verbose("\(identifier ?? "(No identifier)"): sending")
        
        switch mutationNextStep {
        case .s3Upload:
            appSyncClient.performS3ObjectUploadForMutation(operation: mutation,
                                                           s3Object: AWSRequestBuilder.s3Object(from: mutation.variables)!) { (error) in
            if let error = error, AWSMutationRetryAdviceHelper.isRetriableNetworkError(error: error) {
                // If the error retriable, do not mark the operation as completed; schedule a retry.
                self.scheduleRetry()
            } else if error != nil {
                // if the complex object error is not retriable, we callback the developer
                resultHandler?(nil, error)
            } else {
                // If the complex object upload goes through, we set the next step to be graphql operation
                // and then send the graphql mutation request over wire.
                self.mutationNextStep = .graphqlOperation
                self.networkTask = self.performGraphQLMutation(resultHandler)
            }
        }
        case .graphqlOperation:
            // If the mutation next step is graphql operation, then we invoke the network send.
            return performGraphQLMutation(resultHandler)
        default:
            break
        }
        return nil
    }
    
    private func performGraphQLMutation(_ resultHandler: OperationResultHandler<Mutation>?) -> Cancellable? {
        return appSyncClient?.send(
            operation: mutation,
            conflictResolutionBlock: mutationConflictHandler,
            handlerQueue: handlerQueue,
            resultHandler: resultHandler)
    }

    private func notifyCompletion(_ result: GraphQLResult<Mutation.Data>?, error: Error?, notifyDeveloperCallback: Bool) {
        // notify operation completion block which deletes the mutation from persistent store.
        operationCompletionBlock?(self, error)
        
        // if notifyDeveloperCallback set true, invoke mutationResultHandler
        if let mutationResultHandler = mutationResultHandler, notifyDeveloperCallback {
            handlerQueue.async {
                mutationResultHandler(result, error)
            }
        }
    }
    
    private func scheduleRetry() {
        AppSyncLog.debug("Scheduling mutation retry for in-memory mutation.")
        mutationRetryNotifier = AWSMutationRetryNotifier(retryAttemptNumber: currentAttemptNumber) {
            self.performMutation()
            self.mutationRetryNotifier = nil
        }
        currentAttemptNumber += 1
    }
    
    private func performMutation() {
        networkTask = send { (result, error) in
            if error == nil {
                self.notifyCompletion(result, error: nil, notifyDeveloperCallback: true)
                self.state = .finished
                return
            }
            
            if self.isCancelled {
                self.state = .finished
                return
            }
            
            if let error = error, AWSMutationRetryAdviceHelper.isRetriableNetworkError(error: error) {
                // If the error retriable, do not mark the operation as completed; schedule a retry.
                AppSyncLog.debug("InMemory mutation could not be done due to network issue. Scheduling retry.")
                self.scheduleRetry()
                return
            }
            
            self.notifyCompletion(result, error: error, notifyDeveloperCallback: true)
            self.state = .finished
        }
    }

    // MARK: Operation

    override func start() {
        if isCancelled {
            state = .finished
            return
        }

        state = .executing

        performMutation()
    }

    // MARK: Cancellable

    override func cancel() {
        super.cancel()
        networkTask?.cancel()
        self.notifyCompletion(nil, error: nil, notifyDeveloperCallback: false)
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
