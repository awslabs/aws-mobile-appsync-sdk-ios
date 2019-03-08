//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

final class AWSPerformMutationQueue {

    private weak var appSyncClient: AWSAppSyncClient?
    private weak var networkClient: AWSNetworkTransport?
    private let persistentCache: AWSMutationCache?

    /// The OperationQueue onto which we enqueue mutations to perform
    private let operationQueue: OperationQueue

    /// Returns the count of mutations yet to be processed, so apps can give UI advice if there are unprocessed
    /// mutations.
    var operationQueueCount: Int {
        return operationQueue.operationCount
    }

    init(
        appSyncClient: AWSAppSyncClient,
        networkClient: AWSNetworkTransport,
        reachabiltyChangeNotifier: NetworkReachabilityNotifier?,
        cacheFileURL: URL? = nil) {

        AppSyncLog.verbose("Initializing AWSPerformMutationQueue")

        self.appSyncClient = appSyncClient
        self.networkClient = networkClient

        operationQueue = OperationQueue()
        operationQueue.name = "com.amazonaws.service.appsync.AWSPerformMutationQueue.operations"
        operationQueue.maxConcurrentOperationCount = 1

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
        mutationResultHandler: OperationResultHandler<Mutation>?,
        handlerQueue: DispatchQueue) -> Cancellable {

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

        operation.identifier = offlineMutation?.recordIdentifier

        operation.operationCompletionBlock = { [weak self] operation, error in
            guard let identifier = operation.identifier else { return }
            self?.deleteOfflineMutation(withIdentifier: identifier)
        }

        operationQueue.addOperation(operation)

        return operation
    }

    func suspend() {
        AppSyncLog.verbose("Suspending OperationQueue")
        operationQueue.isSuspended = true
    }

    func resume() {
        AppSyncLog.verbose("Resuming OperationQueue")
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
            AppSyncLog.info("Loading offline mutations")

            guard let mutations = try persistentCache?.getStoredMutationRecordsInQueue().await() else {
                return
            }

            for mutation in mutations {
                let operation = AWSPerformOfflineMutationOperation(
                    appSyncClient: appSyncClient,
                    networkClient: networkClient,
                    handlerQueue: .main,
                    mutation: mutation)

                operation.operationCompletionBlock = { [weak self] operation, error in
                    let identifier = operation.mutation.recordIdentifier
                    self?.deleteOfflineMutation(withIdentifier: identifier)
                }

                operationQueue.addOperation(operation)
                AppSyncLog.verbose("\(mutation.recordIdentifier) loaded")
            }
        } catch {
            AppSyncLog.error("Error retrieving offline mutation from storage: \(error)")
        }

        if AppSyncLogHelper.shouldLog(flag: .verbose) {
            operationQueue.addOperation {
                AppSyncLog.verbose("Finished processing offline mutations")
            }
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

        persistentCache
            .saveMutationRecord(record: offlineMutation)
            .catch { error in AppSyncLog.error("\(#function) failure: \(error)") }

        return offlineMutation
    }

    private func deleteOfflineMutation(withIdentifier identifier: String) {
        persistentCache?
            .deleteMutationRecord(withIdentifier: identifier)
            .catch { error in AppSyncLog.error("\(#function) failure: \(error)") }
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
