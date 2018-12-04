//
//  AWSOfflineMutationStore.swift
//  AWSAppSyncClient
//

import Foundation

public enum MutationRecordState: String {
    case inProgress
    case inQueue
    case isDone
}

public enum MutationType: String {
    case graphQLMutation
    case graphQLMutationWithS3Object
}

class InternalS3ObjectDetails: AWSS3InputObjectProtocol, AWSS3ObjectProtocol {
    
    let bucket: String
    let key: String
    let region: String
    let mimeType: String
    let localUri: String
    
    init(bucket: String, key: String, region: String, contentType: String, localUri: String) {
        self.bucket = bucket
        self.key = key
        self.region = region
        self.mimeType = contentType
        self.localUri = localUri
    }
    
    func getRegion() -> String {
        return self.region
    }
    
    func getLocalSourceFileURL() -> URL? {
        return URL(string: self.localUri)
    }
    
    func getMimeType() -> String {
        return self.mimeType
    }
    
    func getBucketName() -> String {
        return self.bucket
    }
    
    func getKeyName() -> String {
        return self.key
    }
}

public class AWSAppSyncMutationRecord {
    var jsonRecord: JSONObject?
    var data: Data?
    var contentMap: GraphQLMap?
    public var recordIdentitifer: String
    public var recordState: MutationRecordState = .inQueue
    var timestamp: Date
    var selections: [GraphQLSelection]?
    var operationTypeClass: String?
    weak var inmemoryExecutor: InMemoryMutationDelegate?
    var type: MutationType
    var s3ObjectInput: InternalS3ObjectDetails?
    var operationString: String?
    
    init(recordIdentifier: String = UUID().uuidString, timestamp: Date = Date(), type: MutationType = .graphQLMutation) {
        self.recordIdentitifer = recordIdentifier
        self.timestamp = timestamp
        self.type = type
    }
}

public class AWSAppSyncOfflineMutationCache {
    private var persistentCache: AWSMutationCache?
    var recordQueue = [String: AWSAppSyncMutationRecord]()
    var processQueue = [AWSAppSyncMutationRecord]()
    
    init(fileURL: URL? = nil) throws {
        if let fileURL = fileURL {
            self.persistentCache = try AWSMutationCache(fileURL: fileURL)
            try self.loadPersistedData()
        }
    }
    
    internal func loadPersistedData() throws {
        _ = try self.persistentCache?.getStoredMutationRecordsInQueue().map({ record in
            recordQueue[record.recordIdentitifer] = record
            processQueue.append(record)
        })
    }
    
    internal func add(mutationRecord: AWSAppSyncMutationRecord) {
        do {
            try _add(mutationRecord: mutationRecord)
        } catch {
        }
    }
    
    fileprivate func _add(mutationRecord: AWSAppSyncMutationRecord) throws {
        recordQueue[mutationRecord.recordIdentitifer] = mutationRecord
        do {
            try persistentCache?.saveMutationRecord(record: mutationRecord)
        } catch {
        }
    }

    internal func removeRecordFromQueue(record: AWSAppSyncMutationRecord) throws -> Bool {
        return try _removeRecordFromQueue(record: record)
    }
    
    fileprivate func _removeRecordFromQueue(record: AWSAppSyncMutationRecord) throws -> Bool {
        do {
            try persistentCache?.deleteMutationRecord(record: record)
        } catch {}

        if let index = processQueue.index(where: {$0.recordIdentitifer == record.recordIdentitifer}) {
            processQueue.remove(at: index)
        }
        recordQueue.removeValue(forKey: record.recordIdentitifer)
        return true
    }
    
    internal func listAllMuationRecords() -> [String: AWSAppSyncMutationRecord] {
        return recordQueue
    }
}

class MutationExecutor: NetworkConnectionNotification {
    
    var mutationQueue = [AWSAppSyncMutationRecord]()
    let dispatchGroup = DispatchGroup()
    var isExecuting = false
    var shouldExecute = true
    
    let isExecutingDispatchGroup = DispatchGroup()
    var currentMutation: AWSAppSyncMutationRecord?
    var networkClient: AWSNetworkTransport
    weak var appSyncClient: AWSAppSyncClient?
    var handlerQueue = DispatchQueue.main
    var store: ApolloStore?
    var apolloClient: ApolloClient?
    var autoSubmitOfflineMutations: Bool = true
    private var persistentCache: AWSMutationCache?
    var snapshotProcessController: SnapshotProcessController
    
    init(networkClient: AWSNetworkTransport,
         appSyncClient: AWSAppSyncClient,
         snapshotProcessController: SnapshotProcessController,
         fileURL: URL? = nil) {
        self.networkClient = networkClient
        self.appSyncClient = appSyncClient
        self.snapshotProcessController = snapshotProcessController
        if let fileURL = fileURL {
            do {
                self.persistentCache = try AWSMutationCache(fileURL: fileURL)
                try self.loadPersistedData()
            } catch let error {
                print("Error persisting cache: \(error.localizedDescription)")
            }
        }
    }
    
    func onNetworkAvailabilityStatusChanged(isEndpointReachable: Bool) {
        if isEndpointReachable {
            if !listAllMuationRecords().isEmpty && autoSubmitOfflineMutations {
                resumeMutationExecutions()
            }
        } else {
            pauseMutationExecutions()
        }
    }
    
    internal func loadPersistedData() throws {
        do {
            _ = try self.persistentCache?.getStoredMutationRecordsInQueue().map({ record in
                mutationQueue.append(record)
            })
        } catch {}
    }
    
    func queueMutation(mutation: AWSAppSyncMutationRecord) {
        mutationQueue.append(mutation)
        do {
            try persistentCache?.saveMutationRecord(record: mutation)
        } catch {
             // silent fail
        }

        // if the record is just queued and we are online, immediately submit the record
        if snapshotProcessController.shouldExecuteOperation(operation: .mutation)
            && self.listAllMuationRecords().count == 1 {
            self.mutationQueue.removeFirst()
            mutation.inmemoryExecutor?.performMutation(dispatchGroup: dispatchGroup)
            do {
                _ = try self.removeRecordFromQueue(record: mutation)
            } catch {}
        }
        
    }
    
    internal func removeRecordFromQueue(record: AWSAppSyncMutationRecord) throws -> Bool {
        return try _removeRecordFromQueue(record: record)
    }
    
    fileprivate func _removeRecordFromQueue(record: AWSAppSyncMutationRecord) throws -> Bool {
        try persistentCache?.deleteMutationRecord(record: record)
        return true
    }
    
    internal func listAllMuationRecords() -> [AWSAppSyncMutationRecord] {
        return mutationQueue
    }
    
    fileprivate func executeMutation(mutation: AWSAppSyncMutationRecord) {
        if let inMemoryMutationExecutor = mutation.inmemoryExecutor {
            dispatchGroup.enter()
            inMemoryMutationExecutor.performMutation(dispatchGroup: dispatchGroup)
            self.mutationQueue.removeFirst()
            do {
                _ = try self.removeRecordFromQueue(record: mutation)
            } catch {
            }
        } else {
            performPersistentOfflineMutation(mutation: mutation)
        }
    }
    
    fileprivate func performPersistentOfflineMutation(mutation: AWSAppSyncMutationRecord) {
        func notifyResultHandler(record: AWSAppSyncMutationRecord, result: JSONObject?, success: Bool, error: Error?) {
            handlerQueue.async {
                // call master delegate
                self.appSyncClient?.offlineMutationDelegate?.mutationCallback(recordIdentifier: record.recordIdentitifer, operationString: record.operationString!, snapshot: result, error: error)
            }
        }
        
        func deleteMutationRecord() {
            // remove from current queue
            let record = self.mutationQueue.removeFirst()
            // remove from persistent store
            do {
                _ = try self.removeRecordFromQueue(record: record)
            } catch {
            }
        }
        
        func sendDataRequest(mutation: AWSAppSyncMutationRecord) {
            networkClient.send(data: mutation.data!) { (result, error) in
                deleteMutationRecord()
                guard let result = result else {
                    notifyResultHandler(record: mutation, result: nil, success: false, error: error)
                    self.dispatchGroup.leave()
                    return
                }
                
                notifyResultHandler(record: mutation, result: result, success: true, error: nil)
                self.dispatchGroup.leave()
            }
        }
        
        dispatchGroup.enter()
        if let s3Object = mutation.s3ObjectInput {
            
            self.appSyncClient?.s3ObjectManager!.upload(s3Object: s3Object) { (isSuccessful, error) in
                if isSuccessful {
                    sendDataRequest(mutation: mutation)
                } else {
                    // give customer error callback with S3 as the error
                    deleteMutationRecord()
                    notifyResultHandler(record: mutation, result: nil, success: false, error: error)
                }
            }
        } else {
            sendDataRequest(mutation: mutation)
        }
        dispatchGroup.wait()
    }
    
    func pauseMutationExecutions() {
        shouldExecute = false
    }
    
    func resumeMutationExecutions() {
        shouldExecute = true
        executeAllQueuedMutations()
    }
    
    // executes all queued mutations synchronously
    func executeAllQueuedMutations() {
        if !isExecuting {
            isExecuting = true
            while !mutationQueue.isEmpty {
                if shouldExecute {
                    executeMutation(mutation: mutationQueue.first!)
                    currentMutation = mutationQueue.first
                } else {
                    // halt execution
                    break
                }
            }
            // update status to not executing
            isExecuting = false
        }
    }
}
