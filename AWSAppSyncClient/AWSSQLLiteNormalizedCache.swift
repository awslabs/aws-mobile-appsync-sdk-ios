//
//  AWSSQLLiteNormalizedCache.swift
//  AWSAppSyncClient
//

import Foundation
import SQLite

/*
 The "timeout" method is used to control how long the SQLite library will wait for locks to clear before giving up on a database transaction. The default timeout is 0 millisecond. (In other words, the default behavior is not to wait at all.)
 
 The SQLite database allows multiple simultaneous readers or a single writer but not both. If any process is writing to the database no other process is allows to read or write. If any process is reading the database other processes are allowed to read but not write. The entire database shared a single lock.
 
 When SQLite tries to open a database and finds that it is locked, it can optionally delay for a short while and try to open the file again. This process repeats until the query times out and SQLite returns a failure. The timeout is adjustable. It is set to 0 by default so that if the database is locked, the SQL statement fails immediately. But you can use the "timeout" method to change the timeout value to a positive number.
 */

internal let sqlBusyTimeoutConstant = 100.0 // Fix a sqllite busy time out of 100ms

public protocol MutationCache {
    func saveMutation(body: Data) -> Int64
    func getMutation(id: Int64) -> Data
    func loadAllMutation() -> Dictionary<Int64, Data>
}

public enum AWSSQLLiteNormalizedCacheError: Error {
    case invalidRecordEncoding(record: String)
    case invalidRecordShape(object: Any)
    case invalidRecordValue(value: Any)
}

public final class AWSMutationCache {
    
    private let db: Connection
    private let mutationRecords = Table("mutation_records")
    private let id = Expression<Int64>("_id")
    private let recordIdentifier = Expression<CacheKey>("recordIdentifier")
    private let data = Expression<Data>("data")
    private let contentMap = Expression<String>("contentMap")
    private let recordState = Expression<String>("recordState")
    private let timestamp = Expression<Date>("timestamp")
    private let s3Bucket = Expression<String?>("s3Bucket")
    private let s3Key = Expression<String?>("s3Key")
    private let s3Region = Expression<String?>("s3Region")
    private let s3LocalUri = Expression<String?>("s3LocalUri")
    private let s3MimeType = Expression<String?>("s3MimeType")
    private let operationString = Expression<String>("operationString")
    
    public init(fileURL: URL) throws {
        db = try Connection(.uri(fileURL.absoluteString), readonly: false)
        db.busyTimeout = sqlBusyTimeoutConstant
        try createTableIfNeeded()
    }
    
    private func createTableIfNeeded() throws {
        try db.run(mutationRecords.create(ifNotExists: true) { table in
            table.column(id, primaryKey: .autoincrement)
            table.column(recordIdentifier, unique: true)
            table.column(data)
            table.column(contentMap)
            table.column(recordState)
            table.column(timestamp)
            table.column(s3Bucket)
            table.column(s3Key)
            table.column(s3Region)
            table.column(s3LocalUri)
            table.column(s3MimeType)
            table.column(operationString)
        })
        try db.run(mutationRecords.createIndex(recordIdentifier, unique: true, ifNotExists: true))
    }
    
    internal func saveMutationRecord(record: AWSAppSyncMutationRecord) throws {
        if let s3Object = record.s3ObjectInput {
            let insert = mutationRecords.insert(recordIdentifier <- record.recordIdentitifer,
                                                data <- record.data!,
                                                contentMap <- record.contentMap!.description,
                                                recordState <- record.recordState.rawValue,
                                                timestamp <- record.timestamp,
                                                s3Bucket <- s3Object.bucket,
                                                s3Key <- s3Object.key,
                                                s3Region <- s3Object.region,
                                                s3LocalUri <- s3Object.localUri,
                                                s3MimeType <- s3Object.mimeType,
                                                operationString <- record.operationString!)
            try db.run(insert)
        } else {
            let insert = mutationRecords.insert(recordIdentifier <- record.recordIdentitifer,
                                                data <- record.data!,
                                                contentMap <- record.contentMap!.description,
                                                recordState <- record.recordState.rawValue,
                                                timestamp <- record.timestamp,
                                                operationString <- record.operationString!)
            try db.run(insert)
        }
        
    }
    
    internal func updateMutationRecord(record: AWSAppSyncMutationRecord) throws {
        let sqlRecord = mutationRecords.filter(recordIdentifier == record.recordIdentitifer)
        try db.run(sqlRecord.update(recordState <- record.recordState.rawValue))
    }
    
    internal func deleteMutationRecord(record: AWSAppSyncMutationRecord) throws {
        let sqlRecord = mutationRecords.filter(recordIdentifier == record.recordIdentitifer)
        try db.run(sqlRecord.delete())
    }
    
    internal func getStoredMutationRecordsInQueue() throws -> [AWSAppSyncMutationRecord] {
        let sqlRecords = mutationRecords.filter(recordState == MutationRecordState.inQueue.rawValue).order(timestamp.asc)
        var mutationRecordQueue = [AWSAppSyncMutationRecord]()
        for record in try db.prepare(sqlRecords) {
            do {
                let mutationRecord = AWSAppSyncMutationRecord(recordIdentifier: try record.get(recordIdentifier), timestamp: try record.get(timestamp))
                mutationRecord.data = try record.get(data)
                mutationRecord.recordState = .inQueue
                mutationRecord.operationString = try record.get(operationString)
                do {
                    if let bucket = try record.get(s3Bucket),
                        let key = try record.get(s3Key),
                        let region = try record.get(s3Region),
                        let localUri = try record.get(s3LocalUri),
                        let mimeType = try record.get(s3MimeType) {
                        mutationRecord.type = .graphQLMutationWithS3Object
                        mutationRecord.s3ObjectInput = InternalS3ObjectDetails(bucket: bucket, key: key, region: region, contentType: mimeType, localUri: localUri)
                    }
                } catch {}
                mutationRecordQueue.append(mutationRecord)
            } catch {
            }
        }
        return mutationRecordQueue
    }
}

public final class AWSSQLLiteNormalizedCache: NormalizedCache {
    
    public init(fileURL: URL) throws {
        db = try Connection(.uri(fileURL.absoluteString), readonly: false)
        db.busyTimeout = sqlBusyTimeoutConstant
        try createTableIfNeeded()
    }
    
    public func merge(records: RecordSet) -> Promise<Set<CacheKey>> {
        return Promise { try mergeRecords(records: records) }
    }
    
    public func loadRecords(forKeys keys: [CacheKey]) -> Promise<[Record?]> {
        return Promise {
            let records = try selectRecords(forKeys: keys)
            let recordsOrNil: [Record?] = keys.map { key in
                if let recordIndex = records.index(where: { $0.key == key }) {
                    return records[recordIndex]
                }
                return nil
            }
            return recordsOrNil
        }
    }
    
    private let db: Connection
    private let records = Table("records")
    private let id = Expression<Int64>("_id")
    private let key = Expression<CacheKey>("key")
    private let record = Expression<String>("record")
    
    private func recordCacheKey(forFieldCacheKey fieldCacheKey: CacheKey) -> CacheKey {
        var components = fieldCacheKey.components(separatedBy: ".")
        if components.count > 1 {
            components.removeLast()
        }
        return components.joined(separator: ".")
    }
    
    private func createTableIfNeeded() throws {
        try db.run(records.create(ifNotExists: true) { table in
            table.column(id, primaryKey: .autoincrement)
            table.column(key, unique: true)
            table.column(record)
        })
        try db.run(records.createIndex(key, unique: true, ifNotExists: true))
    }
    
    private func mergeRecords(records: RecordSet) throws -> Set<CacheKey> {
        var recordSet = RecordSet(records: try selectRecords(forKeys: records.keys))
        let changedFieldKeys = recordSet.merge(records: records)
        let changedRecordKeys = changedFieldKeys.map { recordCacheKey(forFieldCacheKey: $0) }
        for recordKey in Set(changedRecordKeys) {
            if let recordFields = recordSet[recordKey]?.fields {
                let recordData = try SQLiteSerialization.serialize(fields: recordFields)
                guard let recordString = String(data: recordData, encoding: .utf8) else {
                    assertionFailure("Serialization should yield UTF-8 data")
                    continue
                }
                try db.run(self.records.insert(or: .replace, self.key <- recordKey, self.record <- recordString))
            }
        }
        return Set(changedFieldKeys)
    }
    
    private func selectRecords(forKeys keys: [CacheKey]) throws -> [Record] {
        let query = records.filter(keys.contains(key))
        return try db.prepare(query).map { try parse(row: $0) }
    }
    
    private func parse(row: Row) throws -> Record {
        let record = row[self.record]
        
        guard let recordData = record.data(using: .utf8) else {
            throw AWSSQLLiteNormalizedCacheError.invalidRecordEncoding(record: record)
        }
        
        let fields = try SQLiteSerialization.deserialize(data: recordData)
        return Record(key: row[key], fields)
    }
}

private let serializedReferenceKey = "$reference"

private final class SQLiteSerialization {
    static func serialize(fields: Record.Fields) throws -> Data {
        var objectToSerialize = JSONObject()
        for (key, value) in fields {
            objectToSerialize[key] = try serialize(fieldValue: value)
        }
        return try JSONSerialization.data(withJSONObject: objectToSerialize, options: [])
    }
    
    private static func serialize(fieldValue: Record.Value) throws -> JSONValue {
        switch fieldValue {
        case let reference as Reference:
            return [serializedReferenceKey: reference.key]
        case let array as [Record.Value]:
            return try array.map { try serialize(fieldValue: $0) }
        default:
            return fieldValue
        }
    }
    
    static func deserialize(data: Data) throws -> Record.Fields {
        let object = try JSONSerialization.jsonObject(with: data, options: [])
        guard let jsonObject = object as? JSONObject else {
            throw AWSSQLLiteNormalizedCacheError.invalidRecordShape(object: object)
        }
        var fields = Record.Fields()
        for (key, value) in jsonObject {
            fields[key] = try deserialize(fieldJSONValue: value)
        }
        return fields
    }
    
    private static func deserialize(fieldJSONValue: JSONValue) throws -> Record.Value {
        switch fieldJSONValue {
        case let dictionary as JSONObject:
            guard let reference = dictionary[serializedReferenceKey] as? String else {
                throw AWSSQLLiteNormalizedCacheError.invalidRecordValue(value: fieldJSONValue)
            }
            return Reference(key: reference)
        case let array as [JSONValue]:
            return try array.map { try deserialize(fieldJSONValue: $0) }
        default:
            return fieldJSONValue
        }
    }
}

