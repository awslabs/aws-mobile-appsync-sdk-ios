//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

final class AWSPerformOfflineMutationOperation: AsynchronousOperation, Cancellable {
    private weak var appSyncClient: AWSAppSyncClient?
    private weak var networkClient: AWSNetworkTransport?
    private let handlerQueue: DispatchQueue
    let mutation: AWSAppSyncMutationRecord

    var operationCompletionBlock: ((AWSPerformOfflineMutationOperation, Error?) -> Void)?

    init(
        appSyncClient: AWSAppSyncClient?,
        networkClient: AWSNetworkTransport?,
        handlerQueue: DispatchQueue,
        mutation: AWSAppSyncMutationRecord) {
        self.appSyncClient = appSyncClient
        self.networkClient = networkClient
        self.handlerQueue = handlerQueue
        self.mutation = mutation
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

        if let s3Object = mutation.s3ObjectInput {
            appSyncClient.s3ObjectManager?.upload(s3Object: s3Object) { [weak self, mutation] success, error in
                if success {
                    self?.send(mutation, completion: completion)
                } else {
                    completion(nil, error)
                }
            }
        } else {
            send(mutation, completion: completion)
        }
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
                recordIdentifier: self.mutation.recordIdentitifer,
                operationString: self.mutation.operationString!,
                snapshot: result,
                error: error)
        }
    }

    // MARK: Operation

    override func start() {
        if isCancelled {
            state = .finished
            return
        }

        state = .executing

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

            self.notifyCompletion(result, error: error)
            self.state = .finished
        }
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
