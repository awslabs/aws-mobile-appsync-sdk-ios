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
