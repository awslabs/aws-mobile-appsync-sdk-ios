//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

/// Errors thrown from the Queries Cache
public enum AWSAppSyncQueriesCacheError: Error {
    case invalidRecordEncoding(record: String)
    case invalidRecordShape(object: Any)
    case invalidRecordValue(value: Any)
}

/// Errors thrown during creation or migration of AppSync caches
public enum AWSCacheConfigurationError: Error, LocalizedError {
    /// Could not resolve the default Caches directory
    case couldNotResolveCachesDirectory

    public var errorDescription: String? {
        return String(describing: self)
    }

    public var localizedDescription: String {
        return String(describing: self)
    }
}

/// Defines the working directories of different caches in use by AWSAppSync. If the value is non-nil, then the cache
/// is persisted at that URL. If the value is nil, the cache will be created in-memory, and lost when the app is
/// restarted.
public struct AWSAppSyncCacheConfiguration {
    /// A cache configuration with all caches created as in-memory.
    public static let inMemory = AWSAppSyncCacheConfiguration(offlineMutations: nil, queries: nil, subscriptionMetadataCache: nil)

    /// A cache to store mutations created while the app is offline, to be delivered when the app regains network
    public let offlineMutations: URL?

    /// An instance of Apollo's NormalizedCache to locally cache query data
    public let queries: URL?

    /// A local cache to store information about active subscriptions, used to reconnect to subscriptions when the
    /// app is relaunched
    public let subscriptionMetadataCache: URL?

    /// Creates a cache configuration with individually-specified cache paths. If a path is nil, the cache will
    /// be created in-memory. If specified, the directory portion of the file path must exist, and be writable by the
    /// hosting app. No attempt is made to validate the specified file paths until AppSync initializes the related
    /// cache at the specified path.
    ///
    /// - Parameters:
    ///   - offlineMutations: The file path to create or connect to the cache for the offline mutation queue.
    ///   - queries: The file path to create or connect to the cache for the local query cache.
    ///   - subscriptionMetadataCache: The file path to create or connect to the cache for subscription metadata.
    public init(offlineMutations: URL?, queries: URL?, subscriptionMetadataCache: URL?) {
        self.offlineMutations = offlineMutations
        self.queries = queries
        self.subscriptionMetadataCache = subscriptionMetadataCache
    }

    /// Creates a cache configuration for caches at the specified workingDirectory. Attempts to create the directory
    /// if it does not already exist.
    ///
    /// - Parameter url: The directory path at which to store persistent caches. Defaults to `<appCacheDirectory>/appsync`
    /// - Throws: Throws an error if `workingDirectory` is not a directory, or if it cannot be created.
    public init(withRootDirectory url: URL? = nil) throws {
        let resolvedRootDirectory: URL
        if let rootDirectory = url {
            resolvedRootDirectory = rootDirectory
        } else {
            guard let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
                throw AWSCacheConfigurationError.couldNotResolveCachesDirectory
            }
            resolvedRootDirectory = cachesDirectory.appendingPathComponent("appsync")
        }

        try FileManager.default.createDirectory(at: resolvedRootDirectory, withIntermediateDirectories: true)

        offlineMutations = resolvedRootDirectory.appendingPathComponent("offlineMutations.db")
        queries = resolvedRootDirectory.appendingPathComponent("queries.db")
        subscriptionMetadataCache = resolvedRootDirectory.appendingPathComponent("subscriptionMetadataCache.db")
    }
}
