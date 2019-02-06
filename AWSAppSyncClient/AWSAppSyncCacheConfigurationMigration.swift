//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
import SQLite

@available(*, deprecated, message: "This utility will be removed when the databaseURL parameter is removed from AWSAppSyncClientConfiguration")
public struct AWSAppSyncCacheConfigurationMigration {
    public enum Error: Swift.Error {
        /// The destination file specified by the cache configuration already exists
        case destinationFileExists
    }
    
    /// A UserDefaults key that will be set once any successful migration has been completed
    public static let userDefaultsKey = "AWSAppSyncCacheConfigurationMigration.success"
    
    private enum TableName: String, CaseIterable {
        case offlineMutations = "mutation_records"
        case queries = "records"
        case subscriptionMetadata = "subscription_metadata"
    }
    
    /// A convenience method to migrate data from caches created prior to AWSAppSync 2.10.0. Once this migration
    /// completes, the old cache should be deleted. This method is safe to call multiple times: it stores a key in
    /// UserDefaults to indicate that the migration was successfully completed, and will only migrate if that flag is
    /// not set. That makes this method safe to call whenever you need to configure a new AppSyncClient (e.g., app
    /// startup or user login).
    ///
    /// **Usage**
    /// Invoke `migrate` before setting up the AWSAppSyncClientConfiguration:
    ///
    ///     // Given `databaseURL` is the old consolidated databaseURL...
    ///
    ///     // Create a default cacheConfiguration with cache files stored in the app's Caches directory
    ///     let cacheConfiguration = try AWSAppSyncCacheConfiguration()
    ///     try? AWSAppSyncCacheConfigurationMigration.migrate(from: databaseURL, using: cacheConfiguration)
    ///     let clientConfig = try AWSAppSyncClientConfiguration(appSyncServiceConfig: serviceConfig,
    ///                                                          cacheConfiguration: cacheConfiguration)
    ///     let appSyncClient = AWSAppSyncClient(appSyncConfig: clientConfig)
    ///
    /// **How it works**
    /// Internally, this method copies the database file from the source URL to the destination, and then drops
    /// unneeded tables. This results in higher disk usage on device, but is ultimately faster and safer than
    /// performing queries or data exports.creates a new connection to both the source and destination databases.
    ///
    /// **Multiple calls**
    /// A successful migration to a cache configuration with at least one persistent store will write a flag to
    /// UserDefaults to prevent any future migrations from occurring. Migrating to an in-memory cache (such as is
    /// configured by passing no `AWSAppSyncCacheConfiguration` to the `AWSAppSyncClientConfiguration` constructor,
    /// or by passing `AWSAppSyncCacheConfiguration.inMemory`) will __not__ set the flag. That also means this method
    /// will not populate an in-memory copy of a previously existing on-disk database.
    ///
    /// **Warning**
    /// This migration operates by copying the file from `databaseURL` to the URL of the individual cache.
    /// This would destroy any data at the destination cache, so the destination URL must not have a file present at
    /// the time the migration begins.
    ///
    /// - Parameters:
    ///   - databaseURL: The URL of the consolidated cache
    ///   - cacheConfiguration: The AWSAppSyncCacheConfiguration specifying the individual destination cache
    ///     locations to migrate to
    /// - Throws: If the migration encounters an file system error, or if any of the cache files in
    ///   `cacheConfiguration` already exists.
    public static func migrate(from databaseURL: URL, using cacheConfiguration: AWSAppSyncCacheConfiguration) throws {
        guard !hasSuccessfullyMigrated() else {
            AppSyncLog.info("Migration has already been completed, aborting")
            return
        }
        
        guard cacheConfiguration.offlineMutations != nil ||
            cacheConfiguration.queries != nil ||
            cacheConfiguration.subscriptionMetadataCache != nil else {
                AppSyncLog.info("At least one cacheConfiguration must be non-nil")
                return
        }
        
        try migrate(.offlineMutations,
                    from: databaseURL,
                    to: cacheConfiguration.offlineMutations)
        
        try migrate(.queries,
                    from: databaseURL,
                    to: cacheConfiguration.queries)
        
        try migrate(.subscriptionMetadata,
                    from: databaseURL,
                    to: cacheConfiguration.subscriptionMetadataCache)
        
        recordSuccessfulMigration()
    }
    
    private static func hasSuccessfullyMigrated() -> Bool {
        let hasMigrated = UserDefaults.standard.bool(forKey: userDefaultsKey)
        return hasMigrated
    }
    
    private static func migrate(_ tableName: TableName,
                                from databaseURL: URL,
                                to destinationURL: URL?) throws {
        guard let destinationURL = destinationURL else {
            return
        }
        
        try copyIfDestinationNotExists(from: databaseURL, to: destinationURL)
        
        let destinationDB = try Connection(.uri(destinationURL.absoluteString))
        
        try deleteOtherTables(than: tableName, in: destinationDB)
    }
    
    private static func copyIfDestinationNotExists(from sourceURL: URL, to destinationURL: URL) throws {
        let fileManager = FileManager.default
        
        guard !fileManager.fileExists(atPath: destinationURL.path) else {
            throw Error.destinationFileExists
        }
        
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
    }
    
    private static func deleteOtherTables(than tableName: TableName, in db: Connection) throws {
        for tableToDelete in TableName.allCases where tableToDelete != tableName {
            try db.run("DROP TABLE IF EXISTS \(tableToDelete.rawValue)")
        }
        
        try db.run("VACUUM")
    }
    
    private static func recordSuccessfulMigration() {
        UserDefaults.standard.set(true, forKey: userDefaultsKey)
    }
    
}
