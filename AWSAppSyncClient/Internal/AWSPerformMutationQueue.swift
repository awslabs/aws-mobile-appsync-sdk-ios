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

final class AWSPerformMutationQueue {

    private weak var appSyncClient: AWSAppSyncClient?
    private weak var networkClient: AWSNetworkTransport?
    private let persistentCache: AWSMutationCache?

    private let operationQueue: OperationQueue
    private let handlerQueue: DispatchQueue

    init(
        appSyncClient: AWSAppSyncClient,
        networkClient: AWSNetworkTransport,
        handlerQueue: DispatchQueue = .main,
        reachabiltyChangeNotifier: NetworkReachabilityNotifier?,
        cacheFileURL: URL? = nil) {

        self.appSyncClient = appSyncClient
        self.networkClient = networkClient
        self.handlerQueue = handlerQueue

        self.operationQueue = OperationQueue()
        self.operationQueue.name = "com.amazonaws.service.appsync.MutationQueue"
        self.operationQueue.maxConcurrentOperationCount = 1

        if let cacheFileURL = cacheFileURL {
            do {
                persistentCache = try AWSMutationCache(fileURL: cacheFileURL)

                operationQueue.addOperation { [weak self] in
                    do {
                        try self?.loadMutations()
                    } catch {
                        print("Error loading mutations: \(error)")
                    }
                }
            } catch {
                persistentCache = nil
                AppSyncLog.error("persistentCache initialization error: \(error)")
            }
        } else {
            persistentCache = nil
        }

        self.suspendOrResumeQueue(reachabiltyChangeNotifier: reachabiltyChangeNotifier)
        reachabiltyChangeNotifier?.add(watcher: self)
    }

    // MARK: - Queue operations

    func add<Mutation: GraphQLMutation>(
        _ mutation: Mutation,
        mutationConflictHandler: MutationConflictHandler<Mutation>?,
        mutationResultHandler: OperationResultHandler<Mutation>?) -> Cancellable {

        let offlineMutation: AWSAppSyncMutationRecord?
        do {
            offlineMutation = try save(mutation)
        } catch {
            offlineMutation = nil
            AppSyncLog.error("error saving offline mutation: \(error)")
        }

        let operation = AWSPerformMutationOperation(
            appSyncClient: appSyncClient,
            handlerQueue: handlerQueue,
            mutation: mutation,
            mutationConflictHandler: mutationConflictHandler,
            mutationResultHandler: mutationResultHandler)

        operation.identifier = offlineMutation?.recordIdentitifer

        operation.operationCompletionBlock = { [weak self] operation, error in
            guard let identifier = operation.identifier else { return }

            do {
                try self?.deleteOfflineMutation(withIdentifier: identifier)
            } catch {
                AppSyncLog.error("error deleting offline mutation: \(error)")
            }
        }

        operationQueue.addOperation(operation)

        return operation
    }

    func suspend() {
        operationQueue.isSuspended = true
    }

    func resume() {
        operationQueue.isSuspended = false
    }

    private func suspendOrResumeQueue(reachabiltyChangeNotifier: NetworkReachabilityNotifier?) {
        if reachabiltyChangeNotifier?.isNetworkReachable ?? false {
            resume()
        } else {
            suspend()
        }
    }

    // MARK: Offline Mutations

    private func loadMutations() throws {
        do {
            guard let mutations = try persistentCache?.getStoredMutationRecordsInQueue() else {
                return
            }

            for mutation in mutations {
                let operation = AWSPerformOfflineMutationOperation(
                    appSyncClient: appSyncClient,
                    networkClient: networkClient,
                    handlerQueue: handlerQueue,
                    mutation: mutation)

                operation.operationCompletionBlock = { [weak self] operation, error in
                    let identifier = operation.mutation.recordIdentitifer

                    do {
                        try self?.deleteOfflineMutation(withIdentifier: identifier)
                    } catch {
                        AppSyncLog.error("error deleting offline mutation: \(error)")
                    }
                }

                operationQueue.addOperation(operation)
            }
        } catch {
            AppSyncLog.error("error retrieving offline mutation from storage: \(error)")
        }
    }

    private func save<Mutation: GraphQLMutation>(_ mutation: Mutation) throws -> AWSAppSyncMutationRecord? {
        guard let persistentCache = persistentCache else {
            return nil
        }

        let requestBody = AWSRequestBuilder.requestBody(from: mutation)
        let data = try JSONSerializationFormat.serialize(value: requestBody)

        let offlineMutation = AWSAppSyncMutationRecord()

        if let s3Object = AWSRequestBuilder.s3Object(from: mutation.variables) {
            offlineMutation.type = .graphQLMutationWithS3Object
            offlineMutation.s3ObjectInput = s3Object
        }

        offlineMutation.data = data
        offlineMutation.contentMap = mutation.variables
        offlineMutation.jsonRecord = mutation.variables?.jsonObject
        offlineMutation.recordState = .inQueue
        offlineMutation.operationString = Mutation.operationString

        try persistentCache.saveMutationRecord(record: offlineMutation)

        return offlineMutation
    }

    private func deleteOfflineMutation(withIdentifier identifier: String) throws {
        try persistentCache?.deleteMutationRecord(withIdentifier: identifier)
    }

}

// MARK: - NetworkConnectionNotification

extension AWSPerformMutationQueue: NetworkReachabilityWatcher {

    func onNetworkReachabilityChanged(isEndpointReachable: Bool) {
        if isEndpointReachable {
            resume()
        } else {
            suspend()
        }
    }
}
