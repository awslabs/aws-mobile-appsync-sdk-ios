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

let sqlBusyTimeoutConstant = 100.0 // Fix a sqllite busy time out of 100ms

final class AWSSQLiteNormalizedCache: NormalizedCache {
    private static let tableName = "records"

    // This should be the same as GraphQLQuery.rootCacheKey. Unfortunately, we can't access that static member without
    // specializing the protocol. We're using `EmptyQuery` simply to access the `rootCacheKey` member defined by the
    // GraphQLQuery protocol.
    private static let queryRootKey = AWSAppSyncClient.EmptyQuery.rootCacheKey

    private let db: Connection
    private let records = Table(tableName)
    private let id = Expression<Int64>("_id")
    private let key = Expression<CacheKey>("key")
    private let record = Expression<String>("record")

    init(fileURL: URL) throws {
        db = try Connection(.uri(fileURL.absoluteString), readonly: false)
        db.busyTimeout = sqlBusyTimeoutConstant
        try createTableIfNeeded()
    }

    func loadRecords(forKeys keys: [CacheKey]) -> Promise<[Record?]> {
        return selectRecords(forKeys: keys)
            .map({ records in
                let recordsOrNil: [Record?] = keys.map { key in
                    return records.first { $0.key == key }
                }
                return recordsOrNil
            })
    }

    func merge(records: RecordSet) -> Promise<Set<CacheKey>> {
        return mergeRecords(records: records)
    }

    func clear() -> Promise<Void> {
        return Promise {
            try db.run(self.records.delete())
        }
    }

    // MARK: - Utilities
    
    private func createTableIfNeeded() throws {
        try db.run(records.create(ifNotExists: true) { table in
            table.column(id, primaryKey: .autoincrement)
            table.column(key, unique: true)
            table.column(record)
        })
        try db.run(records.createIndex(key, unique: true, ifNotExists: true))

        let queryRootRecords = records.filter(key == AWSSQLiteNormalizedCache.queryRootKey)
        let recordCount = try db.scalar(queryRootRecords.count)
        if recordCount == 0 {
            // Prepopulate the cache with an empty QUERY_ROOT, to allow optimistic updates of query results that have
            // not yet been retrieved from the service. This works around Apollo's behavior of throwing an error if
            // readObject find no records. (#92)
            try db.run(records.insert(
                key <- AWSSQLiteNormalizedCache.queryRootKey,
                record <- "{}"
            ))
        }
    }

    private func recordCacheKey(forFieldCacheKey fieldCacheKey: CacheKey) -> CacheKey {
        var components = fieldCacheKey.components(separatedBy: ".")
        if components.count > 1 {
            components.removeLast()
        }
        return components.joined(separator: ".")
    }

    private func mergeRecords(records: RecordSet) -> Promise<Set<CacheKey>> {

        return Promise {
            var recordSet = try selectRecords(forKeys: records.keys)
                .map { RecordSet(records: $0) }
                .await()

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

    }

    private func selectRecords(forKeys keys: [CacheKey]) -> Promise<[Record]> {
        return Promise {
            let query = records.filter(keys.contains(key))
            return try db.prepare(query).map { try parse(row: $0) }
        }
    }

    private func parse(row: Row) throws -> Record {
        let record = row[self.record]

        guard let recordData = record.data(using: .utf8) else {
            throw AWSAppSyncQueriesCacheError.invalidRecordEncoding(record: record)
        }

        let fields = try SQLiteSerialization.deserialize(data: recordData)
        return Record(key: row[key], fields)
    }

}
