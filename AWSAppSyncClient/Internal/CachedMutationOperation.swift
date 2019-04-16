//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

/// This class(operation) is responsible for executing mutations when they are submitted from the application during the previous session, but were not be able to sent to service due to network not being available or app being quit. The callbacks for these mutations are given to the global callback delegate. For mutations submitted in current session, see: `SessionMutationOperation`.
final class CachedMutationOperation: AsynchronousOperation, Cancellable {
    private weak var appSyncClient: AWSAppSyncClient?
    private weak var networkClient: AWSNetworkTransport?
    private let handlerQueue: DispatchQueue
    let mutation: AWSAppSyncMutationRecord
    var currentAttemptNumber = 1
    var mutationNextStep: MutationState = .unknown
    var mutationRetryNotifier: AWSMutationRetryNotifier?

    var operationCompletionBlock: ((CachedMutationOperation, Error?) -> Void)?

    init(
        appSyncClient: AWSAppSyncClient?,
        networkClient: AWSNetworkTransport?,
        handlerQueue: DispatchQueue,
        mutation: AWSAppSyncMutationRecord) {
        
        self.appSyncClient = appSyncClient
        self.networkClient = networkClient
        self.handlerQueue = handlerQueue
        self.mutation = mutation
        super.init()
        resolveInitialMutationState()
    }

    deinit {
        AppSyncLog.verbose("\(mutation.recordIdentifier): deinit")
    }
    
    private func resolveInitialMutationState() {
        if mutation.s3ObjectInput != nil {
            mutationNextStep = .s3Upload
        } else {
            mutationNextStep = .graphqlOperation
        }
    }

    private func send(_ mutation: AWSAppSyncMutationRecord,
                      completion: @escaping ((JSONObject?, Error?) -> Void)) {
        guard
            let data = mutation.data,
            let networkClient = networkClient
            else {
                completion(nil, nil)
                return
        }

        networkClient.send(data: data) { result, error in
            completion(result, error)
        }
    }

    private func send(completion: @escaping ((JSONObject?, Error?) -> Void)) {
        guard let appSyncClient = appSyncClient else {
            return
        }
        switch mutationNextStep {
        case .s3Upload:
            appSyncClient.s3ObjectManager?.upload(s3Object: mutation.s3ObjectInput!) { [weak self, mutation] success, error in
                if success {
                    // If the complex object upload goes through, we set the next step to be graphql operation
                    // and then send the graphql mutation request over wire.
                    self?.mutationNextStep = .graphqlOperation
                    self?.send(mutation, completion: completion)
                } else {
                    if let error = error, AWSMutationRetryAdviceHelper.isRetriableNetworkError(error: error) {
                        // If the error retriable, do not mark the operation as completed; schedule a retry.
                        self?.scheduleRetry()
                        return
                    }
                    // if complex object upload error is not retriable, we callback the developer
                    completion(nil, error)
                }
            }
        case .graphqlOperation:
            // If the mutation next step is graphql operation, then we invoke the network send.
            send(mutation, completion: completion)
        default:
            break
        }
    }
    
     func scheduleRetry() {
        AppSyncLog.debug("Scheduling mutation retry for persistent mutation.")
        mutationRetryNotifier = AWSMutationRetryNotifier(retryAttemptNumber: currentAttemptNumber) {
            self.performMutation()
            self.mutationRetryNotifier = nil
        }
        currentAttemptNumber += 1
    }

    private func notifyCompletion(_ result: JSONObject?, error: Error?) {
        operationCompletionBlock?(self, error)

        handlerQueue.async { [weak self] in
            guard
                let self = self,
                let appSyncClient = self.appSyncClient,
                let offlineMutationDelegate = appSyncClient.offlineMutationDelegate
                else {
                    return
            }

            // call master delegate
            offlineMutationDelegate.mutationCallback(
                recordIdentifier: self.mutation.recordIdentifier,
                operationString: self.mutation.operationString!,
                snapshot: result,
                error: error)
        }
    }
    
    private func performMutation() {
        send { result, error in
            if error == nil {
                self.notifyCompletion(result, error: nil)
                self.state = .finished
                return
            }
            
            if self.isCancelled {
                self.state = .finished
                return
            }
            
            if let error = error, AWSMutationRetryAdviceHelper.isRetriableNetworkError(error: error) {
                // If the error retriable, do not mark the operation as completed; schedule a retry.
                AppSyncLog.debug("Persistent mutation could not be done due to network issue. Scheduling retry.")
                self.scheduleRetry()
                return
            }
            
            self.notifyCompletion(result, error: error)
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

    // MARK: CustomStringConvertible

    override var description: String {
        var desc: String = "<\(self):\(mutation.self)"
        desc.append("\tmutation: \(mutation)")
        desc.append("\tstate: \(state)")
        desc.append(">")

        return desc
    }
}
