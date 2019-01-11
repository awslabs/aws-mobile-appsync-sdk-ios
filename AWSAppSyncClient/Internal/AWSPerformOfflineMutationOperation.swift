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
