//
//  AWSAppSyncSubscriptionMetadataCache.swift
//  AWSAppSync
//

import Foundation
import SQLite

internal final class AWSSubscriptionMetaDataCache {
    
    private let db: Connection
    private let subscriptionMetadataRecords = Table("subscription_metadata")
    private let operationHash = Expression<String>("operationHash")
    private let lastSyncDate = Expression<Date?>("lastSyncDate")
    
    public init(fileURL: URL) throws {
        db = try Connection(.uri(fileURL.absoluteString), readonly: false)
        db.busyTimeout = sqlBusyTimeoutConstant
        try createTableIfNeeded()
    }
    
    private func createTableIfNeeded() throws {
        try db.run(subscriptionMetadataRecords.create(ifNotExists: true) { table in
            table.column(operationHash, primaryKey: true)
            table.column(lastSyncDate)
        })
    }
    
    internal func updateLasySyncTime(for operationHash: String, with lastSyncTime: Date) throws {
        let sqlRecord = subscriptionMetadataRecords.filter(self.operationHash == operationHash)
        let recordCount = try db.scalar(sqlRecord.count)
        
        guard recordCount == 0 else {
            try db.run(sqlRecord.update(self.operationHash <- operationHash, self.lastSyncDate <- lastSyncTime))
            return
        }
        
        let insert = subscriptionMetadataRecords.insert(self.lastSyncDate <- lastSyncTime,
                                                        self.operationHash <- operationHash)
        try db.run(insert)
    }
    
    internal func getLastSyncTime(operationHash: String) throws -> Date? {
        let sqlRecord = subscriptionMetadataRecords.filter(self.operationHash == operationHash)
        let recordCount = try db.scalar(sqlRecord.count)
        
        guard recordCount != 0 else {
            return nil
        }
        
        var syncDate: Date?
        for record in try db.prepare(sqlRecord) {
            syncDate = try record.get(lastSyncDate)
        }
        return syncDate
    }
}
