//
// Copyright 2010-2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
import SQLite

public final class AWSMutationCache {

    private let db: Connection
    private let mutationRecords = Table("mutation_records")
    private let id = Expression<Int64>("_id")
    private let recordIdentifier = Expression<CacheKey>("recordIdentifier")
    private let data = Expression<Data>("data")
    private let recordState = Expression<String>("recordState")
    private let timestamp = Expression<Date>("timestamp")
    private let s3Bucket = Expression<String?>("s3Bucket")
    private let s3Key = Expression<String?>("s3Key")
    private let s3Region = Expression<String?>("s3Region")
    private let s3LocalUri = Expression<String?>("s3LocalUri")
    private let s3MimeType = Expression<String?>("s3MimeType")
    private let operationString = Expression<String>("operationString")
    private let priority = Expression<Int?>("priority")

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
            table.column(recordState)
            table.column(timestamp)
            table.column(s3Bucket)
            table.column(s3Key)
            table.column(s3Region)
            table.column(s3LocalUri)
            table.column(s3MimeType)
            table.column(operationString)
        })

        do {
            try db.run(mutationRecords.addColumn(priority))
        } catch {}

        try db.run(mutationRecords.createIndex(recordIdentifier, unique: true, ifNotExists: true))
    }

    internal func saveMutationRecord(record: AWSAppSyncMutationRecord) -> Promise<Void> {
        return Promise {
          if let s3Object = record.s3ObjectInput {
              let insert = mutationRecords.insert(
                  recordIdentifier <- record.recordIdentitifer,
                  data <- record.data!,
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
              let insert = mutationRecords.insert(
                  recordIdentifier <- record.recordIdentitifer,
                  data <- record.data!,
                  recordState <- record.recordState.rawValue,
                  timestamp <- record.timestamp,
                  operationString <- record.operationString!)
              try db.run(insert)
          }
        }
    }

    internal func updateMutationRecord(record: AWSAppSyncMutationRecord) -> Promise<Void> {
        return Promise {
            let sqlRecord = mutationRecords.filter(recordIdentifier == record.recordIdentitifer)
            try db.run(sqlRecord.update(recordState <- record.recordState.rawValue))
        }
    }

    internal func deleteMutationRecord(record: AWSAppSyncMutationRecord) -> Promise<Void> {
        return Promise {
            let sqlRecord = mutationRecords.filter(recordIdentifier == record.recordIdentitifer)
            try db.run(sqlRecord.delete())
        }
    }

    internal func deleteMutationRecord(withIdentifier identifier: String) -> Promise<Void> {
        return Promise {
            let sqlRecord = mutationRecords.filter(recordIdentifier == identifier)
            try db.run(sqlRecord.delete())
        }
    }

    internal func getStoredMutationRecordsInQueue() -> Promise<[AWSAppSyncMutationRecord]> {
        return Promise {
            let sqlRecords = mutationRecords.filter(recordState == MutationRecordState.inQueue.rawValue).order(timestamp.asc)
            var mutationRecordQueue: [AWSAppSyncMutationRecord] = []
            for record in try db.prepare(sqlRecords) {
                do {
                    let mutationRecord = AWSAppSyncMutationRecord(
                        recordIdentifier: try record.get(recordIdentifier),
                        timestamp: try record.get(timestamp))
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
                            mutationRecord.s3ObjectInput = InternalS3ObjectDetails(
                                bucket: bucket,
                                key: key,
                                region: region,
                                mimeType: mimeType,
                                localUri: localUri)
                        }
                    } catch {
                        AppSyncLog.error("\(#function) failed \(error)")
                    }

                    mutationRecordQueue.append(mutationRecord)
                } catch {
                    AppSyncLog.error("\(#function) failed \(error)")
                }
            }

            return mutationRecordQueue
        }
    }
}
