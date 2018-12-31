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

    private let appSyncClient: AWSAppSyncClient
    private let networkClient: AWSNetworkTransport
    private let handlerQueue: DispatchQueue
    let mutation: AWSAppSyncMutationRecord

    var operationCompletionBlock: ((AWSPerformOfflineMutationOperation, Error?) -> Void)?

    init(
        appSyncClient: AWSAppSyncClient,
        networkClient: AWSNetworkTransport,
        handlerQueue: DispatchQueue,
        mutation: AWSAppSyncMutationRecord) {
        self.appSyncClient = appSyncClient
        self.networkClient = networkClient
        self.handlerQueue = handlerQueue
        self.mutation = mutation
    }

    private var networkTask: Cancellable?

    private func _send(
        _ mutation: AWSAppSyncMutationRecord,
        completion: @escaping ((JSONObject?, Error?) -> Void)) {
        guard let data = mutation.data else {
            completion(nil, nil)
            return
        }

        networkClient.send(data: data) { result, error in
            completion(result, error)
        }
    }

    private func send(
        completion: @escaping ((JSONObject?, Error?) -> Void)) -> Cancellable? {

        if let s3Object = mutation.s3ObjectInput {
            appSyncClient.s3ObjectManager?.upload(
                s3Object: s3Object,
                completion: { [weak self, mutation] success, error in
                    if success {
                        self?._send(mutation, completion: completion)
                    } else {
                        completion(nil, error)
                    }
                })

            return nil
        } else {
            _send(mutation, completion: completion)

            return nil
        }
    }

    private func notifyCompletion(
        _ result: JSONObject?, error: Error?) {
        operationCompletionBlock?(self, error)

        handlerQueue.async { [appSyncClient, mutation] in
            // call master delegate
            appSyncClient.offlineMutationDelegate?.mutationCallback(
                recordIdentifier: mutation.recordIdentitifer,
                operationString: mutation.operationString!,
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

        networkTask = send { result, error in
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

    // MARK: CustomStringConvertible

    override var description: String {
        var desc: String = "<\(self):\(mutation.self)"
        desc.append("\tmutation: \(mutation)")
        desc.append("\tstate: \(state)")
        desc.append(">")

        return desc
    }
}
