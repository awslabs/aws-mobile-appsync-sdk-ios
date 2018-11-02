//
//  AWSAppSyncClient.swift
//  AWSAppSyncClient
//

import Foundation
import AWSCore
import Reachability

public enum ClientNetworkAccessState {
    case Online
    case Offline
}

public protocol ConnectionStateChangeHandler {
    func stateChanged(networkState: ClientNetworkAccessState)
}

public typealias SubscriptionResultHandler<Operation: GraphQLSubscription> = (_ result: GraphQLResult<Operation.Data>?, _ transaction: ApolloStore.ReadWriteTransaction?, _ error: Error?) -> Void

public typealias OptimisticResponseBlock = (ApolloStore.ReadWriteTransaction?) -> Void

public typealias MutationConflictHandler<Mutation: GraphQLMutation> = (_ serverState: Snapshot?, _ taskCompletionSource: AWSTaskCompletionSource<Mutation>?, _ resultHandler: OperationResultHandler<Mutation>?) -> Void

enum AWSAppSyncGraphQLOperation {
    case mutation
    case query
    case subscription
}

class SnapshotProcessController {
    let endpointURL: URL
    var reachability: Reachability?
    private var networkStatusWatchers: [NetworkConnectionNotification] = []
    let allowsCellularAccess: Bool
    
    init(endpointURL: URL, allowsCellularAccess: Bool = true) {
        self.endpointURL = endpointURL
        self.allowsCellularAccess = allowsCellularAccess
        reachability = Reachability(hostname: endpointURL.host!)
        reachability?.allowsCellularConnection = allowsCellularAccess
        NotificationCenter.default.addObserver(self, selector: #selector(checkForReachability(note:)), name: .reachabilityChanged, object: reachability)
        do {
            try reachability?.startNotifier()
        } catch {
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(SnapshotProcessController.checkForReachability), name: NSNotification.Name(rawValue: kAWSDefaultNetworkReachabilityChangedNotification), object: nil)
    }
    
    @objc func checkForReachability(note: Notification) {
        
        let reachability = note.object as! Reachability
        var isReachable = true
        switch reachability.connection {
        case .none:
            isReachable = false
            break
        default:
            break
        }
        
        for watchers in networkStatusWatchers {
            watchers.onNetworkAvailabilityStatusChanged(isEndpointReachable: isReachable)
        }
    }
    
    func shouldExecuteOperation(operation: AWSAppSyncGraphQLOperation) -> Bool {
        switch operation {
        case .mutation:
            if !(reachability?.connection.description == "No Connection") {
                return true
            } else {
                return false
            }
        case .query:
            return true
        case .subscription:
            return true
        }
    }
}

public class AWSAppSyncClientConfiguration {
    
    fileprivate var url: URL
    fileprivate var region: AWSRegionType
    fileprivate var store: ApolloStore
    fileprivate var networkTransport: AWSNetworkTransport
    fileprivate var databaseURL: URL?
    fileprivate var oidcAuthProvider: AWSOIDCAuthProvider? = nil
    fileprivate var snapshotController: SnapshotProcessController? = nil
    fileprivate var s3ObjectManager: AWSS3ObjectManager? = nil
    fileprivate var presignedURLClient: AWSS3ObjectPresignedURLGenerator? = nil
    fileprivate var connectionStateChangeHandler: ConnectionStateChangeHandler? = nil
    
    fileprivate var allowsCellularAccess: Bool = true
    fileprivate var autoSubmitOfflineMutations: Bool = true
    
    fileprivate var authType: AuthType? = nil
    
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
    public convenience init(url: URL,
                            serviceRegion: AWSRegionType,
                            credentialsProvider: AWSCredentialsProvider,
                            urlSessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default,
                            databaseURL: URL? = nil,
                            connectionStateChangeHandler: ConnectionStateChangeHandler? = nil,
                            s3ObjectManager: AWSS3ObjectManager? = nil,
                            presignedURLClient: AWSS3ObjectPresignedURLGenerator? = nil) throws {
        try self.init(url: url,
                      serviceRegion: serviceRegion,
                      authType: AuthType.awsIAM,
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
    public convenience init(appSyncClientInfo: AWSAppSyncClientInfo,
                            apiKeyAuthProvider: AWSAPIKeyAuthProvider? = nil,
                            credentialsProvider: AWSCredentialsProvider? = nil,
                            userPoolsAuthProvider: AWSCognitoUserPoolsAuthProvider? = nil,
                            oidcAuthProvider: AWSOIDCAuthProvider? = nil,
                            urlSessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default,
                            databaseURL: URL? = nil,
                            connectionStateChangeHandler: ConnectionStateChangeHandler? = nil,
                            s3ObjectManager: AWSS3ObjectManager? = nil,
                            presignedURLClient: AWSS3ObjectPresignedURLGenerator? = nil) throws {
        
        let authTypeFromConfig: AuthType = try AuthType.getAuthType(rawValue: appSyncClientInfo.authType)
        
        var defaultApiKeyAuthProvider: AWSAPIKeyAuthProvider? = apiKeyAuthProvider
        var defaultCredentialsProvider: AWSCredentialsProvider? = credentialsProvider
        
        switch (authTypeFromConfig) {
        case AuthType.apiKey:
            if credentialsProvider != nil || userPoolsAuthProvider != nil || oidcAuthProvider != nil {
                throw AWSAppSyncClientInfoError(errorMessage: AuthType.apiKey.rawValue + " is selected in configuration but a "
                    + "AWSAPIKeyAuthProvider object is not passed in or cannot be constructed.")
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
                defaultApiKeyAuthProvider = BasicAWSAPIKeyAuthProvider(key: appSyncClientInfo.apiKey)
            }
            break
        case AuthType.amazonCognitoUserPools:
            if credentialsProvider != nil || apiKeyAuthProvider != nil || oidcAuthProvider != nil {
                throw AWSAppSyncClientInfoError(errorMessage: AuthType.amazonCognitoUserPools.rawValue + " is selected in configuration but a "
                    + "AWSCognitoUserPoolsAuthProvider object is not passed in.")
            }
            
            if userPoolsAuthProvider == nil {
                throw AWSAppSyncClientInfoError(errorMessage: "userPoolsAuthProvider cannot be nil.")
            }
            break
        case AuthType.awsIAM:
            if apiKeyAuthProvider != nil || userPoolsAuthProvider != nil || oidcAuthProvider != nil {
                throw AWSAppSyncClientInfoError(errorMessage: AuthType.awsIAM.rawValue + " is selected in configuration but a "
                    + "AWSCredentialsProvider object is not passed in or cannot be constructed.")
            }
            
            // If AuthType is AWS_IAM, use the AWSCredentialsProvider passed in
            // or create a provider based on the CognitoIdentity CredentialsProvider
            // passed from the config
            if defaultCredentialsProvider == nil {
                defaultCredentialsProvider = AWSServiceInfo.init().cognitoCredentialsProvider
                if defaultCredentialsProvider == nil {
                    throw AWSAppSyncClientInfoError(errorMessage: "CredentialsProvider is missing in the configuration.")
                }
            }
            break
        case AuthType.oidcToken:
            if credentialsProvider != nil || userPoolsAuthProvider != nil || apiKeyAuthProvider != nil {
                throw AWSAppSyncClientInfoError(errorMessage: AuthType.oidcToken.rawValue + " is selected in configuration but a "
                    + "AWSOIDCAuthProvider object is not passed in.")
            }
            
            if oidcAuthProvider == nil {
                throw AWSAppSyncClientInfoError(errorMessage: "oidcAuthProvider cannot be nil.")
            }
            break
        }
        
        try self.init(url: URL(string: appSyncClientInfo.apiUrl)!,
                      serviceRegion: appSyncClientInfo.region.aws_regionTypeValue(),
                      authType: authTypeFromConfig,
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
    public convenience init(url: URL,
                            serviceRegion: AWSRegionType,
                            apiKeyAuthProvider: AWSAPIKeyAuthProvider,
                            urlSessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default,
                            databaseURL: URL? = nil,
                            connectionStateChangeHandler: ConnectionStateChangeHandler? = nil,
                            s3ObjectManager: AWSS3ObjectManager? = nil,
                            presignedURLClient: AWSS3ObjectPresignedURLGenerator? = nil) throws {
        try self.init(url: url,
                      serviceRegion: serviceRegion,
                      authType: AuthType.apiKey,
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
    public convenience init(url: URL,
                            serviceRegion: AWSRegionType,
                            userPoolsAuthProvider: AWSCognitoUserPoolsAuthProvider,
                            urlSessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default,
                            databaseURL: URL? = nil,
                            connectionStateChangeHandler: ConnectionStateChangeHandler? = nil,
                            s3ObjectManager: AWSS3ObjectManager? = nil,
                            presignedURLClient: AWSS3ObjectPresignedURLGenerator? = nil) throws {
        try self.init(url: url,
                      serviceRegion: serviceRegion,
                      authType: AuthType.amazonCognitoUserPools,
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
    public convenience init(url: URL,
                            serviceRegion: AWSRegionType,
                            oidcAuthProvider: AWSOIDCAuthProvider,
                            urlSessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default,
                            databaseURL: URL? = nil,
                            connectionStateChangeHandler: ConnectionStateChangeHandler? = nil,
                            s3ObjectManager: AWSS3ObjectManager? = nil,
                            presignedURLClient: AWSS3ObjectPresignedURLGenerator? = nil) throws {
        try self.init(url: url,
                      serviceRegion: serviceRegion,
                      authType: AuthType.oidcToken,
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
    public init(url: URL,
                serviceRegion: AWSRegionType,
                networkTransport: AWSNetworkTransport,
                databaseURL: URL? = nil,
                connectionStateChangeHandler: ConnectionStateChangeHandler? = nil,
                s3ObjectManager: AWSS3ObjectManager? = nil,
                presignedURLClient: AWSS3ObjectPresignedURLGenerator? = nil) throws {
        self.url = url
        self.region = serviceRegion
        self.databaseURL = databaseURL
        self.store = ApolloStore(cache: InMemoryNormalizedCache())
        self.networkTransport = networkTransport
        if let databaseURL = databaseURL {
            do {
                self.store = try ApolloStore(cache: AWSSQLLiteNormalizedCache(fileURL: databaseURL))
            } catch {
                // Use in memory cache incase database init fails
            }
        }
        self.s3ObjectManager = s3ObjectManager
        self.presignedURLClient = presignedURLClient
        self.connectionStateChangeHandler = connectionStateChangeHandler
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
    public init(appSyncClientInfo: AWSAppSyncClientInfo,
                networkTransport: AWSNetworkTransport,
                databaseURL: URL? = nil,
                connectionStateChangeHandler: ConnectionStateChangeHandler? = nil,
                s3ObjectManager: AWSS3ObjectManager? = nil,
                presignedURLClient: AWSS3ObjectPresignedURLGenerator? = nil) throws {
        self.url = URL(string: appSyncClientInfo.apiUrl)!
        self.region = appSyncClientInfo.region.aws_regionTypeValue()
        self.databaseURL = databaseURL
        self.store = ApolloStore(cache: InMemoryNormalizedCache())
        self.networkTransport = networkTransport
        if let databaseURL = databaseURL {
            do {
                self.store = try ApolloStore(cache: AWSSQLLiteNormalizedCache(fileURL: databaseURL))
            } catch {
                // Use in memory cache incase database init fails
            }
        }
        self.s3ObjectManager = s3ObjectManager
        self.presignedURLClient = presignedURLClient
        self.connectionStateChangeHandler = connectionStateChangeHandler
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
    private init(url: URL,
                 serviceRegion: AWSRegionType,
                 authType: AuthType,
                 apiKeyAuthProvider: AWSAPIKeyAuthProvider? = nil,
                 credentialsProvider: AWSCredentialsProvider? = nil,
                 userPoolsAuthProvider: AWSCognitoUserPoolsAuthProvider? = nil,
                 oidcAuthProvider: AWSOIDCAuthProvider? = nil,
                 urlSessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default,
                 databaseURL: URL? = nil,
                 connectionStateChangeHandler: ConnectionStateChangeHandler? = nil,
                 s3ObjectManager: AWSS3ObjectManager? = nil,
                 presignedURLClient: AWSS3ObjectPresignedURLGenerator? = nil) throws {
        self.url = url
        self.region = serviceRegion
        self.authType = authType
        
        // Construct the Network Transport based on the authType selected
        switch (authType) {
        case AuthType.apiKey:
            self.networkTransport = AWSAppSyncHTTPNetworkTransport(url: url,
                                                                   apiKeyAuthProvider: apiKeyAuthProvider!,
                                                                   configuration: urlSessionConfiguration)
        case AuthType.awsIAM:
            self.networkTransport = AWSAppSyncHTTPNetworkTransport(url: url,
                                                                   configuration: urlSessionConfiguration,
                                                                   region: region,
                                                                   credentialsProvider: credentialsProvider!)
        case AuthType.amazonCognitoUserPools:
            self.networkTransport = AWSAppSyncHTTPNetworkTransport(url: url,
                                                                   userPoolsAuthProvider: userPoolsAuthProvider!,
                                                                   configuration: urlSessionConfiguration)
        case AuthType.oidcToken:
            self.networkTransport = AWSAppSyncHTTPNetworkTransport(url: url,
                                                                   oidcAuthProvider: oidcAuthProvider!,
                                                                   configuration: urlSessionConfiguration)
        }
        
        self.databaseURL = databaseURL
        self.store = ApolloStore(cache: InMemoryNormalizedCache())
        self.connectionStateChangeHandler = connectionStateChangeHandler
        if let databaseURL = databaseURL {
            do {
                self.store = try ApolloStore(cache: AWSSQLLiteNormalizedCache(fileURL: databaseURL))
            } catch {
                // Use in memory cache (InMemoryNormalizedCache) incase database init fails
            }
        }
        
        self.snapshotController = SnapshotProcessController(endpointURL: url)
        self.s3ObjectManager = s3ObjectManager
        self.presignedURLClient = presignedURLClient
    }
}

/**
 * Configuration for AWSAppSyncClient
 */
public class AWSAppSyncClientInfo {
    
    fileprivate var apiUrl: String = ""
    fileprivate var region: String = ""
    fileprivate var authType: String = ""
    fileprivate var apiKey: String = ""
    
    public convenience init() throws {
        try self.init(forKey: "Default")
    }
    
    public init(forKey: String) throws {
        do {
            if AWSInfo.default().rootInfoDictionary["AppSync"] == nil {
                throw AWSAppSyncClientInfoError(errorMessage: "Cannot read configuration from the awsconfiguration.json")
            }
            
            let appSyncConfig : [String : Any] = (AWSInfo.default().rootInfoDictionary["AppSync"] as? [String : Any])!
            let defaultAppSyncConfig : [String : Any] = (appSyncConfig[forKey] as? [String : Any])!
            self.apiUrl = defaultAppSyncConfig["ApiUrl"] as! String
            self.region = defaultAppSyncConfig["Region"] as! String
            self.authType = defaultAppSyncConfig["AuthMode"] as! String
            
            if let apiKeyFromDictionary = defaultAppSyncConfig["ApiKey"] {
                self.apiKey = apiKeyFromDictionary as! String
            } else {
                if (self.authType == AuthType.apiKey.rawValue) {
                    throw AWSAppSyncClientInfoError(errorMessage: "API_KEY AuthMode found in configuration but a valid ApiKey is not found")
                }
            }
        } catch {
            throw AWSAppSyncClientInfoError(errorMessage: "Error in reading AppSync configuration from the awsconfiguration.json")
        }
    }
}

public struct AWSAppSyncClientInfoError: Error, LocalizedError {
    
    public let errorMessage: String?
    
    public var errorDescription: String? {
        return errorMessage
    }
}

public struct AWSAppSyncClientError: Error, LocalizedError {
    
    /// The body of the response.
    public let body: Data?
    /// Information about the response as provided by the server.
    public let response: HTTPURLResponse?
    let isInternalError: Bool
    let additionalInfo: String?
    
    public var errorDescription: String? {
        if (isInternalError) {
            return additionalInfo
        }
        return "(\(response!.statusCode) \(response!.statusCodeDescription)) \(additionalInfo ?? "")"
    }
}

public struct AWSAppSyncSubscriptionError: Error, LocalizedError {
    let additionalInfo: String?
    let errorDetails: [String:String]?
    
    public var errorDescription: String? {
        return additionalInfo ?? "Unable to start subscription."
    }
    
    public var recoverySuggestion: String? {
        return errorDetails?["recoverySuggestion"]
    }
    
    public var failureReason: String? {
        return errorDetails?["failureReason"]
    }
}

protocol NetworkConnectionNotification {
    func onNetworkAvailabilityStatusChanged(isEndpointReachable: Bool)
}

public protocol AWSAppSyncOfflineMutationDelegate {
    func mutationCallback(recordIdentifier: String, operationString: String, snapshot: Snapshot?, error: Error?) -> Void
}

// The client for making `Mutation`, `Query` and `Subscription` requests.
public class AWSAppSyncClient: NetworkConnectionNotification {
    
    public let apolloClient: ApolloClient?
    public var offlineMutationDelegate: AWSAppSyncOfflineMutationDelegate?
    public let store: ApolloStore?
    public let presignedURLClient: AWSS3ObjectPresignedURLGenerator?
    public let s3ObjectManager: AWSS3ObjectManager?
    
    var reachability: Reachability?
    
    private var networkStatusWatchers: [NetworkConnectionNotification] = []
    private var appSyncConfiguration: AWSAppSyncClientConfiguration
    internal var httpTransport: AWSNetworkTransport?
    private var offlineMuationCacheClient : AWSAppSyncOfflineMutationCache?
    private var offlineMutationExecutor: MutationExecutor?
    private var autoSubmitOfflineMutations: Bool = false
    private var appSyncMQTTClient = AppSyncMQTTClient()
    private var subscriptionsQueue = DispatchQueue(label: "SubscriptionsQueue", qos: .userInitiated)
    
    internal var connectionStateChangeHandler: ConnectionStateChangeHandler?
    
    /// Creates a client with the specified `AWSAppSyncClientConfiguration`.
    ///
    /// - Parameters:
    ///   - appSyncConfig: The `AWSAppSyncClientConfiguration` object.
    public init(appSyncConfig: AWSAppSyncClientConfiguration) throws {
        self.appSyncConfiguration = appSyncConfig
        
        reachability = Reachability(hostname: self.appSyncConfiguration.url.host!)
        self.autoSubmitOfflineMutations = self.appSyncConfiguration.autoSubmitOfflineMutations
        self.store = appSyncConfig.store
        self.appSyncMQTTClient.allowCellularAccess = self.appSyncConfiguration.allowsCellularAccess
        self.presignedURLClient = appSyncConfig.presignedURLClient
        self.s3ObjectManager = appSyncConfig.s3ObjectManager
        
        self.httpTransport = appSyncConfig.networkTransport
        self.connectionStateChangeHandler = appSyncConfiguration.connectionStateChangeHandler
        
        self.apolloClient = ApolloClient(networkTransport: self.httpTransport!, store: self.appSyncConfiguration.store)
        
        try self.offlineMuationCacheClient = AWSAppSyncOfflineMutationCache()
        if let fileURL = self.appSyncConfiguration.databaseURL {
            do {
                self.offlineMuationCacheClient = try AWSAppSyncOfflineMutationCache(fileURL: fileURL)
            } catch {
                // continue using in memory cache client
            }
        }
        
        self.offlineMutationExecutor = MutationExecutor(networkClient: self.httpTransport!, appSyncClient: self, snapshotProcessController: SnapshotProcessController(endpointURL:self.appSyncConfiguration.url), fileURL: self.appSyncConfiguration.databaseURL)
        networkStatusWatchers.append(self.offlineMutationExecutor!)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(checkForReachability(note:)), name: .reachabilityChanged, object: reachability)
        do{
            try reachability?.startNotifier()
        } catch {
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(AWSAppSyncClient.checkForReachability), name: NSNotification.Name(rawValue: kAWSDefaultNetworkReachabilityChangedNotification), object: nil)
        
    }
    
    @objc func checkForReachability(note: Notification) {
        
        let reachability = note.object as! Reachability
        var isReachable = false
        
        switch reachability.connection {
        case .wifi:
            isReachable = true
        case .cellular:
            if (self.appSyncConfiguration.allowsCellularAccess) {
                isReachable = true
            }
        case .none:
            print("")
        }
        
        for watchers in networkStatusWatchers {
            watchers.onNetworkAvailabilityStatusChanged(isEndpointReachable: isReachable)
        }
        self.onNetworkAvailabilityStatusChanged(isEndpointReachable: isReachable)
    }
    
    /// Fetches a query from the server or from the local cache, depending on the current contents of the cache and the specified cache policy.
    ///
    /// - Parameters:
    ///   - query: The query to fetch.
    ///   - cachePolicy: A cache policy that specifies when results should be fetched from the server and when data should be loaded from the local cache.
    ///   - queue: A dispatch queue on which the result handler will be called. Defaults to the main queue.
    ///   - resultHandler: An optional closure that is called when query results are available or when an error occurs.
    ///   - result: The result of the fetched query, or `nil` if an error occurred.
    ///   - error: An error that indicates why the fetch failed, or `nil` if the fetch was succesful.
    /// - Returns: An object that can be used to cancel an in progress fetch.
    @discardableResult public func fetch<Query: GraphQLQuery>(query: Query, cachePolicy: CachePolicy = .returnCacheDataElseFetch, queue: DispatchQueue = DispatchQueue.main, resultHandler: OperationResultHandler<Query>? = nil) -> Cancellable {
        return apolloClient!.fetch(query: query, cachePolicy: cachePolicy, queue: queue, resultHandler: resultHandler)
    }
    
    /// Watches a query by first fetching an initial result from the server or from the local cache, depending on the current contents of the cache and the specified cache policy. After the initial fetch, the returned query watcher object will get notified whenever any of the data the query result depends on changes in the local cache, and calls the result handler again with the new result.
    ///
    /// - Parameters:
    ///   - query: The query to fetch.
    ///   - cachePolicy: A cache policy that specifies when results should be fetched from the server or from the local cache.
    ///   - queue: A dispatch queue on which the result handler will be called. Defaults to the main queue.
    ///   - resultHandler: An optional closure that is called when query results are available or when an error occurs.
    ///   - result: The result of the fetched query, or `nil` if an error occurred.
    ///   - error: An error that indicates why the fetch failed, or `nil` if the fetch was succesful.
    /// - Returns: A query watcher object that can be used to control the watching behavior.
    public func watch<Query: GraphQLQuery>(query: Query, cachePolicy: CachePolicy = .returnCacheDataElseFetch, queue: DispatchQueue = DispatchQueue.main, resultHandler: @escaping OperationResultHandler<Query>) -> GraphQLQueryWatcher<Query> {
        
        return apolloClient!.watch(query: query, cachePolicy: cachePolicy, queue: queue, resultHandler: resultHandler)
    }
    
    public func subscribe<Subscription: GraphQLSubscription>(subscription: Subscription, queue: DispatchQueue = DispatchQueue.main, resultHandler: @escaping SubscriptionResultHandler<Subscription>) throws -> AWSAppSyncSubscriptionWatcher<Subscription>? {
        
        return AWSAppSyncSubscriptionWatcher(client: self.appSyncMQTTClient,
                                              httpClient: self.httpTransport!,
                                              store: self.store!,
                                              subscriptionsQueue: self.subscriptionsQueue,
                                              subscription: subscription,
                                              handlerQueue: queue,
                                              resultHandler: resultHandler)
    }
    
    /// Performs a mutation by sending it to the server.
    ///
    /// - Parameters:
    ///   - mutation: The mutation to perform.
    ///   - queue: A dispatch queue on which the result handler will be called. Defaults to the main queue.
    ///   - optimisticUpdate: An optional closure which gets executed before making the network call, should be used to update local store using the `transaction` object.
    ///   - conflictResolutionBlock: An optional closure that is called when mutation results into a conflict.
    ///   - resultHandler: An optional closure that is called when mutation results are available or when an error occurs.
    ///   - result: The result of the performed mutation, or `nil` if an error occurred.
    ///   - error: An error that indicates why the mutation failed, or `nil` if the mutation was succesful.
    /// - Returns: An object that can be used to cancel an in progress mutation.
    @discardableResult public func perform<Mutation: GraphQLMutation>(mutation: Mutation,
                                                                      queue: DispatchQueue = DispatchQueue.main,
                                                                      optimisticUpdate: OptimisticResponseBlock? = nil,
                                                                      conflictResolutionBlock: MutationConflictHandler<Mutation>? = nil,
                                                                      resultHandler: OperationResultHandler<Mutation>? = nil) -> PerformMutationOperation<Mutation>? {
        if let optimisticUpdate = optimisticUpdate {
            do {
                let _ = try self.store?.withinReadWriteTransaction { transaction in
                    optimisticUpdate(transaction)
                    }.await()
            } catch {
            }
        }
        
        let taskCompletionSource = AWSTaskCompletionSource<Mutation>()
        taskCompletionSource.task.continueWith(block: { (task) -> Any? in
            _ = task.result
            return nil
        })
        
        let serializationFormat = JSONSerializationFormat.self
        let bodyRequest = requestBody(for: mutation)
        let data = try! serializationFormat.serialize(value: bodyRequest)
        let record = AWSAppSyncMutationRecord()
        if let s3Object = self.checkAndFetchS3Object(variables: mutation.variables) {
            record.type = .graphQLMutationWithS3Object
            record.s3ObjectInput =  InternalS3ObjectDetails(bucket: s3Object.bucket,
                                                            key: s3Object.key,
                                                            region: s3Object.region,
                                                            contentType: s3Object.contentType,
                                                            localUri: s3Object.localUri)
        }
        record.data = data
        record.contentMap = mutation.variables
        record.jsonRecord = mutation.variables?.jsonObject
        record.recordState = .inQueue
        record.operationString = Mutation.operationString
        
        return PerformMutationOperation(offlineMutationRecord: record, client: self.apolloClient!, appSyncClient: self, offlineExecutor: self.offlineMutationExecutor!, mutation: mutation, handlerQueue: queue, mutationConflictHandler: conflictResolutionBlock, resultHandler: resultHandler)
    }
    
    private func checkAndFetchS3Object(variables:GraphQLMap?) -> (bucket: String, key: String, region: String, contentType: String, localUri: String)? {
        if let variables = variables {
            for key in variables.keys {
                if let object = variables[key].jsonValue as? Dictionary<String, String> {
                    guard let bucket = object["bucket"] else { return nil }
                    guard let key = object["key"] else { return nil }
                    guard let region = object["region"] else { return nil }
                    guard let contentType = object["mimeType"] else { return nil }
                    guard let localUri = object["localUri"] else { return nil }
                    return (bucket, key, region, contentType, localUri)
                }
            }
        }
        return nil
    }
    
    func onNetworkAvailabilityStatusChanged(isEndpointReachable: Bool) {
        var accessState: ClientNetworkAccessState = .Offline
        if (isEndpointReachable) {
            accessState = .Online
        }
        self.connectionStateChangeHandler?.stateChanged(networkState: accessState)
    }
    
    private func requestBody<Operation: GraphQLOperation>(for operation: Operation) -> GraphQLMap {
        return ["query": type(of: operation).requestString, "variables": operation.variables]
    }
}

protocol InMemoryMutationDelegate {
    func performMutation(dispatchGroup: DispatchGroup)
}

public final class PerformMutationOperation<Mutation: GraphQLMutation>: InMemoryMutationDelegate {
    let client: ApolloClient
    let appSyncClient: AWSAppSyncClient
    let mutation: Mutation
    let handlerQueue: DispatchQueue
    let mutationConflictHandler: MutationConflictHandler<Mutation>?
    let resultHandler: OperationResultHandler<Mutation>?
    let mutationExecutor: MutationExecutor
    public let mutationRecord: AWSAppSyncMutationRecord
    
    init(offlineMutationRecord: AWSAppSyncMutationRecord, client: ApolloClient, appSyncClient: AWSAppSyncClient, offlineExecutor: MutationExecutor, mutation: Mutation, handlerQueue: DispatchQueue, mutationConflictHandler: MutationConflictHandler<Mutation>?, resultHandler: OperationResultHandler<Mutation>?) {
        self.mutationRecord = offlineMutationRecord
        self.client = client
        self.appSyncClient = appSyncClient
        self.mutationExecutor = offlineExecutor
        self.mutation = mutation
        self.handlerQueue = handlerQueue
        self.resultHandler = resultHandler
        self.mutationConflictHandler = mutationConflictHandler
        // set the deletgate callback to self
        self.mutationRecord.inmemoryExecutor = self
        mutationExecutor.queueMutation(mutation: self.mutationRecord)
    }
    
    func performMutation(dispatchGroup: DispatchGroup) {
        dispatchGroup.enter()
        if self.mutationRecord.type == .graphQLMutationWithS3Object {
            // call s3mutation object here
            let _ = appSyncClient.performMutationWithS3Object(operation: self.mutation, s3Object: self.mutationRecord.s3ObjectInput!, conflictResolutionBlock: mutationConflictHandler, dispatchGroup: dispatchGroup, handlerQueue: handlerQueue, resultHandler: resultHandler)
        } else {
            let _ = appSyncClient.send(operation: self.mutation, context: nil, conflictResolutionBlock: self.mutationConflictHandler, dispatchGroup: dispatchGroup, handlerQueue: self.handlerQueue, resultHandler: self.resultHandler)
            let _  = dispatchGroup.wait(timeout: DispatchTime(uptimeNanoseconds: 3000000))
        }
    }
}
