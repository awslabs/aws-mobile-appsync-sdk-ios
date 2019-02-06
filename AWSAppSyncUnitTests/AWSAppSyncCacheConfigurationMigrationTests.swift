//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import XCTest

@testable import AWSAppSync
@testable import AWSAppSyncTestCommon
import SQLite

@available(*, deprecated, message: "These tests will be removed when the databaseURL parameter is removed from AWSAppSyncClientConfiguration")
class AWSAppSyncCacheConfigurationMigrationTests: XCTestCase {

    enum TestDatabaseFiles: String {
        case allTables = "cacheConfigUnitTests-allTables"
        case noOfflineMutation = "cacheConfigUnitTests-noMutationRecords"
        case noQueries = "cacheConfigUnitTests-noRecords"
        case noSubscriptionMetadata = "cacheConfigUnitTests-noSubscriptionMetadata"
        case noTables = "cacheConfigUnitTests-noTables"

        var databaseURL: URL {
            let bundle = Bundle.main
            let databaseURL = bundle.url(forResource: rawValue, withExtension: ".db")
            return databaseURL!
        }
    }

    var rootDirectory: URL {
        let rootPath = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        return rootPath
    }

    // Clear migration state before and after each test
    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: AWSAppSyncCacheConfigurationMigration.userDefaultsKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: AWSAppSyncCacheConfigurationMigration.userDefaultsKey)
        super.tearDown()
    }

    // Test that the data was copied correctly by doing a simple record count on each migrated table
    func testMigrationCopiesAllTables() throws {
        try? FileManager.default.removeItem(at: rootDirectory)

        let cacheConfiguration = try AWSAppSyncCacheConfiguration(withRootDirectory: rootDirectory)
        let databaseURL = TestDatabaseFiles.allTables.databaseURL
        try AWSAppSyncCacheConfigurationMigration.migrate(from: databaseURL, using: cacheConfiguration)

        // Validate offline mutations
        var db = try Connection(.uri(cacheConfiguration.offlineMutations!.absoluteString))
        var rowCount = try db.scalar("SELECT count(*) from mutation_records") as! Int64
        XCTAssertEqual(rowCount, 1, "Offline mutations has wrong count")

        // Validate queries
        db = try Connection(.uri(cacheConfiguration.queries!.absoluteString))
        rowCount = try db.scalar("SELECT count(*) from records") as! Int64
        XCTAssertEqual(rowCount, 477, "Offline mutations has wrong count")

        // Validate subscription metadata
        db = try Connection(.uri(cacheConfiguration.subscriptionMetadataCache!.absoluteString))
        rowCount = try db.scalar("SELECT count(*) from subscription_metadata") as! Int64
        XCTAssertEqual(rowCount, 1, "Offline mutations has wrong count")
    }

    func testMigrationSucceedsWithMissingOfflineMutationsTable() throws {
        try? FileManager.default.removeItem(at: rootDirectory)

        let cacheConfiguration = try AWSAppSyncCacheConfiguration(withRootDirectory: rootDirectory)
        let databaseURL = TestDatabaseFiles.noOfflineMutation.databaseURL
        try AWSAppSyncCacheConfigurationMigration.migrate(from: databaseURL, using: cacheConfiguration)

        // Validate offline mutations doesn't exist in offlineMutations cache db
        let db = try Connection(.uri(cacheConfiguration.offlineMutations!.absoluteString))
        let rowCount = try db.scalar("SELECT count(*) FROM sqlite_master WHERE type='table'") as! Int64
        XCTAssertEqual(rowCount, 0, "No table should be present")
    }

    func testMigrationSucceedsWithMissingQueriesTable() throws {
        try? FileManager.default.removeItem(at: rootDirectory)

        let cacheConfiguration = try AWSAppSyncCacheConfiguration(withRootDirectory: rootDirectory)
        let databaseURL = TestDatabaseFiles.noQueries.databaseURL
        try AWSAppSyncCacheConfigurationMigration.migrate(from: databaseURL, using: cacheConfiguration)

        // Validate queries doesn't exist in queries cache db
        let db = try Connection(.uri(cacheConfiguration.queries!.absoluteString))
        let rowCount = try db.scalar("SELECT count(*) FROM sqlite_master WHERE type='table'") as! Int64
        XCTAssertEqual(rowCount, 0, "No table should be present")
    }

    func testMigrationSucceedsWithMissingSubscriptionMetadataTable() throws {
        try? FileManager.default.removeItem(at: rootDirectory)

        let cacheConfiguration = try AWSAppSyncCacheConfiguration(withRootDirectory: rootDirectory)
        let databaseURL = TestDatabaseFiles.noSubscriptionMetadata.databaseURL
        try AWSAppSyncCacheConfigurationMigration.migrate(from: databaseURL, using: cacheConfiguration)

        // Validate queries doesn't exist in queries cache db
        let db = try Connection(.uri(cacheConfiguration.subscriptionMetadataCache!.absoluteString))
        let rowCount = try db.scalar("SELECT count(*) FROM sqlite_master WHERE type='table'") as! Int64
        XCTAssertEqual(rowCount, 0, "No table should be present")
    }

    func testMigrationSucceedsWithNoSourceTables() throws {
        try? FileManager.default.removeItem(at: rootDirectory)

        let cacheConfiguration = try AWSAppSyncCacheConfiguration(withRootDirectory: rootDirectory)
        let databaseURL = TestDatabaseFiles.noTables.databaseURL
        try AWSAppSyncCacheConfigurationMigration.migrate(from: databaseURL, using: cacheConfiguration)

        // Validate queries doesn't exist in queries cache db
        var db = try Connection(.uri(cacheConfiguration.offlineMutations!.absoluteString))
        var rowCount = try db.scalar("SELECT count(*) FROM sqlite_master WHERE type='table'") as! Int64
        XCTAssertEqual(rowCount, 0, "No table should be present in offlineMutations")

        db = try Connection(.uri(cacheConfiguration.queries!.absoluteString))
        rowCount = try db.scalar("SELECT count(*) FROM sqlite_master WHERE type='table'") as! Int64
        XCTAssertEqual(rowCount, 0, "No table should be present in queries")

        db = try Connection(.uri(cacheConfiguration.subscriptionMetadataCache!.absoluteString))
        rowCount = try db.scalar("SELECT count(*) FROM sqlite_master WHERE type='table'") as! Int64
        XCTAssertEqual(rowCount, 0, "No table should be present in subscriptionMetadataCache")
    }

    func testCanCreateClientWithMigratedDatabases() throws {
        try? FileManager.default.removeItem(at: rootDirectory)

        let cacheConfiguration = try AWSAppSyncCacheConfiguration(withRootDirectory: rootDirectory)
        let databaseURL = TestDatabaseFiles.allTables.databaseURL
        try AWSAppSyncCacheConfigurationMigration.migrate(from: databaseURL, using: cacheConfiguration)

        let helper = try AppSyncClientTestHelper(with: .apiKey,
                                                 testConfiguration: AppSyncClientTestConfiguration.forUnitTests,
                                                 cacheConfiguration: cacheConfiguration)

        XCTAssertNotNil(helper.appSyncClient)
    }

    func testMigrationThrowsIfDatabaseURLDoesNotExist() throws {
        try? FileManager.default.removeItem(at: rootDirectory)

        let cacheConfiguration = try AWSAppSyncCacheConfiguration(withRootDirectory: rootDirectory)
        let databaseURL = rootDirectory.appendingPathComponent("THIS_FILE_DOES_NOT_EXIST.db")

        do {
            try AWSAppSyncCacheConfigurationMigration.migrate(from: databaseURL, using: cacheConfiguration)
        } catch {
            XCTAssertNotNil(error)
            return
        }
        XCTFail("Expected migration to throw when attempting to copy a non-existent file")
    }

    func testMigrationDoesNotThrowForInMemoryCacheConfigurations() throws {
        let cacheConfiguration = AWSAppSyncCacheConfiguration.inMemory
        let databaseURL = TestDatabaseFiles.allTables.databaseURL

        do {
            try AWSAppSyncCacheConfigurationMigration.migrate(from: databaseURL, using: cacheConfiguration)
        } catch {
            XCTFail("Unexpected error migrating to in-memory cacheConfiguration: \(error)")
        }
    }

    func testMigrationSetsUserDefaultFlag() throws {
        try? FileManager.default.removeItem(at: rootDirectory)

        let flagBeforeMigration = UserDefaults.standard.bool(forKey: AWSAppSyncCacheConfigurationMigration.userDefaultsKey)
        XCTAssertFalse(flagBeforeMigration)

        let cacheConfiguration = try AWSAppSyncCacheConfiguration(withRootDirectory: rootDirectory)
        let databaseURL = TestDatabaseFiles.allTables.databaseURL
        try AWSAppSyncCacheConfigurationMigration.migrate(from: databaseURL, using: cacheConfiguration)

        let flagAfterMigration = UserDefaults.standard.bool(forKey: AWSAppSyncCacheConfigurationMigration.userDefaultsKey)
        XCTAssert(flagAfterMigration)
    }

    // Perform a migration with the "noTables" schema, then immediately perform another with the "allTables" schema.
    // Expect that no tables exist, since the followup migration should have been abandoned.
    func testMigrationOnlyPerformsOnce() throws {
        try? FileManager.default.removeItem(at: rootDirectory)
        let cacheConfiguration = try AWSAppSyncCacheConfiguration(withRootDirectory: rootDirectory)
        let firstSourceDatabase = TestDatabaseFiles.noTables.databaseURL
        try AWSAppSyncCacheConfigurationMigration.migrate(from: firstSourceDatabase, using: cacheConfiguration)

        let secondSourceDatabase = TestDatabaseFiles.allTables.databaseURL
        try AWSAppSyncCacheConfigurationMigration.migrate(from: secondSourceDatabase, using: cacheConfiguration)

        // Validate queries doesn't exist in queries cache db
        var db = try Connection(.uri(cacheConfiguration.offlineMutations!.absoluteString))
        var rowCount = try db.scalar("SELECT count(*) FROM sqlite_master WHERE type='table'") as! Int64
        XCTAssertEqual(rowCount, 0, "No table should be present in offlineMutations")

        db = try Connection(.uri(cacheConfiguration.queries!.absoluteString))
        rowCount = try db.scalar("SELECT count(*) FROM sqlite_master WHERE type='table'") as! Int64
        XCTAssertEqual(rowCount, 0, "No table should be present in queries")

        db = try Connection(.uri(cacheConfiguration.subscriptionMetadataCache!.absoluteString))
        rowCount = try db.scalar("SELECT count(*) FROM sqlite_master WHERE type='table'") as! Int64
        XCTAssertEqual(rowCount, 0, "No table should be present in subscriptionMetadataCache")
    }

    func testFailedMigrationDoesNotSetFlag() throws {
        let cacheConfiguration = try AWSAppSyncCacheConfiguration(withRootDirectory: rootDirectory)
        let databaseURL = rootDirectory.appendingPathComponent("THIS_FILE_DOES_NOT_EXIST.db")

        try? AWSAppSyncCacheConfigurationMigration.migrate(from: databaseURL, using: cacheConfiguration)

        let flagAfterMigration = UserDefaults.standard.bool(forKey: AWSAppSyncCacheConfigurationMigration.userDefaultsKey)
        XCTAssertFalse(flagAfterMigration)
    }

    func testMigrationToInMemoryCacheConfigurationDoesNotSetFlag() throws {
        let cacheConfiguration = AWSAppSyncCacheConfiguration.inMemory
        let databaseURL = TestDatabaseFiles.allTables.databaseURL

        try AWSAppSyncCacheConfigurationMigration.migrate(from: databaseURL, using: cacheConfiguration)

        let flagAfterMigration = UserDefaults.standard.bool(forKey: AWSAppSyncCacheConfigurationMigration.userDefaultsKey)
        XCTAssertFalse(flagAfterMigration)
    }

    func testThrowsIfDatabaseFileAlreadyExists() throws {
        let cacheConfiguration = try AWSAppSyncCacheConfiguration(withRootDirectory: rootDirectory)
        let databaseURL = TestDatabaseFiles.allTables.databaseURL
        try FileManager.default.copyItem(at: databaseURL, to: cacheConfiguration.offlineMutations!)

        do {
            try AWSAppSyncCacheConfigurationMigration.migrate(from: databaseURL, using: cacheConfiguration)
        } catch {
            XCTAssertNotNil(error)
            return
        }
        XCTFail("Expected migration to throw when attempting to copy a non-existent file")
    }

}
