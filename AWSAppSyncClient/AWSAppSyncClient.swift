//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
import AWSCore

public typealias SubscriptionResultHandler<Operation: GraphQLSubscription> = (_ result: GraphQLResult<Operation.Data>?, _ transaction: ApolloStore.ReadWriteTransaction?, _ error: Error?) -> Void

public typealias SubscriptionStatusChangeHandler = (AWSAppSyncSubscriptionWatcherStatus) -> Void

public typealias DeltaQueryResultHandler<Operation: GraphQLQuery> = (_ result: GraphQLResult<Operation.Data>?, _ transaction: ApolloStore.ReadWriteTransaction?, _ error: Error?) -> Void

public typealias OptimisticResponseBlock = (ApolloStore.ReadWriteTransaction?) -> Void

public typealias MutationConflictHandler<Mutation: GraphQLMutation> = (_ serverState: Snapshot?, _ taskCompletionSource: AWSTaskCompletionSource<Mutation>?, _ resultHandler: OperationResultHandler<Mutation>?) -> Void

internal let NoOpOperationString = "No-op"

/// Delegates will be notified when a mutation is performed from the `mutationCallback`. This pattern is necessary
/// in order to provide notifications of mutations which are performed after an app restart and the initial callback
/// context has been lost.
public protocol AWSAppSyncOfflineMutationDelegate {
    func mutationCallback(recordIdentifier: String, operationString: String, snapshot: Snapshot?, error: Error?)
}

/// The client for making `Mutation`, `Query` and `Subscription` requests.
public class AWSAppSyncClient {

    static var prefixTracker: [String: (String, Int)] = [:]
    static var prefixTrackerQueue: DispatchQueue = DispatchQueue(label: "com.amazonaws.appsync.AWSAppSyncClient.clientDatabasePrefixTrackerQueue")

    public let apolloClient: ApolloClient?
    public let store: ApolloStore?
    public let presignedURLClient: AWSS3ObjectPresignedURLGenerator?
    public let s3ObjectManager: AWSS3ObjectManager?

    var httpTransport: AWSNetworkTransport?
    var subscriptionConnectionFactory: SubscriptionConnectionFactory?

    public var offlineMutationDelegate: AWSAppSyncOfflineMutationDelegate?
    private var mutationQueue: AWSPerformMutationQueue!
    var retryStrategy: AWSAppSyncRetryStrategy

    var prefixTrackerKey: String?
    var prefixTrackerValue: String?

    /// The count of Mutation operations queued for sending to the backend.
    ///
    /// AppSyncClient processes both offline and online mutations, and mutations are queued for processing even while
    /// the client is offline, so this count represents a good measure of the number of mutations that have yet to be
    /// successfully sent to the service, regardless of the state of the network.
    ///
    /// This value is `nil` if the mutationQueue cannot be accessed (e.g., has not finished initializing).
    public var queuedMutationCount: Int? {
        return mutationQueue?.operationQueueCount
    }

    private var connectionStateChangeHandler: ConnectionStateChangeHandler?
    private var autoSubmitOfflineMutations: Bool = false
    private var subscriptionsQueue = DispatchQueue(label: "SubscriptionsQueue", qos: .userInitiated)

    fileprivate var subscriptionMetadataCache: AWSSubscriptionMetaDataCache?

    /// Creates a client with the specified `AWSAppSyncClientConfiguration`.
    ///
    /// - Parameters:
    ///   - appSyncConfig: The `AWSAppSyncClientConfiguration` object.
    public convenience init(appSyncConfig: AWSAppSyncClientConfiguration) throws {
        try self.init(appSyncConfig: appSyncConfig, reachabilityFactory: nil)
    }

    /// Creates a client with the specified `AWSAppSyncClientConfiguration`
    /// and `NetworkReachabilityProvidingFactory`.
    ///
    /// This method is primarily intended to facilitate integration testing, but may be used by apps that wish
    /// to use their own reachability solution in place of AppSync's bundled reachability framework.
    ///
    /// Note that the AppSync client's use of the Reachability client provided by the factory should be
    /// considered an implementation detail. In particular, apps should not rely on AppSync to inspect network
    /// reachability status before attempting a network connection.
    ///
    /// - Parameters:
    ///   - appSyncConfig: The `AWSAppSyncClientConfiguration` object.
    ///   - reachabilityFactory: An optional factory that provides `NetworkReachabilityProviding` instances.
    public init(appSyncConfig: AWSAppSyncClientConfiguration,
                reachabilityFactory: NetworkReachabilityProvidingFactory.Type? = nil) throws {

        AppSyncLog.info("Initializing AppSyncClient")
        self.autoSubmitOfflineMutations = appSyncConfig.autoSubmitOfflineMutations
        self.store = appSyncConfig.store
        self.presignedURLClient = appSyncConfig.presignedURLClient
        self.s3ObjectManager = appSyncConfig.s3ObjectManager
        self.subscriptionMetadataCache = appSyncConfig.subscriptionMetadataCache

        self.httpTransport = appSyncConfig.networkTransport
        self.connectionStateChangeHandler = appSyncConfig.connectionStateChangeHandler
        
        self.retryStrategy = appSyncConfig.retryStrategy

        self.apolloClient = ApolloClient(networkTransport: self.httpTransport!, store: appSyncConfig.store)
        self.subscriptionConnectionFactory = appSyncConfig.subscriptionConnectionFactory
        NetworkReachabilityNotifier.setupShared(
            host: appSyncConfig.url.host!,
            allowsCellularAccess: appSyncConfig.allowsCellularAccess,
            reachabilityFactory: reachabilityFactory)

        self.mutationQueue = AWSPerformMutationQueue(
            appSyncClient: self,
            networkClient: httpTransport!,
            reachabiltyChangeNotifier: NetworkReachabilityNotifier.shared,
            cacheFileURL: appSyncConfig.cacheConfiguration?.offlineMutations)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appsyncReachabilityChanged(note:)),
            name: .appSyncReachabilityChanged,
            object: nil)

        try AWSAppSyncClient.prefixTrackerQueue.sync {
            if appSyncConfig.cacheConfiguration?.usePrefix ?? false {
                let prefixTrackerKey = appSyncConfig.cacheConfiguration?.prefix ?? ""
                let authTypeString = appSyncConfig.authType?.rawValue ?? "unknown_auth"
                let prefixTrackerValue = appSyncConfig.url.absoluteString + "_" + authTypeString
                if let (clientString, clientCount) = AWSAppSyncClient.prefixTracker[prefixTrackerKey] {
                    if clientString != prefixTrackerValue {
                        throw AWSAppSyncClientConfigurationError.cacheConfigurationAlreadyInUse("Configured two clients with the same database prefix")
                    } else {
                        AWSAppSyncClient.prefixTracker[prefixTrackerKey] = (prefixTrackerValue, clientCount + 1)
                    }
                } else {
                    AWSAppSyncClient.prefixTracker[prefixTrackerKey] = (prefixTrackerValue, 1)
                }
                self.prefixTrackerKey = prefixTrackerKey
                self.prefixTrackerValue = prefixTrackerValue
            }
        }
    }

    deinit {
        AppSyncLog.info("Releasing AppSyncClient")
        NetworkReachabilityNotifier.clearShared()
        AWSAppSyncClient.prefixTrackerQueue.sync {
            if let key = self.prefixTrackerKey,
                let (value, count) = AWSAppSyncClient.prefixTracker[key] {
                if count <= 1 {
                    AWSAppSyncClient.prefixTracker[key] = nil
                } else {
                    AWSAppSyncClient.prefixTracker[key] = (value, count - 1)
                }
            }
        }
    }

    @objc func appsyncReachabilityChanged(note: Notification) {
        let connectionInfo = note.object as! AppSyncConnectionInfo
        let isReachable = connectionInfo.isConnectionAvailable
        let accessState = isReachable ? ClientNetworkAccessState.Online : .Offline
        self.connectionStateChangeHandler?.stateChanged(networkState: accessState)
    }

    /// Clears apollo cache
    ///
    /// - Returns: Promise
    @available(*, deprecated, message: "Use the clearCaches method that optionally takes in ClearCacheOptions")
    public func clearCache() -> Promise<Void> {
        guard let store = store else { return Promise(fulfilled: ()) }
        return store.clearCache()
    }

    /// Clears the apollo cache, offline mutation queue, and delta sync subscription metadata
    ///
    /// - Parameters:
    ///   - options Fine-tune which caches are cleared when calling this method
    public func clearCaches(options: ClearCacheOptions = ClearCacheOptions(clearQueries: true, clearMutations: true, clearSubscriptions: true)) throws {
        var map: [CacheType: Error] = [:]
        do {
            if options.clearQueries {
                try store?.clearCache().await()
            }
        } catch {
            map[.query] = error
        }
        do {
            if options.clearMutations {
                try mutationQueue.clearQueue()
            }
        } catch {
            map[.mutation] = error
        }
        do {
            if options.clearSubscriptions {
                try subscriptionMetadataCache?.clear()
            }
        } catch {
            map[.subscription] = error
        }
        if map.keys.count > 0 {
            throw ClearCacheError.failedToClear(map)
        }
    }

    /// Fetches a query from the server or from the local cache, depending on the current contents of the cache and the
    /// specified cache policy.
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
        AppSyncLog.verbose("Fetching: \(query)")
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

    public func subscribe<Subscription: GraphQLSubscription>(subscription: Subscription,
                                                             queue: DispatchQueue = DispatchQueue.main,
                                                             statusChangeHandler: SubscriptionStatusChangeHandler? = nil,
                                                             resultHandler: @escaping SubscriptionResultHandler<Subscription>) throws -> AWSAppSyncSubscriptionWatcher<Subscription>? {
        let connection = self.subscriptionConnectionFactory?.connection(connectionType: .appSyncRealtime)
        return AWSAppSyncSubscriptionWatcher(connection: connection!,
                                             store: self.store!,
                                             subscriptionsQueue: self.subscriptionsQueue,
                                             subscription: subscription,
                                             handlerQueue: queue,
                                             statusChangeHandler: statusChangeHandler,
                                             resultHandler: resultHandler)
    }

    internal func subscribeWithConnectCallback<Subscription: GraphQLSubscription>(subscription: Subscription,
                                                                                  queue: DispatchQueue = DispatchQueue.main,
                                                                                  connectCallback: @escaping (() -> Void),
                                                                                  resultHandler: @escaping SubscriptionResultHandler<Subscription>) throws -> AWSAppSyncSubscriptionWatcher<Subscription>? {
        let connection = self.subscriptionConnectionFactory?.connection(connectionType: .appSyncRealtime)
        return AWSAppSyncSubscriptionWatcher(connection: connection!,
                                             store: self.store!,
                                             subscriptionsQueue: self.subscriptionsQueue,
                                             subscription: subscription,
                                             handlerQueue: queue,
                                             statusChangeHandler: nil,
                                             connectedCallback: connectCallback,
                                             resultHandler: resultHandler)
    }

    /// Performs a mutation by sending it to the server. Internally, these mutations are added to a queue and performed
    /// serially, in first-in, first-out order. Clients can inspect the size of the queue with the `queuedMutationCount`
    /// property.
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
                AppSyncLog.error("optimisticUpdate error: \(error)")
            }
        }

        return mutationQueue.add(
            mutation,
            mutationConflictHandler: conflictResolutionBlock,
            mutationResultHandler: resultHandler,
            handlerQueue: queue
        )
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
