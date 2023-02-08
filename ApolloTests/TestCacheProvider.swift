import XCTest
@testable import AWSAppSync

public protocol TestCacheProvider: AnyObject {
  static func withCache(initialRecords: RecordSet?, execute test: (NormalizedCache) throws -> ()) rethrows
}

public class InMemoryTestCacheProvider: TestCacheProvider {
  /// Execute a test block rather than return a cache synchronously, since cache setup may be
  /// asynchronous at some point.
  public static func withCache(initialRecords: RecordSet? = nil, execute test: (NormalizedCache) throws -> ()) rethrows {
    let cache = InMemoryNormalizedCache(records: initialRecords ?? [:])
    try test(cache)
  }
}

extension XCTestCase {
  public static var bundleDirectoryURL: URL {
    return Bundle(for: self).bundleURL.deletingLastPathComponent()
  }
  
  public static var cacheProviderClass: TestCacheProvider.Type {
    guard let cacheProviderClassName = ProcessInfo.processInfo.environment["APOLLO_TEST_CACHE_PROVIDER"] else {
      fatalError("Please define the APOLLO_TEST_CACHE_PROVIDER environment variable")
    }
    
    guard let cacheProviderClass = _typeByName(cacheProviderClassName) as? TestCacheProvider.Type else {
      fatalError("Could not load APOLLO_TEST_CACHE_PROVIDER \(cacheProviderClassName)")
    }
    
    return cacheProviderClass
  }
  
  public func withCache(initialRecords: RecordSet? = nil, execute test: (NormalizedCache) throws -> ()) rethrows {
    return try type(of: self).cacheProviderClass.withCache(initialRecords: initialRecords, execute: test)
  }
}

public class SQLiteTestCacheProvider: TestCacheProvider {
    public static func withCache(initialRecords: RecordSet? = nil, execute test: (NormalizedCache) throws -> ()) rethrows {
        return try withCache(initialRecords: initialRecords, fileURL: nil, execute: test)
    }

    /// Execute a test block rather than return a cache synchronously, since cache setup may be
    /// asynchronous at some point.
    public static func withCache(initialRecords: RecordSet? = nil, fileURL: URL? = nil, execute test: (NormalizedCache) throws -> ()) rethrows {
        let fileURL = fileURL ?? temporarySQLiteFileURL()
        let cache = try! AWSSQLiteNormalizedCache(fileURL: fileURL)
        if let initialRecords = initialRecords {
            _ = cache.merge(records: initialRecords) // This is synchronous
        }
        try test(cache)
    }

    public static func temporarySQLiteFileURL() -> URL {
        let applicationSupportPath = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first!
        let applicationSupportURL = URL(fileURLWithPath: applicationSupportPath)
        let temporaryDirectoryURL = try! FileManager.default.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: applicationSupportURL,
            create: true)
        return temporaryDirectoryURL.appendingPathComponent("db.sqlite3")
    }
}
