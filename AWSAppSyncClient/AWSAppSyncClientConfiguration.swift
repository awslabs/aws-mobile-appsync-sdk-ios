//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
import AWSCore

public class AWSAppSyncClientConfiguration {
    private(set) var url: URL
    private(set) var networkTransport: AWSNetworkTransport
    @available(*, deprecated, message: "Use cacheConfiguration instead")
    private(set) var databaseURL: URL?
    private(set) var cacheConfiguration: AWSAppSyncCacheConfiguration?
    private(set) var workingDirectory: URL?
    private(set) var store: ApolloStore
    private(set) var subscriptionMetadataCache: AWSSubscriptionMetaDataCache?
    private(set) var s3ObjectManager: AWSS3ObjectManager? = nil
    private(set) var presignedURLClient: AWSS3ObjectPresignedURLGenerator? = nil
    private(set) var connectionStateChangeHandler: ConnectionStateChangeHandler? = nil
    private(set) var allowsCellularAccess: Bool = true
    private(set) var autoSubmitOfflineMutations: Bool = true
    var authType: AWSAppSyncAuthType?
    // retry strategy is set during initializing the configuration object and cannot be changed on the fly.
    let retryStrategy: AWSAppSyncRetryStrategy

    // MARK: - Initializers that specify the network transport

    /// Convenience initializer to create a configuration object for the `AWSAppSyncClient` using a caller-specified
    /// AWSNetworkTransport. The service URL and region are retrieved from `appSyncClientInfo`.
    ///
    /// - Parameters:
    ///   - appSyncServiceConfig: The configuration information represented in awsconfiguration.json file.
    ///   - networkTransport: The network transport used to communicate with the server.
    ///   - cacheConfiguration: Configuration for local queries, mutations, and subscriptions caches.
    ///   - connectionStateChangeHandler: The delegate object to be notified when client network state changes.
    ///   - s3ObjectManager: The client used for uploading / downloading `S3Objects`.
    ///   - presignedURLClient: The `AWSS3ObjectPresignedURLGenerator` object.
    ///   - retryStrategy: The `AWSAppSyncRetryStrategy` object which determines the retry strategy for client.
    ///
    public convenience init(appSyncServiceConfig: AWSAppSyncServiceConfigProvider,
                            networkTransport: AWSNetworkTransport,
                            cacheConfiguration: AWSAppSyncCacheConfiguration? = nil,
                            connectionStateChangeHandler: ConnectionStateChangeHandler? = nil,
                            s3ObjectManager: AWSS3ObjectManager? = nil,
                            presignedURLClient: AWSS3ObjectPresignedURLGenerator? = nil,
                            retryStrategy: AWSAppSyncRetryStrategy = .exponential) {
        let urlFromConfig = appSyncServiceConfig.endpoint
        let regionFromConfig = appSyncServiceConfig.region

        self.init(url: urlFromConfig,
                  serviceRegion: regionFromConfig,
                  networkTransport: networkTransport,
                  cacheConfiguration: cacheConfiguration,
                  connectionStateChangeHandler: connectionStateChangeHandler,
                  s3ObjectManager: s3ObjectManager,
                  presignedURLClient: presignedURLClient,
                  retryStrategy: retryStrategy)
    }

    /// Creates a configuration object for the `AWSAppSyncClient` using a caller-specified AWSNetworkTransport.
    ///
    /// - Parameters:
    ///   - url: The endpoint url for Appsync endpoint.
    ///   - serviceRegion: The service region for Appsync.
    ///   - networkTransport: The network transport used to communicate with the server.
    ///   - cacheConfiguration: Configuration for local queries, mutations, and subscriptions caches.
    ///   - connectionStateChangeHandler: The delegate object to be notified when client network state changes.
    ///   - s3ObjectManager: The client used for uploading / downloading `S3Objects`.
    ///   - presignedURLClient: The `AWSAppSyncClientConfiguration` object.
    ///   - retryStrategy: The `AWSAppSyncRetryStrategy` object which determines the retry strategy for client.
    ///
    public init(url: URL,
                serviceRegion: AWSRegionType,
                networkTransport: AWSNetworkTransport,
                cacheConfiguration: AWSAppSyncCacheConfiguration? = nil,
                connectionStateChangeHandler: ConnectionStateChangeHandler? = nil,
                s3ObjectManager: AWSS3ObjectManager? = nil,
                presignedURLClient: AWSS3ObjectPresignedURLGenerator? = nil,
                retryStrategy: AWSAppSyncRetryStrategy = .exponential) {
        self.url = url
        self.cacheConfiguration = cacheConfiguration
        self.store = AWSAppSyncClientConfiguration.makeApolloStore(for: cacheConfiguration?.queries)
        self.subscriptionMetadataCache = AWSAppSyncClientConfiguration.makeSubscriptionMetadataCache(for: cacheConfiguration?.subscriptionMetadataCache)
        self.networkTransport = networkTransport
        self.s3ObjectManager = s3ObjectManager
        self.presignedURLClient = presignedURLClient
        self.connectionStateChangeHandler = connectionStateChangeHandler
        self.retryStrategy = retryStrategy
    }

    // MARK: - Initializers that derive the network transport from auth provider configuration

    /// Creates a configuration object for the `AWSAppSyncClient` using configurations from `appSyncClientInfo`.
    ///
    /// Internally, this method creates an AWSHTTPNetworkTransport using one of the provided auth providers.
    /// The incoming arguments must meet exactly one of the following conditions
    /// - `apiKeyAuthProvider` is nil, `appSyncClientInfo.authType` is "API_KEY", and `appSyncClientInfo.apiKey` has a valid
    ///   value
    /// - `apiKeyAuthProvider` is specified, and `appSyncClientInfo.authType` is "API_KEY". The value of
    ///   `appSyncClientInfo.apiKey` is ignored.
    /// - `credentialsProvider` is nil, `appSyncClientInfo.authType` is "AWS_IAM", and the app's `awsconfiguration.json` file
    ///   has a valid "CredentialsProvider" configuration.
    /// - `credentialsProvider` is specified, and `appSyncClientInfo.authType` is "AWS_IAM". The "CredentialsProvider" config in
    ///   the app's `awsconfiguration.json` is ignored, except insofar as the caller may have used it to create the incoming
    ///   `credentialsProvider`.
    /// - `oidcAuthProvider` is specified, and `appSyncClientInfo.authType` is "OPENID_CONNECT"
    /// - `userPoolsAuthProvider` is specified, and `appSyncClientInfo.authType` is "AMAZON_COGNITO_USER_POOLS"
    ///
    /// If none of those conditions are met, or if more than provider is specified, the initializer will throw an error.
    ///
    /// - Parameters:
    ///   - appSyncServiceConfig: The configuration information represented in awsconfiguration.json file.
    ///   - apiKeyAuthProvider: A `AWSAPIKeyAuthProvider` protocol object for API Key based authorization.
    ///   - credentialsProvider: A `AWSCredentialsProvider` object for AWS_IAM based authorization.
    ///   - userPoolsAuthProvider: A `AWSCognitoUserPoolsAuthProvider` protocol object for User Pool based authorization.
    ///   - oidcAuthProvider: A `AWSOIDCAuthProvider` protocol object for OIDC based authorization.
    ///   - urlSessionConfiguration: A `URLSessionConfiguration` configuration object for custom HTTP configuration.
    ///   - cacheConfiguration: Configuration for local queries, mutations, and subscriptions caches.
    ///   - connectionStateChangeHandler: The delegate object to be notified when client network state changes.
    ///   - s3ObjectManager: The client used for uploading / downloading `S3Objects`.
    ///   - presignedURLClient: The `AWSAppSyncClientConfiguration` object.
    ///   - retryStrategy: The `AWSAppSyncRetryStrategy` object which determines the retry strategy for client.
    ///
    /// - Throws: A AWSAppSyncClientConfigurationError if the auth configuration is invalid
    public convenience init(appSyncServiceConfig: AWSAppSyncServiceConfigProvider,
                            apiKeyAuthProvider: AWSAPIKeyAuthProvider? = nil,
                            credentialsProvider: AWSCredentialsProvider? = nil,
                            oidcAuthProvider: AWSOIDCAuthProvider? = nil,
                            userPoolsAuthProvider: AWSCognitoUserPoolsAuthProvider? = nil,
                            urlSessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default,
                            cacheConfiguration: AWSAppSyncCacheConfiguration? = nil,
                            connectionStateChangeHandler: ConnectionStateChangeHandler? = nil,
                            s3ObjectManager: AWSS3ObjectManager? = nil,
                            presignedURLClient: AWSS3ObjectPresignedURLGenerator? = nil,
                            retryStrategy: AWSAppSyncRetryStrategy = .exponential) throws {

        let apiKeyFromConfig = appSyncServiceConfig.apiKey
        let authTypeFromConfig = appSyncServiceConfig.authType
        let urlFromConfig = appSyncServiceConfig.endpoint
        let regionFromConfig = appSyncServiceConfig.region

        try self.init(url: urlFromConfig,
                      serviceRegion: regionFromConfig,
                      authType: authTypeFromConfig,
                      apiKey: apiKeyFromConfig,
                      apiKeyAuthProvider: apiKeyAuthProvider,
                      credentialsProvider: credentialsProvider,
                      userPoolsAuthProvider: userPoolsAuthProvider,
                      oidcAuthProvider: oidcAuthProvider,
                      urlSessionConfiguration: urlSessionConfiguration,
                      cacheConfiguration: cacheConfiguration,
                      connectionStateChangeHandler: connectionStateChangeHandler,
                      s3ObjectManager: s3ObjectManager,
                      presignedURLClient: presignedURLClient,
                      retryStrategy: retryStrategy)
    }

    /// Creates a configuration object for the `AWSAppSyncClient`.
    ///
    /// Internally, this method creates an AWSHTTPNetworkTransport using one of the provided auth providers.
    /// The incoming arguments must meet exactly one of the following conditions
    /// - `apiKeyAuthProvider` is specified
    /// - `credentialsProvider` is specified
    /// - `oidcAuthProvider` is specified
    /// - `userPoolsAuthProvider` is specified
    ///
    /// If all of the provider arguments are nil, or if more than one are specified, the initializer will throw an error.
    ///
    /// - Parameters:
    ///   - url: The endpoint url for Appsync endpoint
    ///   - serviceRegion: The service region for Appsync
    ///   - apiKeyAuthProvider: A `AWSAPIKeyAuthProvider` protocol object for API Key based authorization
    ///   - credentialsProvider: A `AWSCredentialsProvider` object for AWS_IAM based authorization
    ///   - oidcAuthProvider: A `AWSOIDCAuthProvider` protocol object for OIDC based authorization
    ///   - userPoolsAuthProvider: A `AWSCognitoUserPoolsAuthProvider` protocol object for User Pool based authorization
    ///   - urlSessionConfiguration: A `URLSessionConfiguration` configuration object for custom HTTP configuration
    ///   - cacheConfiguration: Configuration for local queries, mutations, and subscriptions caches.
    ///   - connectionStateChangeHandler: The delegate object to be notified when client network state changes
    ///   - s3ObjectManager: The client used for uploading / downloading `S3Objects`
    ///   - presignedURLClient: The `AWSAppSyncClientConfiguration` object
    ///   - retryStrategy: The `AWSAppSyncRetryStrategy` object which determines the retry strategy for client.
    ///
    /// - Throws: A AWSAppSyncClientConfigurationError if the auth configuration is invalid
    public convenience init(url: URL,
                            serviceRegion: AWSRegionType,
                            apiKeyAuthProvider: AWSAPIKeyAuthProvider? = nil,
                            credentialsProvider: AWSCredentialsProvider? = nil,
                            oidcAuthProvider: AWSOIDCAuthProvider? = nil,
                            userPoolsAuthProvider: AWSCognitoUserPoolsAuthProvider? = nil,
                            urlSessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default,
                            cacheConfiguration: AWSAppSyncCacheConfiguration? = nil,
                            connectionStateChangeHandler: ConnectionStateChangeHandler? = nil,
                            s3ObjectManager: AWSS3ObjectManager? = nil,
                            presignedURLClient: AWSS3ObjectPresignedURLGenerator? = nil,
                            retryStrategy: AWSAppSyncRetryStrategy = .exponential) throws {
        let authType: AWSAppSyncAuthType

        if apiKeyAuthProvider != nil {
            authType = .apiKey
        } else if credentialsProvider != nil {
            authType = .awsIAM
        } else if oidcAuthProvider != nil {
            authType = .oidcToken
        } else if userPoolsAuthProvider != nil {
            authType = .amazonCognitoUserPools
        } else {
            throw AWSAppSyncClientConfigurationError.invalidAuthConfiguration("Invalid auth provider configuration. Exactly one of the supported auth providers must be passed")
        }

        try self.init(url: url,
                      serviceRegion: serviceRegion,
                      authType: authType,
                      apiKey: nil,
                      apiKeyAuthProvider: apiKeyAuthProvider,
                      credentialsProvider: credentialsProvider,
                      userPoolsAuthProvider: userPoolsAuthProvider,
                      oidcAuthProvider: oidcAuthProvider,
                      urlSessionConfiguration: urlSessionConfiguration,
                      cacheConfiguration: cacheConfiguration,
                      connectionStateChangeHandler: connectionStateChangeHandler,
                      s3ObjectManager: s3ObjectManager,
                      presignedURLClient: presignedURLClient,
                      retryStrategy: retryStrategy)
    }

    // MARK: - Designated initializer that derives network transport from auth configuration

    /// Creates a configuration object for the `AWSAppSyncClient`.
    ///
    /// - Parameters:
    ///   - url: The endpoint url for AppSync endpoint.
    ///   - serviceRegion: The service region for AppSync.
    ///   - authType: The Mode of Authentication used with AppSync
    ///   - apiKey: An API key to use to create an APIKeyAuthProvider
    ///   - apiKeyAuthProvider: A `AWSAPIKeyAuthProvider` protocol object for API Key based authorization.
    ///   - credentialsProvider: A `AWSCredentialsProvider` object for AWS_IAM based authorization.
    ///   - userPoolsAuthProvider: A `AWSCognitoUserPoolsAuthProvider` protocol object for Cognito User Pools based authorization.
    ///   - oidcAuthProvider: A `AWSOIDCAuthProvider` protocol object for any OpenId Connect based authorization.
    ///   - urlSessionConfiguration: A `URLSessionConfiguration` configuration object for custom HTTP configuration.
    ///   - cacheConfiguration: Configuration for local queries, mutations, and subscriptions caches.
    ///   - connectionStateChangeHandler: The delegate object to be notified when client network state changes.
    ///   - s3ObjectManager: The client used for uploading / downloading `S3Objects`.
    ///   - presignedURLClient: The `AWSAppSyncClientConfiguration` object.
    ///
    /// - Throws: A AWSAppSyncClientConfigurationError if the auth configuration is invalid
    private init(url: URL,
                 serviceRegion: AWSRegionType,
                 authType: AWSAppSyncAuthType,
                 apiKey: String?,
                 apiKeyAuthProvider: AWSAPIKeyAuthProvider?,
                 credentialsProvider: AWSCredentialsProvider?,
                 userPoolsAuthProvider: AWSCognitoUserPoolsAuthProvider?,
                 oidcAuthProvider: AWSOIDCAuthProvider?,
                 urlSessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default,
                 cacheConfiguration: AWSAppSyncCacheConfiguration?,
                 connectionStateChangeHandler: ConnectionStateChangeHandler?,
                 s3ObjectManager: AWSS3ObjectManager?,
                 presignedURLClient: AWSS3ObjectPresignedURLGenerator?,
                 retryStrategy: AWSAppSyncRetryStrategy = .exponential) throws {

        // Passthrough properties
        self.connectionStateChangeHandler = connectionStateChangeHandler
        self.cacheConfiguration = cacheConfiguration
        self.presignedURLClient = presignedURLClient
        self.s3ObjectManager = s3ObjectManager
        self.url = url
        self.authType = authType

        // Initialized objects
        self.store = AWSAppSyncClientConfiguration.makeApolloStore(for: cacheConfiguration?.queries)
        self.subscriptionMetadataCache = AWSAppSyncClientConfiguration
            .makeSubscriptionMetadataCache(for: cacheConfiguration?.subscriptionMetadataCache)

        self.networkTransport = try AWSAppSyncClientConfiguration.getNetworkTransport(
            url: url,
            urlSessionConfiguration: urlSessionConfiguration,
            authType: authType,
            region: serviceRegion,
            apiKey: apiKey,
            apiKeyAuthProvider: apiKeyAuthProvider,
            credentialsProvider: credentialsProvider,
            userPoolsAuthProvider: userPoolsAuthProvider,
            oidcAuthProvider: oidcAuthProvider,
            retryStrategy: retryStrategy
        )
        self.retryStrategy = retryStrategy
    }

    // MARK: - Initialization helpers

    /// Returns `true` if the auth providers not needed by `authType` are nil. Does not validate that the auth provider required
    /// by the `authType` are actually populated, since the provider may be subsequently initialized using a default config.
    ///
    /// - Parameters:
    ///   - authType: The AuthType for which to validate the provider list
    ///   - apiKeyAuthProvider: Should be `nil` unless `authType` is `.apiKey`
    ///   - credentialsProvider: Should be `nil` unless `authType` is `.awsIAM`
    ///   - oidcAuthProvider: Should be `nil` unless `authType` is `.oidcToken`
    ///   - userPoolsAuthProvider: Should be `nil` unless `authType` is `.amazonCognitoUserPools`
    /// - Returns: `true` if the auth providers not required for `authType` are all `nil`, `false` otherwise.
    private static func unusedAuthProvidersAreNil(for authType: AWSAppSyncAuthType,
                                                  apiKeyAuthProvider: AWSAPIKeyAuthProvider?,
                                                  credentialsProvider: AWSCredentialsProvider?,
                                                  oidcAuthProvider: AWSOIDCAuthProvider?,
                                                  userPoolsAuthProvider: AWSCognitoUserPoolsAuthProvider?) -> Bool {

        let unneededProviders: [Any?]

        switch authType {
        case .apiKey:
            unneededProviders = [credentialsProvider, userPoolsAuthProvider, oidcAuthProvider]
        case .amazonCognitoUserPools:
            unneededProviders = [apiKeyAuthProvider, credentialsProvider, oidcAuthProvider]
        case .awsIAM:
            unneededProviders = [apiKeyAuthProvider, oidcAuthProvider, userPoolsAuthProvider]
        case .oidcToken:
            unneededProviders = [apiKeyAuthProvider, credentialsProvider, userPoolsAuthProvider]
        }

        return unneededProviders.allSatisfy { $0 == nil }
    }

    /// Returns a AWSAppSyncHTTPNetworkTransport based on the authType
    ///
    /// - Parameters:
    ///   - url:
    ///   - urlSessionConfiguration:
    ///   - authType:
    ///   - region:
    ///   - apiKey:
    ///   - apiKeyAuthProvider:
    ///   - credentialsProvider:
    ///   - userPoolsAuthProvider:
    ///   - oidcAuthProvider:
    /// - Returns: An AWSAppSyncHTTPNetworkTransport
    /// - Throws: An AWSAppSyncClientConfigurationError if the required data is not present to construct a network transport for
    ///   the specified authType
    static private func getNetworkTransport(url: URL,
                                            urlSessionConfiguration: URLSessionConfiguration,
                                            authType: AWSAppSyncAuthType,
                                            region: AWSRegionType,
                                            apiKey: String?,
                                            apiKeyAuthProvider: AWSAPIKeyAuthProvider?,
                                            credentialsProvider: AWSCredentialsProvider?,
                                            userPoolsAuthProvider: AWSCognitoUserPoolsAuthProvider?,
                                            oidcAuthProvider: AWSOIDCAuthProvider?,
                                            retryStrategy: AWSAppSyncRetryStrategy) throws -> AWSAppSyncHTTPNetworkTransport {

        // Validate the incoming parameters are consistent with the intent expressed by `authType`
        let unusedProvidersAreNil = AWSAppSyncClientConfiguration.unusedAuthProvidersAreNil(
            for: authType,
            apiKeyAuthProvider: apiKeyAuthProvider,
            credentialsProvider: credentialsProvider,
            oidcAuthProvider: oidcAuthProvider,
            userPoolsAuthProvider: userPoolsAuthProvider
        )

        guard unusedProvidersAreNil else {
            throw AWSAppSyncClientConfigurationError.invalidAuthConfiguration("\(authType.rawValue) is selected in configuration but other providers are passed.")
        }

        let networkTransport: AWSAppSyncHTTPNetworkTransport

        switch authType {
        case .apiKey:
            networkTransport = try makeNetworkTransportForAPIKey(url: url,
                                                                 urlSessionConfiguration: urlSessionConfiguration,
                                                                 apiKey: apiKey,
                                                                 authProvider: apiKeyAuthProvider,
                                                                 retryStrategy: retryStrategy)

        case .awsIAM:
            networkTransport = makeNetworkTransportForIAM(url: url,
                                                          urlSessionConfiguration: urlSessionConfiguration,
                                                          region: region,
                                                          authProvider: credentialsProvider,
                                                          retryStrategy: retryStrategy)

        case .amazonCognitoUserPools:
            networkTransport = try makeNetworkTransportForCognitoUserPools(url: url,
                                                                           urlSessionConfiguration: urlSessionConfiguration,
                                                                           authProvider: userPoolsAuthProvider,
                                                                           retryStrategy: retryStrategy)

        case .oidcToken:
            networkTransport = try makeNetworkTransportForOIDC(url: url,
                                                               urlSessionConfiguration: urlSessionConfiguration,
                                                               authProvider: oidcAuthProvider,
                                                               retryStrategy: retryStrategy)
        }

        return networkTransport
    }

    /// Returns an AWSAppSyncHTTPNetworkTransport configured to use the provided auth provider
    ///
    /// - Parameters:
    ///   - url: The endpoint URL
    ///   - urlSessionConfiguration: The URLSessionConfiguration to use for network connections managed by the transport
    ///   - authProvider: The auth provider to use for authenticating network requests
    ///   - retryStrategy: The retry strategy specified in client configuration
    /// - Returns: The AWSAppSyncHTTPNetworkTransport
    /// - Throws: An AWSAppSyncClientConfigurationError if the auth provider is nil
    private static func makeNetworkTransportForAPIKey(url: URL,
                                                      urlSessionConfiguration: URLSessionConfiguration,
                                                      apiKey: String?,
                                                      authProvider: AWSAPIKeyAuthProvider?,
                                                      retryStrategy: AWSAppSyncRetryStrategy) throws -> AWSAppSyncHTTPNetworkTransport {
        let resolvedAPIKeyAuthProvider = try AWSAppSyncClientConfiguration.resolveAPIKeyAuthProvider(
            apiKeyAuthProvider: authProvider,
            apiKey: apiKey
        )
        let networkTransport = AWSAppSyncHTTPNetworkTransport(url: url,
                                                              apiKeyAuthProvider: resolvedAPIKeyAuthProvider,
                                                              configuration: urlSessionConfiguration,
                                                              retryStrategy: retryStrategy)
        return networkTransport
    }

    /// Returns an AWSAppSyncHTTPNetworkTransport configured to use the provided auth provider
    ///
    /// - Parameters:
    ///   - url: The endpoint URL
    ///   - urlSessionConfiguration: The URLSessionConfiguration to use for network connections managed by the transport
    ///   - region: The AWS region to which the auth provider is configured
    ///   - authProvider: The auth provider to use for authenticating network requests
    ///   - retryStrategy: The retry strategy specified in client configuration
    /// - Returns: The AWSAppSyncHTTPNetworkTransport
    /// - Throws: An AWSAppSyncClientConfigurationError if the auth provider is nil
    private static func makeNetworkTransportForIAM(url: URL,
                                                   urlSessionConfiguration: URLSessionConfiguration,
                                                   region: AWSRegionType,
                                                   authProvider: AWSCredentialsProvider?,
                                                   retryStrategy: AWSAppSyncRetryStrategy) -> AWSAppSyncHTTPNetworkTransport {
        let resolvedCredentialsProvider = authProvider ?? AWSServiceInfo().cognitoCredentialsProvider
        let networkTransport = AWSAppSyncHTTPNetworkTransport(url: url,
                                                              configuration: urlSessionConfiguration,
                                                              region: region,
                                                              credentialsProvider: resolvedCredentialsProvider,
                                                              retryStrategy: retryStrategy)
        return networkTransport
    }

    /// Returns an AWSAppSyncHTTPNetworkTransport configured to use the provided auth provider
    ///
    /// - Parameters:
    ///   - url: The endpoint URL
    ///   - urlSessionConfiguration: The URLSessionConfiguration to use for network connections managed by the transport
    ///   - authProvider: The auth provider to use for authenticating network requests
    ///   - retryStrategy: The retry strategy specified in client configuration
    /// - Returns: The AWSAppSyncHTTPNetworkTransport
    /// - Throws: An AWSAppSyncClientConfigurationError if the auth provider is nil
    private static func makeNetworkTransportForCognitoUserPools(url: URL,
                                                                urlSessionConfiguration: URLSessionConfiguration,
                                                                authProvider: AWSCognitoUserPoolsAuthProvider?,
                                                                retryStrategy: AWSAppSyncRetryStrategy) throws -> AWSAppSyncHTTPNetworkTransport {
        // No default OIDC provider available
        guard let authProvider = authProvider else {
            throw AWSAppSyncClientConfigurationError.invalidAuthConfiguration("AWSCognitoUserPoolsAuthProvider cannot be nil.")
        }
        let networkTransport = AWSAppSyncHTTPNetworkTransport(url: url,
                                                              userPoolsAuthProvider: authProvider,
                                                              configuration: urlSessionConfiguration,
                                                              retryStrategy: retryStrategy)
        return networkTransport
    }

    /// Returns an AWSAppSyncHTTPNetworkTransport configured to use the provided auth provider
    ///
    /// - Parameters:
    ///   - url: The endpoint URL
    ///   - urlSessionConfiguration: The URLSessionConfiguration to use for network connections managed by the transport
    ///   - authProvider: The auth provider to use for authenticating network requests
    ///   - retryStrategy: The retry strategy specified in client configuration
    /// - Returns: The AWSAppSyncHTTPNetworkTransport
    /// - Throws: An AWSAppSyncClientConfigurationError if the auth provider is nil
    private static func makeNetworkTransportForOIDC(url: URL,
                                                    urlSessionConfiguration: URLSessionConfiguration,
                                                    authProvider: AWSOIDCAuthProvider?,
                                                    retryStrategy: AWSAppSyncRetryStrategy) throws -> AWSAppSyncHTTPNetworkTransport {
        // No default OIDC provider available
        guard let authProvider = authProvider else {
            throw AWSAppSyncClientConfigurationError.invalidAuthConfiguration("AWSOIDCAuthProvider cannot be nil.")
        }
        let networkTransport = AWSAppSyncHTTPNetworkTransport(url: url,
                                                              oidcAuthProvider: authProvider,
                                                              configuration: urlSessionConfiguration,
                                                              retryStrategy: retryStrategy)
        return networkTransport
    }

    /// Given at least one non-nil parameter, resolves and returns an AWSAPIKeyAuthProvider to use for creating an
    /// AWSHTTPNetworkTransport. If `apiKeyAuthProvider` is not nil, returns that object. If it is nil, but `apiKey` is not nil,
    /// returns a new `BasicAWSAPIKeyAuthProvider`. If both arguments are nil, throws an error.
    ///
    /// - Parameters:
    ///   - apiKeyAuthProvider: The auth provider to return if not nil
    ///   - apiKey: An API key to use for creating a new `BasicAWSAPIKeyAuthProvider` if `apiKeyAuthProvider` is nil
    /// - Returns: An AWSAPIKeyAuthProvider
    /// - Throws: A AWSAppSyncClientConfigurationError if both arguments are nil
    private static func resolveAPIKeyAuthProvider(apiKeyAuthProvider: AWSAPIKeyAuthProvider?, apiKey: String?) throws -> AWSAPIKeyAuthProvider {
        if let apiKeyAuthProvider = apiKeyAuthProvider {
            return apiKeyAuthProvider
        }

        guard let apiKey = apiKey else {
            throw AWSAppSyncClientConfigurationError.invalidAuthConfiguration("apiKey cannot be nil")
        }

        let resolvedProvider = BasicAWSAPIKeyAuthProvider(key: apiKey)
        return resolvedProvider
    }

    /// Creates an Apollo store with a cache at `databaseURL`, or an in-memory cache if `databaseURL` is nil or if the normalized
    /// cache cannot be created
    ///
    /// - Parameter databaseURL: The file URL at which to store the cache database
    /// - Returns: The ApolloStore
    private static func makeApolloStore(for databaseURL: URL?) -> ApolloStore {
        let store: ApolloStore
        if let databaseURL = databaseURL, let cache = try? AWSSQLiteNormalizedCache(fileURL: databaseURL) {
            store = ApolloStore(cache: cache)
        } else {
            // Prepopulate the InMemoryNormalizedCache record set with an empty QUERY_ROOT, to allow optimistic
            // updates against empty caches to succeed. Otherwise, such an operation will fail with a "missingValue"
            // error (#92)
            let emptyQueryRootRecord = Record(key: AWSAppSyncClient.EmptyQuery.rootCacheKey, [:])
            let records = RecordSet(records: [emptyQueryRootRecord])
            let inMemoryCache = InMemoryNormalizedCache(records: records)
            store = ApolloStore(cache: inMemoryCache)
        }
        return store
    }

    /// Returns a reference to a AWSSubscriptionMetaDataCache stored at `databaseURL`, or nil if `databaseURL` is nil
    ///
    /// - Parameter databaseURL: The file URL at which to store the cache database
    /// - Returns: The AWSSubscriptionMetaDataCache, or nil if `databaseURL` is nil
    private static func makeSubscriptionMetadataCache(for databaseURL: URL?) -> AWSSubscriptionMetaDataCache? {
        let subscriptionMetadataCache: AWSSubscriptionMetaDataCache?
        if let databaseURL = databaseURL {
            subscriptionMetadataCache = try? AWSSubscriptionMetaDataCache(fileURL: databaseURL)
        } else {
            subscriptionMetadataCache = nil
        }
        return subscriptionMetadataCache
    }

}
