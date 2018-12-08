//
// Copyright 2010-2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

public class AWSAppSyncClientConfiguration {

    public let url: URL
    public let region: AWSRegionType
    public let store: ApolloStore
    public let networkTransport: AWSNetworkTransport
    public let databaseURL: URL?
    public let oidcAuthProvider: AWSOIDCAuthProvider?
    public let s3ObjectManager: AWSS3ObjectManager?
    public let presignedURLClient: AWSS3ObjectPresignedURLGenerator?
    public let connectionStateChangeHandler: ConnectionStateChangeHandler?

    let snapshotController: SnapshotProcessController?
    let subscriptionMetadataCache: AWSSubscriptionMetaDataCache?

    public let allowsCellularAccess: Bool = true
    public let autoSubmitOfflineMutations: Bool = true

    let authType: AppSyncAuthType?

    /// Creates a configuration object for the `AWSAppSyncClient`.
    ///
    /// - Parameters:
    ///   - url: The endpoint url for Appsync endpoint.
    ///   - serviceRegion: The service region for Appsync.
    ///   - credentialsProvider: A `AWSCredentialsProvider` object for AWS_IAM based authorization.
    ///   - urlSessionConfiguration: A `URLSessionConfiguration` configuration object for custom HTTP configuration.
    ///   - databaseURL: The path to local sqlite database for persistent storage, if nil, an in-memory database is used.
    ///   - connectionStateChangeHandler: The delegate object to be notified when client network state changes.
    ///   - s3ObjectManager: The client used for uploading / downloading `S3Objects`.
    ///   - presignedURLClient: The `AWSAppSyncClientConfiguration` object.
    ///   - loggingClient: The logging client for application logging.
    public convenience init(
        url: URL,
        serviceRegion: AWSRegionType,
        credentialsProvider: AWSCredentialsProvider,
        urlSessionConfiguration: URLSessionConfiguration = .default,
        databaseURL: URL? = nil,
        connectionStateChangeHandler: ConnectionStateChangeHandler? = nil,
        s3ObjectManager: AWSS3ObjectManager? = nil,
        presignedURLClient: AWSS3ObjectPresignedURLGenerator? = nil) throws {

        try self.init(
            url: url,
            serviceRegion: serviceRegion,
            authType: .awsIAM,
            apiKeyAuthProvider: nil,
            credentialsProvider: credentialsProvider,
            userPoolsAuthProvider: nil,
            oidcAuthProvider: nil,
            urlSessionConfiguration: urlSessionConfiguration,
            databaseURL: databaseURL,
            connectionStateChangeHandler: connectionStateChangeHandler,
            s3ObjectManager: s3ObjectManager,
            presignedURLClient: presignedURLClient)
    }

    /// Creates a configuration object for the `AWSAppSyncClient`.
    ///
    /// - Parameters:
    ///   - appSyncClientInfo: The configuration information represented in awsconfiguration.json file.
    ///   - apiKeyAuthProvider: A `AWSAPIKeyAuthProvider` protocol object for API Key based authorization.
    ///   - credentialsProvider: A `AWSCredentialsProvider` object for AWS_IAM based authorization.
    ///   - userPoolsAuthProvider: A `AWSCognitoUserPoolsAuthProvider` protocol object for User Pool based authorization.
    ///   - oidcAuthProvider: A `AWSOIDCAuthProvider` protocol object for OIDC based authorization.
    ///   - urlSessionConfiguration: A `URLSessionConfiguration` configuration object for custom HTTP configuration.
    ///   - databaseURL: The path to local sqlite database for persistent storage, if nil, an in-memory database is used.
    ///   - connectionStateChangeHandler: The delegate object to be notified when client network state changes.
    ///   - s3ObjectManager: The client used for uploading / downloading `S3Objects`.
    ///   - presignedURLClient: The `AWSAppSyncClientConfiguration` object.
    ///   - loggingClient: The logging client for application logging.
    public convenience init(
        appSyncClientInfo: AWSAppSyncClientInfo,
        apiKeyAuthProvider: AWSAPIKeyAuthProvider? = nil,
        credentialsProvider: AWSCredentialsProvider? = nil,
        userPoolsAuthProvider: AWSCognitoUserPoolsAuthProvider? = nil,
        oidcAuthProvider: AWSOIDCAuthProvider? = nil,
        urlSessionConfiguration: URLSessionConfiguration = .default,
        databaseURL: URL? = nil,
        connectionStateChangeHandler: ConnectionStateChangeHandler? = nil,
        s3ObjectManager: AWSS3ObjectManager? = nil,
        presignedURLClient: AWSS3ObjectPresignedURLGenerator? = nil) throws {

        var defaultApiKeyAuthProvider: AWSAPIKeyAuthProvider? = apiKeyAuthProvider
        var defaultCredentialsProvider: AWSCredentialsProvider? = credentialsProvider
        
        switch appSyncClientInfo.authType {
        case .apiKey:
            if credentialsProvider != nil || userPoolsAuthProvider != nil || oidcAuthProvider != nil {
                throw AWSAppSyncClientInfoError(
                    errorMessage: """
                    \(AppSyncAuthType.apiKey) is selected in configuration but
                    a AWSAPIKeyAuthProvider object is not passed in or cannot be constructed.
                    """)
            }

            guard let apiKey = appSyncClientInfo.apiKey else {
                throw AWSAppSyncClientInfoError(
                    errorMessage: "API_KEY AuthMode found in configuration but a valid ApiKey is not found")
            }

            // If AuthType is API_KEY, use the ApiKey Auth Provider passed in
            // or create a provider based on the ApiKey passed from the config
            if defaultApiKeyAuthProvider == nil {
                class BasicAWSAPIKeyAuthProvider: AWSAPIKeyAuthProvider {
                    var apiKey: String
                    public init(key: String) {
                        apiKey = key
                    }
                    func getAPIKey() -> String {
                        return apiKey
                    }
                }
                defaultApiKeyAuthProvider = BasicAWSAPIKeyAuthProvider(key: apiKey)
            }
        case .amazonCognitoUserPools:
            if credentialsProvider != nil || apiKeyAuthProvider != nil || oidcAuthProvider != nil {
                throw AWSAppSyncClientInfoError(
                    errorMessage: """
                    \(AppSyncAuthType.amazonCognitoUserPools) is selected in configuration but
                    AWSCognitoUserPoolsAuthProvider object is not passed in.
                    """)
            }

            if userPoolsAuthProvider == nil {
                throw AWSAppSyncClientInfoError(errorMessage: "userPoolsAuthProvider cannot be nil.")
            }
        case .awsIAM:
            if apiKeyAuthProvider != nil || userPoolsAuthProvider != nil || oidcAuthProvider != nil {
                throw AWSAppSyncClientInfoError(
                    errorMessage: """
                    \(AppSyncAuthType.awsIAM) is selected in configuration but
                    AWSCredentialsProvider object is not passed in or cannot be constructed.
                    """)
            }

            // If AuthType is AWS_IAM, use the AWSCredentialsProvider passed in
            // or create a provider based on the CognitoIdentity CredentialsProvider
            // passed from the config
            if defaultCredentialsProvider == nil {
                defaultCredentialsProvider = AWSServiceInfo().cognitoCredentialsProvider
                if defaultCredentialsProvider == nil {
                    throw AWSAppSyncClientInfoError(errorMessage: "CredentialsProvider is missing in the configuration.")
                }
            }
        case .oidcToken:
            if credentialsProvider != nil || userPoolsAuthProvider != nil || apiKeyAuthProvider != nil {
                throw AWSAppSyncClientInfoError(
                    errorMessage: """
                    \(AppSyncAuthType.oidcToken) is selected in configuration but
                    AWSOIDCAuthProvider object is not passed in.
                    """)
            }

            if oidcAuthProvider == nil {
                throw AWSAppSyncClientInfoError(errorMessage: "oidcAuthProvider cannot be nil.")
            }
        }

        try self.init(
            url: appSyncClientInfo.apiURL,
            serviceRegion: appSyncClientInfo.region,
            authType: appSyncClientInfo.authType,
            apiKeyAuthProvider: defaultApiKeyAuthProvider,
            credentialsProvider: defaultCredentialsProvider,
            userPoolsAuthProvider: userPoolsAuthProvider,
            oidcAuthProvider: oidcAuthProvider,
            urlSessionConfiguration: urlSessionConfiguration,
            databaseURL: databaseURL,
            connectionStateChangeHandler: connectionStateChangeHandler,
            s3ObjectManager: s3ObjectManager,
            presignedURLClient: presignedURLClient)
    }

    /// Creates a configuration object for the `AWSAppSyncClient`.
    ///
    /// - Parameters:
    ///   - url: The endpoint url for Appsync endpoint.
    ///   - serviceRegion: The service region for Appsync.
    ///   - apiKeyAuthProvider: A `AWSAPIKeyAuthProvider` protocol object for API Key based authorization.
    ///   - urlSessionConfiguration: A `URLSessionConfiguration` configuration object for custom HTTP configuration.
    ///   - databaseURL: The path to local sqlite database for persistent storage, if nil, an in-memory database is used.
    ///   - connectionStateChangeHandler: The delegate object to be notified when client network state changes.
    ///   - s3ObjectManager: The client used for uploading / downloading `S3Objects`.
    ///   - presignedURLClient: The `AWSAppSyncClientConfiguration` object.
    ///   - loggingClient: The logging client for application logging.
    public convenience init(
        url: URL,
        serviceRegion: AWSRegionType,
        apiKeyAuthProvider: AWSAPIKeyAuthProvider,
        urlSessionConfiguration: URLSessionConfiguration = .default,
        databaseURL: URL? = nil,
        connectionStateChangeHandler: ConnectionStateChangeHandler? = nil,
        s3ObjectManager: AWSS3ObjectManager? = nil,
        presignedURLClient: AWSS3ObjectPresignedURLGenerator? = nil) throws {
        try self.init(
            url: url,
            serviceRegion: serviceRegion,
            authType: AppSyncAuthType.apiKey,
            apiKeyAuthProvider: apiKeyAuthProvider,
            credentialsProvider: nil,
            userPoolsAuthProvider: nil,
            oidcAuthProvider: nil,
            urlSessionConfiguration: urlSessionConfiguration,
            databaseURL: databaseURL,
            connectionStateChangeHandler: connectionStateChangeHandler,
            s3ObjectManager: s3ObjectManager,
            presignedURLClient: presignedURLClient)
    }

    /// Creates a configuration object for the `AWSAppSyncClient`.
    ///
    /// - Parameters:
    ///   - url: The endpoint url for Appsync endpoint.
    ///   - serviceRegion: The service region for Appsync.
    ///   - userPoolsAuthProvider: A `AWSCognitoUserPoolsAuthProvider` protocol object for User Pool based authorization.
    ///   - urlSessionConfiguration: A `URLSessionConfiguration` configuration object for custom HTTP configuration.
    ///   - databaseURL: The path to local sqlite database for persistent storage, if nil, an in-memory database is used.
    ///   - connectionStateChangeHandler: The delegate object to be notified when client network state changes.
    ///   - s3ObjectManager: The client used for uploading / downloading `S3Objects`.
    ///   - presignedURLClient: The `AWSAppSyncClientConfiguration` object.
    ///   - loggingClient: The logging client for application logging.
    public convenience init(
        url: URL,
        serviceRegion: AWSRegionType,
        userPoolsAuthProvider: AWSCognitoUserPoolsAuthProvider,
        urlSessionConfiguration: URLSessionConfiguration = .default,
        databaseURL: URL? = nil,
        connectionStateChangeHandler: ConnectionStateChangeHandler? = nil,
        s3ObjectManager: AWSS3ObjectManager? = nil,
        presignedURLClient: AWSS3ObjectPresignedURLGenerator? = nil) throws {
        try self.init(
            url: url,
            serviceRegion: serviceRegion,
            authType: AppSyncAuthType.amazonCognitoUserPools,
            apiKeyAuthProvider: nil,
            credentialsProvider: nil,
            userPoolsAuthProvider: userPoolsAuthProvider,
            oidcAuthProvider: nil,
            urlSessionConfiguration: urlSessionConfiguration,
            databaseURL: databaseURL,
            connectionStateChangeHandler: connectionStateChangeHandler,
            s3ObjectManager: s3ObjectManager,
            presignedURLClient: presignedURLClient)
    }

    /// Creates a configuration object for the `AWSAppSyncClient`.
    ///
    /// - Parameters:
    ///   - url: The endpoint url for Appsync endpoint.
    ///   - serviceRegion: The service region for Appsync.
    ///   - oidcAuthProvider: A `AWSOIDCAuthProvider` protocol object for OIDC based authorization.
    ///   - urlSessionConfiguration: A `URLSessionConfiguration` configuration object for custom HTTP configuration.
    ///   - databaseURL: The path to local sqlite database for persistent storage, if nil, an in-memory database is used.
    ///   - connectionStateChangeHandler: The delegate object to be notified when client network state changes.
    ///   - s3ObjectManager: The client used for uploading / downloading `S3Objects`.
    ///   - presignedURLClient: The `AWSAppSyncClientConfiguration` object.
    ///   - loggingClient: The logging client for application logging.
    public convenience init(
        url: URL,
        serviceRegion: AWSRegionType,
        oidcAuthProvider: AWSOIDCAuthProvider,
        urlSessionConfiguration: URLSessionConfiguration = .default,
        databaseURL: URL? = nil,
        connectionStateChangeHandler: ConnectionStateChangeHandler? = nil,
        s3ObjectManager: AWSS3ObjectManager? = nil,
        presignedURLClient: AWSS3ObjectPresignedURLGenerator? = nil) throws {
        try self.init(
            url: url,
            serviceRegion: serviceRegion,
            authType: AppSyncAuthType.oidcToken,
            apiKeyAuthProvider: nil,
            credentialsProvider: nil,
            userPoolsAuthProvider: nil,
            oidcAuthProvider: oidcAuthProvider,
            urlSessionConfiguration: urlSessionConfiguration,
            databaseURL: databaseURL,
            connectionStateChangeHandler: connectionStateChangeHandler,
            s3ObjectManager: s3ObjectManager,
            presignedURLClient: presignedURLClient)
    }

    /// Creates a configuration object for the `AWSAppSyncClient`.
    ///
    /// - Parameters:
    ///   - url: The endpoint url for Appsync endpoint.
    ///   - serviceRegion: The service region for Appsync.
    ///   - networkTransport: The Network Transport used to communicate with the server.
    ///   - databaseURL: The path to local sqlite database for persistent storage, if nil, an in-memory database is used.
    ///   - connectionStateChangeHandler: The delegate object to be notified when client network state changes.
    ///   - s3ObjectManager: The client used for uploading / downloading `S3Objects`.
    ///   - presignedURLClient: The `AWSAppSyncClientConfiguration` object.
    ///   - loggingClient: The logging client for application logging.
    public init(
        url: URL,
        serviceRegion: AWSRegionType,
        networkTransport: AWSNetworkTransport,
        databaseURL: URL? = nil,
        connectionStateChangeHandler: ConnectionStateChangeHandler? = nil,
        s3ObjectManager: AWSS3ObjectManager? = nil,
        presignedURLClient: AWSS3ObjectPresignedURLGenerator? = nil) throws {
        self.url = url
        self.region = serviceRegion
        self.databaseURL = databaseURL
        self.networkTransport = networkTransport

        if let databaseURL = databaseURL {
            do {
                self.store = try ApolloStore(cache: AWSSQLLiteNormalizedCache(fileURL: databaseURL))
            } catch {
                self.store = ApolloStore(cache: InMemoryNormalizedCache())
            }

            do {
                self.subscriptionMetadataCache = try AWSSubscriptionMetaDataCache(fileURL: databaseURL)
            } catch {
                self.subscriptionMetadataCache = nil
            }
        } else {
            self.store = ApolloStore(cache: InMemoryNormalizedCache())
            self.subscriptionMetadataCache = nil
        }

        self.authType = nil
        self.oidcAuthProvider = nil
        self.s3ObjectManager = s3ObjectManager
        self.presignedURLClient = presignedURLClient
        self.connectionStateChangeHandler = connectionStateChangeHandler
        self.snapshotController = SnapshotProcessController(endpointURL: url)
    }

    /// Creates a configuration object for the `AWSAppSyncClient`.
    ///
    /// - Parameters:
    ///   - appSyncClientInfo: The configuration information represented in awsconfiguration.json file.
    ///   - networkTransport: The Network Transport used to communicate with the server.
    ///   - databaseURL: The path to local sqlite database for persistent storage, if nil, an in-memory database is used.
    ///   - connectionStateChangeHandler: The delegate object to be notified when client network state changes.
    ///   - s3ObjectManager: The client used for uploading / downloading `S3Objects`.
    ///   - presignedURLClient: The `AWSAppSyncClientConfiguration` object.
    ///   - loggingClient: The logging client for application logging.
    public init(
        appSyncClientInfo: AWSAppSyncClientInfo,
        networkTransport: AWSNetworkTransport,
        databaseURL: URL? = nil,
        connectionStateChangeHandler: ConnectionStateChangeHandler? = nil,
        s3ObjectManager: AWSS3ObjectManager? = nil,
        presignedURLClient: AWSS3ObjectPresignedURLGenerator? = nil) throws {
        self.url = appSyncClientInfo.apiURL
        self.region = appSyncClientInfo.region
        self.databaseURL = databaseURL
        self.networkTransport = networkTransport

        if let databaseURL = databaseURL {
            do {
                self.store = try ApolloStore(cache: AWSSQLLiteNormalizedCache(fileURL: databaseURL))
            } catch {
                self.store = ApolloStore(cache: InMemoryNormalizedCache())
            }
            do {
                self.subscriptionMetadataCache = try AWSSubscriptionMetaDataCache(fileURL: databaseURL)
            } catch {
                self.subscriptionMetadataCache = nil
            }
        } else {
            self.store = ApolloStore(cache: InMemoryNormalizedCache())
            self.subscriptionMetadataCache = nil
        }

        self.authType = nil
        self.oidcAuthProvider = nil
        self.s3ObjectManager = s3ObjectManager
        self.presignedURLClient = presignedURLClient
        self.connectionStateChangeHandler = connectionStateChangeHandler
        self.snapshotController = SnapshotProcessController(endpointURL: url)
    }
    
    /// Creates a configuration object for the `AWSAppSyncClient`.
    ///
    /// - Parameters:
    ///   - url: The endpoint url for AppSync endpoint.
    ///   - serviceRegion: The service region for AppSync.
    ///   - authType: The Mode of Authentication used with AppSync
    ///   - apiKeyAuthProvider: A `AWSAPIKeyAuthProvider` protocol object for API Key based authorization.
    ///   - credentialsProvider: A `AWSCredentialsProvider` object for AWS_IAM based authorization.
    ///   - userPoolsAuthProvider: A `AWSCognitoUserPoolsAuthProvider` protocol object for Cognito User Pools based authorization.
    ///   - oidcAuthProvider: A `AWSOIDCAuthProvider` protocol object for any OpenId Connect based authorization.
    ///   - urlSessionConfiguration: A `URLSessionConfiguration` configuration object for custom HTTP configuration.
    ///   - databaseURL: The path to local sqlite database for persistent storage, if nil, an in-memory database is used.
    ///   - connectionStateChangeHandler: The delegate object to be notified when client network state changes.
    ///   - s3ObjectManager: The client used for uploading / downloading `S3Objects`.
    ///   - presignedURLClient: The `AWSAppSyncClientConfiguration` object.
    private init(
        url: URL,
        serviceRegion: AWSRegionType,
        authType: AppSyncAuthType,
        apiKeyAuthProvider: AWSAPIKeyAuthProvider? = nil,
        credentialsProvider: AWSCredentialsProvider? = nil,
        userPoolsAuthProvider: AWSCognitoUserPoolsAuthProvider? = nil,
        oidcAuthProvider: AWSOIDCAuthProvider? = nil,
        urlSessionConfiguration: URLSessionConfiguration = .default,
        databaseURL: URL? = nil,
        connectionStateChangeHandler: ConnectionStateChangeHandler? = nil,
        s3ObjectManager: AWSS3ObjectManager? = nil,
        presignedURLClient: AWSS3ObjectPresignedURLGenerator? = nil) throws {
        self.url = url
        self.region = serviceRegion
        self.authType = authType

        // Construct the Network Transport based on the authType selected
        switch authType {
        case .apiKey:
            self.networkTransport = AWSAppSyncHTTPNetworkTransport(
                url: url,
                apiKeyAuthProvider: apiKeyAuthProvider!,
                configuration: urlSessionConfiguration)
        case .awsIAM:
            self.networkTransport = AWSAppSyncHTTPNetworkTransport(
                url: url,
                configuration: urlSessionConfiguration,
                region: region,
                credentialsProvider: credentialsProvider!)
        case .amazonCognitoUserPools:
            self.networkTransport = AWSAppSyncHTTPNetworkTransport(
                url: url,
                userPoolsAuthProvider: userPoolsAuthProvider!,
                configuration: urlSessionConfiguration)
        case .oidcToken:
            self.networkTransport = AWSAppSyncHTTPNetworkTransport(
                url: url,
                oidcAuthProvider: oidcAuthProvider!,
                configuration: urlSessionConfiguration)
        }

        self.databaseURL = databaseURL
        self.connectionStateChangeHandler = connectionStateChangeHandler

        if let databaseURL = databaseURL {
            do {
                self.store = try ApolloStore(cache: AWSSQLLiteNormalizedCache(fileURL: databaseURL))
            } catch {
                self.store = ApolloStore(cache: InMemoryNormalizedCache())
            }
            do {
                self.subscriptionMetadataCache = try AWSSubscriptionMetaDataCache(fileURL: databaseURL)
            } catch {
                self.subscriptionMetadataCache = nil
            }
        } else {
            self.store = ApolloStore(cache: InMemoryNormalizedCache())
            self.subscriptionMetadataCache = nil
        }

        self.oidcAuthProvider = nil
        self.snapshotController = SnapshotProcessController(endpointURL: url)
        self.s3ObjectManager = s3ObjectManager
        self.presignedURLClient = presignedURLClient
    }
}
