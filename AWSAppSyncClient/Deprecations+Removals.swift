//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

extension AWSAppSyncClientError {

    @available(*, deprecated, message: "use the enum pattern matching instead")
    public var body: Data? {
        switch self {
        case .parseError(let data, _, _):
            return data
        case .requestFailed(let data, _, _):
            return data
        case .noData, .authenticationError:
            return nil
        }
    }

    @available(*, deprecated, message: "use the enum pattern matching instead")
    public var response: HTTPURLResponse? {
        switch self {
        case .parseError(_, let response, _):
            return response
        case .requestFailed(_, let response, _):
            return response
        case .noData, .authenticationError:
            return nil
        }
    }

    @available(*, deprecated)
    var isInternalError: Bool {
        return false
    }

    @available(*, deprecated, message: "use errorDescription instead")
    var additionalInfo: String? {
        switch self {
        case .parseError:
            return "Could not parse response data."
        case .requestFailed:
            return "Did not receive a successful HTTP code."
        case .noData, .authenticationError:
            return "No Data received in response."
        }
    }
}

@available(*, deprecated, renamed: "AWSAppSyncQueriesCacheError", message: "This error is no longer being thrown and will be removed in an upcoming release.")
public enum AWSSQLLiteNormalizedCacheError: Error {
    case invalidRecordEncoding(record: String)
    case invalidRecordShape(object: Any)
    case invalidRecordValue(value: Any)
}

@available(*, deprecated, message: "This protocol is unused")
public protocol MutationCache {
    /// Saves a mutation to the cache, and returns a unique sequence number for it
    func saveMutation(body: Data) -> Int64
    func getMutation(id: Int64) -> Data
    func loadAllMutation() -> [Int64: Data]
}

public extension AWSAppSyncClientConfiguration {
    @available(*, deprecated, message: "Use an initializer that takes cacheConfiguration instead of databaseURL")
    public convenience init(appSyncServiceConfig: AWSAppSyncServiceConfigProvider,
                            networkTransport: AWSNetworkTransport,
                            databaseURL: URL?,
                            connectionStateChangeHandler: ConnectionStateChangeHandler? = nil,
                            s3ObjectManager: AWSS3ObjectManager? = nil,
                            presignedURLClient: AWSS3ObjectPresignedURLGenerator? = nil) {

        self.init(appSyncServiceConfig: appSyncServiceConfig,
                  networkTransport: networkTransport,
                  cacheConfiguration: AWSAppSyncCacheConfiguration(from: databaseURL),
                  connectionStateChangeHandler: connectionStateChangeHandler,
                  s3ObjectManager: s3ObjectManager,
                  presignedURLClient: presignedURLClient)
    }

    @available(*, deprecated, message: "Use an initializer that takes cacheConfiguration instead of databaseURL")
    public convenience init(url: URL,
                            serviceRegion: AWSRegionType,
                            networkTransport: AWSNetworkTransport,
                            databaseURL: URL?,
                            connectionStateChangeHandler: ConnectionStateChangeHandler? = nil,
                            s3ObjectManager: AWSS3ObjectManager? = nil,
                            presignedURLClient: AWSS3ObjectPresignedURLGenerator? = nil) {
        self.init(url: url,
                  serviceRegion: serviceRegion,
                  networkTransport: networkTransport,
                  cacheConfiguration: AWSAppSyncCacheConfiguration(from: databaseURL),
                  connectionStateChangeHandler: connectionStateChangeHandler,
                  s3ObjectManager: s3ObjectManager,
                  presignedURLClient: presignedURLClient)
    }

    @available(*, deprecated, message: "Use an initializer that takes cacheConfiguration instead of databaseURL")
    public convenience init(url: URL,
                            serviceRegion: AWSRegionType,
                            apiKeyAuthProvider: AWSAPIKeyAuthProvider? = nil,
                            credentialsProvider: AWSCredentialsProvider? = nil,
                            oidcAuthProvider: AWSOIDCAuthProvider? = nil,
                            userPoolsAuthProvider: AWSCognitoUserPoolsAuthProvider? = nil,
                            urlSessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default,
                            databaseURL: URL?,
                            connectionStateChangeHandler: ConnectionStateChangeHandler? = nil,
                            s3ObjectManager: AWSS3ObjectManager? = nil,
                            presignedURLClient: AWSS3ObjectPresignedURLGenerator? = nil) throws {
        try self.init(url: url,
                      serviceRegion: serviceRegion,
                      apiKeyAuthProvider: apiKeyAuthProvider,
                      credentialsProvider: credentialsProvider,
                      oidcAuthProvider: oidcAuthProvider,
                      userPoolsAuthProvider: userPoolsAuthProvider,
                      urlSessionConfiguration: urlSessionConfiguration,
                      cacheConfiguration: AWSAppSyncCacheConfiguration(from: databaseURL),
                      connectionStateChangeHandler: connectionStateChangeHandler,
                      s3ObjectManager: s3ObjectManager,
                      presignedURLClient: presignedURLClient)
    }

    @available(*, deprecated, message: "Use an initializer that takes cacheConfiguration instead of databaseURL")
    public convenience init(appSyncServiceConfig: AWSAppSyncServiceConfigProvider,
                            apiKeyAuthProvider: AWSAPIKeyAuthProvider? = nil,
                            credentialsProvider: AWSCredentialsProvider? = nil,
                            oidcAuthProvider: AWSOIDCAuthProvider? = nil,
                            userPoolsAuthProvider: AWSCognitoUserPoolsAuthProvider? = nil,
                            urlSessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default,
                            databaseURL: URL?,
                            connectionStateChangeHandler: ConnectionStateChangeHandler? = nil,
                            s3ObjectManager: AWSS3ObjectManager? = nil,
                            presignedURLClient: AWSS3ObjectPresignedURLGenerator? = nil) throws {
        try self.init(appSyncServiceConfig: appSyncServiceConfig,
            apiKeyAuthProvider: apiKeyAuthProvider,
            credentialsProvider: credentialsProvider,
            oidcAuthProvider: oidcAuthProvider,
            userPoolsAuthProvider: userPoolsAuthProvider,
            urlSessionConfiguration: urlSessionConfiguration,
            cacheConfiguration: AWSAppSyncCacheConfiguration(from: databaseURL),
            connectionStateChangeHandler: connectionStateChangeHandler,
            s3ObjectManager: s3ObjectManager,
            presignedURLClient: presignedURLClient)
    }

}

public extension AWSAppSyncCacheConfiguration {
    init(from databaseURL: URL?) {
        self.init(offlineMutations: databaseURL,
                  queries: databaseURL,
                  subscriptionMetadataCache: databaseURL)
    }
}
