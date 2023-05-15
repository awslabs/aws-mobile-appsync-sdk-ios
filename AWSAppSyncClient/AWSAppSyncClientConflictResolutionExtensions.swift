//
//  AWSAppSyncHTTPNetworkTransportExtensions.swift
//  AWSAppSync
//

import Foundation
import AWSCore

enum MutationQueuePosition {
    case start
    case end
}

class ConflictMutation<Mutation: GraphQLMutation> {
    let mutation: Mutation
    let position: MutationQueuePosition

    init(mutation: Mutation, position: MutationQueuePosition) {
        self.mutation = mutation
        self.position = position
    }
}

extension AWSAppSyncClient {
    
    func send<Operation: GraphQLMutation>(
        operation: Operation,
        conflictResolutionBlock: MutationConflictHandler<Operation>?,
        handlerQueue: DispatchQueue,
        resultHandler: OperationResultHandler<Operation>?) -> Cancellable {

        AppSyncLog.verbose("Sending operation \(operation)")

        func notifyResultHandler(result: GraphQLResult<Operation.Data>?, error: Error?) {
            guard let resultHandler = resultHandler else { return }

            handlerQueue.async {
                resultHandler(result, error)
            }
        }

        return httpTransport!.send(operation: operation) { (response, error) in
            guard let response = response else {
                notifyResultHandler(result: nil, error: error)
                return
            }

            firstly {
                try response.parseResult(cacheKeyForObject: self.store!.cacheKeyForObject)
            }.andThen { result, records in
                if let resultError = result.errors,
                    let conflictResolutionBlock = conflictResolutionBlock,
                    let error = resultError.first,
                    error.localizedDescription.hasPrefix("The conditional request failed") {
                    let error = resultError[0]

                    if error.localizedDescription.hasPrefix("The conditional request failed") {
                        let serverState = error["data"] as? JSONObject
                        let taskCompletionSource = AWSTaskCompletionSource<Operation>()
                        conflictResolutionBlock(serverState, taskCompletionSource, nil)
                        taskCompletionSource.task.continueWith(block: { (task) -> Any? in
                            if let mutation = task.result {
                                _ = self.send(operation: mutation,
                                              conflictResolutionBlock: nil,
                                              handlerQueue: handlerQueue,
                                              resultHandler: resultHandler)
                            }
                            return nil
                        }).waitUntilFinished()
                    }
                } else {
                    notifyResultHandler(result: result, error: nil)

                    if let records = records {
                        self.store?.publish(records: records).catch { error in
                            preconditionFailure(String(describing: error))
                        }
                    }
                }
            }.catch { error in
                notifyResultHandler(result: nil, error: error)
            }
        }
    }
}
