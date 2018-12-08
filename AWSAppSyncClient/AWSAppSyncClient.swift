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

public typealias DeltaQueryResultHandler<Operation: GraphQLQuery> = (_ result: GraphQLResult<Operation.Data>?, _ transaction: ApolloStore.ReadWriteTransaction?, _ error: Error?) -> Void

public typealias OptimisticResponseBlock = (ApolloStore.ReadWriteTransaction?) -> Void

public typealias MutationConflictHandler<Mutation: GraphQLMutation> = (_ serverState: Snapshot?, _ taskCompletionSource: AWSTaskCompletionSource<Mutation>?, _ resultHandler: OperationResultHandler<Mutation>?) -> Void

enum AWSAppSyncGraphQLOperation {
    case mutation
    case query
    case subscription
}

internal let NoOpOperationString = "No-op"

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
        default:
            break
        }

        for watchers in networkStatusWatchers {
            watchers.onNetworkAvailabilityStatusChanged(isEndpointReachable: isReachable)
        }
    }

    var isNetworkReachable: Bool {
        guard let reachability = reachability else {
            return false
        }

        switch reachability.connection {
        case .none:
            return false
        case .wifi:
            return true
        case .cellular:
            return allowsCellularAccess
        }
    }

    func canExecute(_ operation: AWSAppSyncGraphQLOperation) -> Bool {
        switch operation {
        case .mutation:
            return isNetworkReachable
        case .query:
            return true
        case .subscription:
            return true
        }
    }
}

public enum AWSAppSyncClientError: Error, LocalizedError {
    case requestFailed(Data?, HTTPURLResponse?, Error?)
    case noData(HTTPURLResponse)
    case parseError(Data, HTTPURLResponse, Error?)
    case authenticationError(Error)

    public var errorDescription: String? {
        let underlyingError: Error?
        var message: String
        let errorResponse: HTTPURLResponse?
        switch self {
        case .requestFailed(_, let response, let error):
            errorResponse = response
            underlyingError = error
            message = "Did not receive a successful HTTP code."
        case .noData(let response):
            errorResponse = response
            underlyingError = nil
            message = "No Data received in response."
        case .parseError(_, let response, let error):
            underlyingError = error
            errorResponse = response
            message = "Could not parse response data."
        case .authenticationError(let error):
            underlyingError = error
            errorResponse = nil
            message = "Failed to authenticate request."
        }

        if let error = underlyingError {
            message += " Error: \(error)"
        }

        if let unwrappedResponse = errorResponse {
            return "(\(unwrappedResponse.statusCode) \(unwrappedResponse.statusCodeDescription)) \(message)"
        } else {
            return "\(message)"
        }
    }

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

public struct AWSAppSyncSubscriptionError: Error, LocalizedError {
    let additionalInfo: String?
    let errorDetails: [String: String]?

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
    func mutationCallback(recordIdentifier: String, operationString: String, snapshot: Snapshot?, error: Error?)
}

public struct AppSyncConnectionInfo {
    public let isConnectionAvailable: Bool
    public let isInitialConnection: Bool
}

internal extension Notification.Name {
    internal static let appSyncReachabilityChanged = Notification.Name("AppSyncNetworkAvailabilityChangedNotification")
}

class AWSAppSyncNetworkStatusChangeNotifier {
    var reachability: Reachability?
    var allowsCellularAccess: Bool = true
    var isInitialConnection: Bool = true

    static func setupSharedInstance(host: String, allowsCellular: Bool) {
        sharedInstance = AWSAppSyncNetworkStatusChangeNotifier(host: host, allowsCellular: allowsCellular)
    }

    static var sharedInstance: AWSAppSyncNetworkStatusChangeNotifier?

    private init(host: String, allowsCellular: Bool) {
        reachability = Reachability(hostname: host)
        allowsCellularAccess = allowsCellular
        NotificationCenter.default.addObserver(self, selector: #selector(checkForReachability(note:)), name: .reachabilityChanged, object: reachability)
        do {
            try reachability?.startNotifier()
        } catch {

        }
    }

    @objc func checkForReachability(note: Notification) {
        let reachability = note.object as! Reachability
        var isReachable = false

        switch reachability.connection {
        case .wifi:
            isReachable = true
        case .cellular:
            if self.allowsCellularAccess {
                isReachable = true
            }
        case .none:
            isReachable = false
        }

        let info = AppSyncConnectionInfo.init(isConnectionAvailable: isReachable, isInitialConnection: isInitialConnection)

        guard isInitialConnection == false else {
            isInitialConnection = false
            return
        }

        NotificationCenter.default.post(name: .appSyncReachabilityChanged, object: info)
    }
}

// The client for making `Mutation`, `Query` and `Subscription` requests.
public class AWSAppSyncClient {

    public let apolloClient: ApolloClient?
    public let store: ApolloStore?
    public let presignedURLClient: AWSS3ObjectPresignedURLGenerator?
    public let s3ObjectManager: AWSS3ObjectManager?

    internal var reachability: Reachability?
    internal var httpTransport: AWSNetworkTransport?
    internal var connectionStateChangeHandler: ConnectionStateChangeHandler?

    public var offlineMutationDelegate: AWSAppSyncOfflineMutationDelegate?
    private var offlineMutationQueue: AWSPerformMutationQueue!

    private var networkStatusWatchers: [NetworkConnectionNotification] = []
    private var autoSubmitOfflineMutations: Bool = false
    private var appSyncMQTTClient = AppSyncMQTTClient()
    private var subscriptionsQueue = DispatchQueue(label: "SubscriptionsQueue", qos: .userInitiated)

    fileprivate var subscriptionMetadataCache: AWSSubscriptionMetaDataCache?
    fileprivate var accessState: ClientNetworkAccessState = .Offline

    /// Creates a client with the specified `AWSAppSyncClientConfiguration`.
    ///
    /// - Parameters:
    ///   - appSyncConfig: The `AWSAppSyncClientConfiguration` object.
    public init(appSyncConfig: AWSAppSyncClientConfiguration) throws {
        self.reachability = Reachability(hostname: appSyncConfig.url.host!)
        self.autoSubmitOfflineMutations = appSyncConfig.autoSubmitOfflineMutations
        self.store = appSyncConfig.store
        self.appSyncMQTTClient.allowCellularAccess = appSyncConfig.allowsCellularAccess
        self.presignedURLClient = appSyncConfig.presignedURLClient
        self.s3ObjectManager = appSyncConfig.s3ObjectManager
        self.subscriptionMetadataCache = appSyncConfig.subscriptionMetadataCache

        self.httpTransport = appSyncConfig.networkTransport
        self.connectionStateChangeHandler = appSyncConfig.connectionStateChangeHandler

        self.apolloClient = ApolloClient(networkTransport: self.httpTransport!, store: appSyncConfig.store)

        self.offlineMutationQueue = AWSPerformMutationQueue(
            appSyncClient: self,
            networkClient: httpTransport!,
            handlerQueue: .main,
            snapshotProcessController: SnapshotProcessController(endpointURL: appSyncConfig.url),
            fileURL: appSyncConfig.databaseURL)
        networkStatusWatchers.append(offlineMutationQueue)

        if AWSAppSyncNetworkStatusChangeNotifier.sharedInstance == nil {
            AWSAppSyncNetworkStatusChangeNotifier.setupSharedInstance(host: appSyncConfig.url.host!, allowsCellular: appSyncConfig.allowsCellularAccess)
        }

        NotificationCenter.default.addObserver(
            self, selector: #selector(appsyncReachabilityChanged(note:)), name: .appSyncReachabilityChanged, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .appSyncReachabilityChanged, object: nil)
    }

    @objc func appsyncReachabilityChanged(note: Notification) {

        let connectionInfo = note.object as! AppSyncConnectionInfo
        let isReachable = connectionInfo.isConnectionAvailable
        for watchers in networkStatusWatchers {
            watchers.onNetworkAvailabilityStatusChanged(isEndpointReachable: isReachable)
        }

        var accessState: ClientNetworkAccessState = .Offline
        if isReachable {
            accessState = .Online
            self.accessState = .Online
        } else {
            self.accessState = .Offline
        }
        self.connectionStateChangeHandler?.stateChanged(networkState: accessState)
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

    internal func subscribeWithConnectCallback<Subscription: GraphQLSubscription>(subscription: Subscription, queue: DispatchQueue = DispatchQueue.main, connectCallback: @escaping (() -> Void), resultHandler: @escaping SubscriptionResultHandler<Subscription>) throws -> AWSAppSyncSubscriptionWatcher<Subscription>? {

        return AWSAppSyncSubscriptionWatcher(client: self.appSyncMQTTClient,
                                             httpClient: self.httpTransport!,
                                             store: self.store!,
                                             subscriptionsQueue: self.subscriptionsQueue,
                                             subscription: subscription,
                                             handlerQueue: queue,
                                             connectedCallback: connectCallback,
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
    @discardableResult
    public func perform<Mutation: GraphQLMutation>(
        mutation: Mutation,
        mutationPriority: AWSPerformMutationPriority = .normal,
        queue: DispatchQueue = .main,
        optimisticUpdate: OptimisticResponseBlock? = nil,
        conflictResolutionBlock: MutationConflictHandler<Mutation>? = nil,
        resultHandler: OperationResultHandler<Mutation>? = nil) -> Cancellable {

        if let optimisticUpdate = optimisticUpdate {
            do {
                _ = try store?.withinReadWriteTransaction { transaction in
                    optimisticUpdate(transaction)
                }.await()
            } catch {
                debugPrint("optimisticUpdate error: \(error)")
            }
        }

        return offlineMutationQueue.add(
            mutation,
            mutationPriority: mutationPriority,
            mutationConflictHandler: conflictResolutionBlock,
            mutationResultHandler: resultHandler)
    }

    internal final class EmptySubscription: GraphQLSubscription {
        public static var operationString: String = NoOpOperationString
        struct Data: GraphQLSelectionSet {
            static var selections: [GraphQLSelection] = []
            var snapshot: Snapshot = [:]
        }
    }

    internal final class EmptyQuery: GraphQLQuery {
        public static var operationString: String = NoOpOperationString
        struct Data: GraphQLSelectionSet {
            static var selections: [GraphQLSelection] = []
            var snapshot: Snapshot = [:]
        }
    }

    /// Performs a sync operation where a base query is periodically called to fetch primary data from the server based on the syncConfiguration.
    ///
    /// - Parameters:
    ///   - baseQuery: The base query to fetch which contains the primary data.
    ///   - baseQueryResultHandler: Closure that is called when base query results are available or when an error occurs. Every time a sync operation is called, a fetch for the baseQuery from the cache will be done first before initiating any other operations.
    ///   - subscription: The subscription which will provide real time updates.
    ///   - subscriptionResultHandler: Closure that is called when a real time update is available or when an error occurs.
    ///   - deltaQuery: The delta query which fetches data starting from the `lastSync` time.
    ///   - deltaQueryResultHandler: Closure that is called when delta query executes.
    ///   - callbackQueue: An optional queue on which sync callbacks will be invoked. Defaults to the main queue.
    ///   - syncConfiguration: The sync configuration where the baseQuery sync interval can be specified. (Defaults to 24 hours.)
    /// - Returns: An object that can be used to cancel the sync operation.
    public func sync<BaseQuery: GraphQLQuery, Subscription: GraphQLSubscription, DeltaQuery: GraphQLQuery>(baseQuery: BaseQuery,
                                                                                                           baseQueryResultHandler: @escaping OperationResultHandler<BaseQuery>,
                                                                                                           subscription: Subscription,
                                                                                                           subscriptionResultHandler: @escaping SubscriptionResultHandler<Subscription>,
                                                                                                           deltaQuery: DeltaQuery,
                                                                                                           deltaQueryResultHandler: @escaping DeltaQueryResultHandler<DeltaQuery>,
                                                                                                           callbackQueue: DispatchQueue = DispatchQueue.main,
                                                                                                           syncConfiguration: SyncConfiguration = SyncConfiguration()) -> Cancellable {
        return AppSyncSubscriptionWithSync<Subscription, BaseQuery, DeltaQuery>(appSyncClient: self,
                                                                                baseQuery: baseQuery,
                                                                                deltaQuery: deltaQuery,
                                                                                subscription: subscription,
                                                                                baseQueryHandler: baseQueryResultHandler,
                                                                                deltaQueryHandler: deltaQueryResultHandler,
                                                                                subscriptionResultHandler: subscriptionResultHandler,
                                                                                subscriptionMetadataCache: self.subscriptionMetadataCache,
                                                                                syncConfiguration: syncConfiguration,
                                                                                handlerQueue: callbackQueue)
    }

    /// Performs a sync operation where a base query is periodically called to fetch primary data from the server based on the syncConfiguration.
    ///
    /// - Parameters:
    ///   - baseQuery: The base query to fetch which contains the primary data.
    ///   - baseQueryResultHandler: Closure that is called when base query results are available or when an error occurs. Every time a sync operation is called, a fetch for the baseQuery from the cache will be done first before initiating any other operations.
    ///   - deltaQuery: The delta query which fetches data starting from the `lastSync` time.
    ///   - deltaQueryResultHandler: Closure that is called when delta query executes.
    ///   - callbackQueue: An optional queue on which sync callbacks will be invoked. Defaults to the main queue.
    ///   - syncConfiguration: The sync configuration where the baseQuery sync interval can be specified. (Defaults to 24 hours.)
    /// - Returns: An object that can be used to cancel the sync operation.
    public func sync<BaseQuery: GraphQLQuery, DeltaQuery: GraphQLQuery>(baseQuery: BaseQuery,
                                                                        baseQueryResultHandler: @escaping OperationResultHandler<BaseQuery>,
                                                                        deltaQuery: DeltaQuery,
                                                                        deltaQueryResultHandler: @escaping DeltaQueryResultHandler<DeltaQuery>,
                                                                        callbackQueue: DispatchQueue = DispatchQueue.main,
                                                                        syncConfiguration: SyncConfiguration = SyncConfiguration()) -> Cancellable {

        // The compiler chokes on delegating to `AWSAppSyncClient.sync(baseQuery:baseQueryResultHandler:..)`, so we'll invoke
        // the final return within this method, at the expense of some code duplication.
        let subscription = EmptySubscription.init()
        let subscriptionResultHandler: SubscriptionResultHandler<EmptySubscription> = { (_, _, _) in }

        return AppSyncSubscriptionWithSync<EmptySubscription, BaseQuery, DeltaQuery>(appSyncClient: self,
                                                                                     baseQuery: baseQuery,
                                                                                     deltaQuery: deltaQuery,
                                                                                     subscription: subscription,
                                                                                     baseQueryHandler: baseQueryResultHandler,
                                                                                     deltaQueryHandler: deltaQueryResultHandler,
                                                                                     subscriptionResultHandler: subscriptionResultHandler,
                                                                                     subscriptionMetadataCache: self.subscriptionMetadataCache,
                                                                                     syncConfiguration: syncConfiguration,
                                                                                     handlerQueue: callbackQueue)
    }

    /// Performs a sync operation where a base query is periodically called to fetch primary data from the server based on the syncConfiguration.
    ///
    /// - Parameters:
    ///   - baseQuery: The base query to fetch which contains the primary data.
    ///   - baseQueryResultHandler: Closure that is called when base query results are available or when an error occurs. Every time a sync operation is called, a fetch for the baseQuery from the cache will be done first before initiating any other operations.
    ///   - callbackQueue: An optional queue on which sync callbacks will be invoked. Defaults to the main queue.
    ///   - syncConfiguration: The sync configuration where the baseQuery sync interval can be specified. (Defaults to 24 hours.)
    /// - Returns: An object that can be used to cancel the sync operation.
    public func sync<BaseQuery: GraphQLQuery>(baseQuery: BaseQuery,
                                              baseQueryResultHandler: @escaping OperationResultHandler<BaseQuery>,
                                              callbackQueue: DispatchQueue = DispatchQueue.main,
                                              syncConfiguration: SyncConfiguration = SyncConfiguration()) -> Cancellable {

        let subs = EmptySubscription.init()
        let subsCallback: (GraphQLResult<EmptySubscription.Data>?, ApolloStore.ReadTransaction?, Error?) -> Void = { (_, _, _) in }

        let deltaQuery = EmptyQuery.init()
        let deltaCallback: (GraphQLResult<EmptyQuery.Data>?, ApolloStore.ReadTransaction?, Error?) -> Void = { (_, _, _) in }

        return AppSyncSubscriptionWithSync<EmptySubscription, BaseQuery, EmptyQuery>.init(appSyncClient: self,
                                                                                          baseQuery: baseQuery,
                                                                                          deltaQuery: deltaQuery,
                                                                                          subscription: subs,
                                                                                          baseQueryHandler: baseQueryResultHandler,
                                                                                          deltaQueryHandler: deltaCallback,
                                                                                          subscriptionResultHandler: subsCallback,
                                                                                          subscriptionMetadataCache: self.subscriptionMetadataCache,
                                                                                          syncConfiguration: syncConfiguration,
                                                                                          handlerQueue: callbackQueue)
    }
}
