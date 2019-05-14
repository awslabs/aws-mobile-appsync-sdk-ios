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
    /// Did not match requirements to be database prefix ^[_a-zA-Z]+$
    case invalidClientDatabasePrefix
    /// The client database prefix was not found in the configuration
    case missingClientDatabasePrefix

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

    let prefix: String?

    let usePrefix: Bool

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
        prefix = nil
        usePrefix = false
    }

    /// Creates a cache configuration for caches at the specified workingDirectory. Attempts to create the directory
    /// if it does not already exist.
    ///
    /// - Parameter url: The directory path at which to store persistent caches. Defaults to `<appCacheDirectory>/appsync`
    /// - Throws: Throws an error if `workingDirectory` is not a directory, or if it cannot be created.
    public init(withRootDirectory url: URL? = nil, useClientDatabasePrefix: Bool = false, appSyncServiceConfig: AWSAppSyncServiceConfigProvider? = nil) throws {
        let resolvedRootDirectory: URL
        if let rootDirectory = url {
            resolvedRootDirectory = rootDirectory
        } else {
            guard let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
                throw AWSCacheConfigurationError.couldNotResolveCachesDirectory
            }
            resolvedRootDirectory = cachesDirectory.appendingPathComponent("appsync")
        }

        let resolvedClientDatabasePrefix: String
        if (useClientDatabasePrefix) {
            guard let clientDatabasePrefix = appSyncServiceConfig?.clientDatabasePrefix else {
                throw AWSCacheConfigurationError.missingClientDatabasePrefix
            }
            guard clientDatabasePrefix.range(of: "^[_a-zA-Z0-9]+$", options: .regularExpression) != nil else {
                throw AWSCacheConfigurationError.invalidClientDatabasePrefix
            }
            resolvedClientDatabasePrefix = clientDatabasePrefix + "_"
            prefix = resolvedClientDatabasePrefix
        } else {
            resolvedClientDatabasePrefix = ""
            prefix = nil
            if appSyncServiceConfig?.clientDatabasePrefix != nil {
                AppSyncLog.info("The client database prefix was specified even though useClientDatabasePrefix is false.")
            }
        }
        usePrefix = useClientDatabasePrefix

        try FileManager.default.createDirectory(at: resolvedRootDirectory, withIntermediateDirectories: true)

        offlineMutations = resolvedRootDirectory.appendingPathComponent(resolvedClientDatabasePrefix + "offlineMutations.db")
        queries = resolvedRootDirectory.appendingPathComponent(resolvedClientDatabasePrefix + "queries.db")
        subscriptionMetadataCache = resolvedRootDirectory.appendingPathComponent(resolvedClientDatabasePrefix + "subscriptionMetadataCache.db")
    }
}

/// Allows the developer to fine-tune which caches are cleared in the client.
public struct ClearCacheOptions {
    /// True if clears the query cache for this client
    let clearQueries: Bool

    /// True if clears the offline mutations for this client
    let clearMutations: Bool

    /// True if clears the subscription metadata for this client
    let clearSubscriptions: Bool

    public init(clearQueries: Bool = false, clearMutations: Bool = false, clearSubscriptions: Bool = false) {
        self.clearQueries = clearQueries
        self.clearMutations = clearMutations
        self.clearSubscriptions = clearSubscriptions
    }
}

/// Used to differentiate the cache that was cleared using AWSAppSyncClient.clearCaches(options:)
public enum CacheType: String {
    case query
    case mutation
    case subscription
}

/// Errors thrown trying to clear the client's caches
public enum ClearCacheError: Error {
    case failedToClear([CacheType:Error])
}

// MARK: - LocalizedError

/// More information from the cache clearing error
extension ClearCacheError: LocalizedError {

    public var errorDescription: String? {
        var message: String

        switch self {
        case .failedToClear(let cacheErrorMap):
            message = "Failed to clear caches: " + cacheErrorMap.keys.flatMap { $0.rawValue }
        }

        return message
    }

    /// A map of the errors the caches threw during clearing
    public var failures: [CacheType: Error] {
        var map: [CacheType: Error]
        switch self {
        case .failedToClear(let cacheErrorMap):
            map = cacheErrorMap
        }
        return map
    }
}
