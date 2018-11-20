//
//  AWSAppSyncDeltaSubscription.swift
//  AWSAppSync
//

import Foundation

enum SyncState {
    case active, failed(error: Error), interrupted, terminated(error: Error), cancelled
}

typealias DeltaSyncStatusCallback = ((_ currentState: SyncState) -> Void)

public class SyncConfiguration {
    
    internal let seconds: Int
    
    internal var syncIntervalInSeconds: Int {
        return seconds
    }
    
    public init(baseRefreshIntervalInSeconds: Int) {
        self.seconds = baseRefreshIntervalInSeconds
    }
    
    // utility for setting default sync to 1 day
    public class func defaultSyncConfiguration() -> SyncConfiguration {
        return SyncConfiguration(baseRefreshIntervalInSeconds: 86400)
    }
}

public typealias DeltaQueryResultHandler<Operation: GraphQLQuery> = (_ result: GraphQLResult<Operation.Data>?, _ transaction: ApolloStore.ReadWriteTransaction?, _ error: Error?) -> Void

internal class AppSyncSubscriptionWithSync<Subscription: GraphQLSubscription, BaseQuery: GraphQLQuery, DeltaQuery: GraphQLQuery>: Cancellable {
    
    weak var appsyncClient: AWSAppSyncClient?
    weak var subscriptionMetadataCache: AWSSubscriptionMetaDataCache?
    var syncConfiguration: SyncConfiguration
    var subscription: Subscription?
    var baseQuery: BaseQuery?
    var deltaQuery: DeltaQuery?
    var subscriptionHandler: SubscriptionResultHandler<Subscription>?
    var baseQueryHandler: OperationResultHandler<BaseQuery>?
    var deltaQueryHandler: DeltaQueryResultHandler<DeltaQuery>?
    var subscriptionWatcher: AWSAppSyncSubscriptionWatcher<Subscription>?
    var userCancelledSubscription: Bool = false
    var shouldQueueSubscriptionMessages: Bool = false
    var subscriptionMessagesQueue: [(GraphQLResult<Subscription.Data>, Date)] = []
    var isNetworkAvailable: Bool = true
    var lastSyncTime: Date?
    var deltaSyncOperationQueue: OperationQueue?
    var subscriptionMessageDispatchQueue: DispatchQueue?
    weak var handlerQueue: DispatchQueue?
    var activeTimer: DispatchSourceTimer?
    var deltaSyncStatusCallback: DeltaSyncStatusCallback?
    var isSyncOperationSuccessful: Bool = false
    var currentAttempt: Int = 0
    
    internal init(appsyncClient: AWSAppSyncClient,
                  baseQuery: BaseQuery,
                  deltaQuery: DeltaQuery,
                  subscription: Subscription,
                  baseQueryHandler: @escaping OperationResultHandler<BaseQuery>,
                  deltaQueryHandler: @escaping DeltaQueryResultHandler<DeltaQuery>,
                  subscriptionResultHandler: @escaping SubscriptionResultHandler<Subscription>,
                  subscriptionMetadataCache: AWSSubscriptionMetaDataCache?,
                  syncConfiguration: SyncConfiguration,
                  handlerQueue: DispatchQueue) {
        self.appsyncClient = appsyncClient
        self.subscriptionMetadataCache = subscriptionMetadataCache
        self.syncConfiguration = syncConfiguration
        self.handlerQueue = handlerQueue
        self.baseQuery = baseQuery
        
        // We check if subscription and delta query are not internal no-op operations before setting them
        // This is done since Swift compiler can't infer generic types for these operations.
        if Subscription.operationString != NoOpOperationString {
            self.subscription = subscription
            self.subscriptionHandler = subscriptionResultHandler
        }
        if DeltaQuery.operationString != NoOpOperationString {
            self.deltaQuery = deltaQuery
            self.deltaQueryHandler = deltaQueryHandler
        }
        
        self.baseQueryHandler = baseQueryHandler
        self.deltaSyncOperationQueue = OperationQueue()
        deltaSyncOperationQueue?.maxConcurrentOperationCount = 1
        deltaSyncOperationQueue?.name = "AppSync.DeltaSyncOperationQueue.\(getOperationHash())"
        subscriptionMessageDispatchQueue = DispatchQueue(label: "SubscriptionMessagesQueue.\(getOperationHash())")

        self.deltaSyncOperationQueue?.addOperation {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(AppSyncSubscriptionWithSync.applicationWillEnterForeground),
                                                   name: UIApplication.willEnterForegroundNotification, object: nil)
            
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(AppSyncSubscriptionWithSync.didConnectivityChange(notification:)),
                                                   name: .appSyncReachabilityChanged, object: nil)
            self.loadSyncTimeFromCache()
            self.runBaseQueryFromCache()
            AppSyncLog.debug("DS: Perform Initial Sync")
            self.performDeltaSync()
        }
    }
    
    func getUniqueIdentifierForOperation() -> String {
        return getOperationHash()
    }
    
    func performDeltaSync() {
            // TODO: Capture timestamp here and use it start the asyncTimer
        AppSyncLog.debug("DS: Starting Sync")
        shouldQueueSubscriptionMessages = true
        isSyncOperationSuccessful = false
        // If we have already attempted 15 times, we will back-off by 5 minutes always and this will also save Math computations for 2^x.
        if(currentAttempt >= 15) {
            currentAttempt += 1
        }
        
        let baseQueryDispatchTime = DispatchTime.now()
        
        defer{
            subscriptionMessageDispatchQueue?.sync {
                drainSubscriptionMessagesQueue()
                shouldQueueSubscriptionMessages = false
            }
            
            // setup the timer to force catch up using the base query or retry in case of failed state
            if (isSyncOperationSuccessful) {
                let deadline = baseQueryDispatchTime + .seconds(syncConfiguration.syncIntervalInSeconds)
                AppSyncLog.debug("DS: Setting up baseQuery timer")
                activeTimer = setupAsyncPoll(deadline: deadline)
            } else {
                let waitMillis = min(Int(Double(truncating: pow(2.0, currentAttempt) as NSNumber) * 100.0 + Double(AWSAppSyncRetryHandler.getRandomBetween0And1() * AWSAppSyncRetryHandler.JITTER)), AWSAppSyncRetryHandler.MAX_RETRY_WAIT_MILLIS)
                let deadline = DispatchTime.now() + .milliseconds(waitMillis)
                AppSyncLog.debug("DS: Setting up retry timer")
                activeTimer = setupAsyncPoll(deadline: deadline)
            }
        }
        
        guard startSubscription() == true else {
            return
        }
        
        // If within time frame, fetch using delta query.
        // If lastSyncTime or deltaQuery not available, run base query.
        if (lastSyncTime == nil ||
            deltaQuery == nil ||
            (Date() > Date(timeInterval: TimeInterval(exactly: syncConfiguration.syncIntervalInSeconds)!, since: self.lastSyncTime!))){
            guard runBaseQuery() == true else {
                return
            }
        } else {
            // If we ran baseQuery in this iteration of sync, we do not run the delta query
            guard runDeltaQuery() == true else {
                return
            }
        }
        
        isSyncOperationSuccessful = true
        currentAttempt = 0
    }
    
    func executeAfter(deadline: DispatchTime, queue: DispatchQueue, block: @escaping () -> Void ) -> DispatchSourceTimer {
        let timer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: 0), queue: queue)
        #if swift(>=4)
        timer.schedule(deadline: deadline)
        #else
        timer.scheduleOneshot(deadline: deadline)
        #endif
        timer.setEventHandler(handler: block)
        timer.resume()
        return timer
    }
    
    func setupAsyncPoll(deadline: DispatchTime) -> DispatchSourceTimer {
        // Invalidate existing time and restart again
        activeTimer?.cancel()
        
        return executeAfter(deadline: deadline, queue: self.handlerQueue!) {
            AppSyncLog.debug("DS: Timer fired. Performing sync.")
            self.deltaSyncOperationQueue?.addOperation {
                AppSyncLog.debug("DS: Perform Sync Timer")
                self.performDeltaSync()
            }
        }
    }
    
    // for first call, always try to fetch and return from cache.
    func runBaseQueryFromCache() {
        if let baseQuery = baseQuery {
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            AppSyncLog.info("DS: Running base query from cache.")
            appsyncClient?.fetch(query: baseQuery, cachePolicy: CachePolicy.returnCacheDataDontFetch, resultHandler: {[weak self] (result, error) in
                self?.baseQueryHandler?(result, error)
                dispatchGroup.leave()
            })
            dispatchGroup.wait()
        }
    }
    
    // Each step represents whether to proceed to next step.
    func runBaseQuery() -> Bool {
        var success: Bool = true
        if let baseQuery = baseQuery {
            AppSyncLog.info("DS: Running Base Query Now")
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            let networkFetchTime = Date()
            AppSyncLog.info("DS: Running base query from network.")
            appsyncClient?.fetch(query: baseQuery, cachePolicy: .fetchIgnoringCacheData, resultHandler: {[weak self] (result, error) in
                // call customer if successful or error
                // return false to parent if failed
                if error == nil {
                    self?.baseQueryHandler?(result, error)
                    success = true
                } else if error != nil && result != nil {
                    self?.baseQueryHandler?(result, error)
                    success = true
                } else {
                    self?.baseQueryHandler?(result, error)
                    success = false
                }
                if (success) {
                    AppSyncLog.debug("DS: Updating last sync time.")
                    self?.updateLastSyncTimeInMemoryAndCache(date: networkFetchTime)
                }
                dispatchGroup.leave()
            })
            dispatchGroup.wait()
            
        }
        return success
    }
    
    
    /// Runs the delta query based on the given criterias.
    ///
    /// - Returns: true if the operation is executed successfully.
    func runDeltaQuery() -> Bool {
        if let deltaQuery = deltaQuery, let lastSyncTime = self.lastSyncTime {
            let dispatchGroup = DispatchGroup()
            AppSyncLog.info("DS: Running Delta Query now")
            if let networkTransport = appsyncClient?.httpTransport as? AWSAppSyncHTTPNetworkTransport {
                dispatchGroup.enter()
                var overrideMap: [String:Int] = [:]
                if let lastSyncTime = self.lastSyncTime {
                    AppSyncLog.debug("DS: Using last sync time from cache. \(lastSyncTime.description)")
                    overrideMap = ["lastSync": Int(Float(lastSyncTime.timeIntervalSince1970.description)!)]
                } else {
                    AppSyncLog.debug("DS: No last sync time available")
                }
                
                func notifyResultHandler(result: GraphQLResult<DeltaQuery.Data>?, transaction: ApolloStore.ReadWriteTransaction?, error: Error?) {
                    handlerQueue?.async {
                        let _ = self.appsyncClient?.store?.withinReadWriteTransaction { transaction in
                            self.deltaQueryHandler?(result, transaction, error)
                            if (error == nil) {
                                self.updateLastSyncTimeInMemoryAndCache(date: Date())
                            }
                        }
                    }
                }
                
                let _ = networkTransport.send(operation: deltaQuery, overrideMap: overrideMap) {[weak self] (response, error) in
                    guard let response = response else {
                        notifyResultHandler(result: nil, transaction: nil, error: error)
                        return
                    }
                    // we have the parsing logic here to perform custom actions in cache, e.g. if we receive a delete type event, we can remove from store.
                    firstly {
                        try response.parseResult(cacheKeyForObject: self?.appsyncClient?.store!.cacheKeyForObject)
                        }.andThen { (result, records) in
                            notifyResultHandler(result: result, transaction: nil, error: nil)
                            if let records = records {
                                self?.appsyncClient?.store?.publish(records: records, context: nil).catch { error in
                                    preconditionFailure(String(describing: error))
                                }
                            }
                        }.catch { error in
                            notifyResultHandler(result: nil, transaction: nil, error: error)
                    }
                    dispatchGroup.leave()
                }
                dispatchGroup.wait()
            }
        }
        return true
    }
    
    func startSubscription() -> Bool {
        var success: Bool? = nil
        if let subscription = subscription {
            AppSyncLog.info("DS: Starting Sub Now")
            let dispatchGroup = DispatchGroup()
            var updatedSubscriptionWatcher: AWSAppSyncSubscriptionWatcher<Subscription>?
            var isSubscriptionWatcherUpdated: Bool = false
            do {
                dispatchGroup.enter()
                updatedSubscriptionWatcher = try appsyncClient?.subscribeWithConnectCallback(subscription: subscription, connectCallback: ({
                    success = true
                    if (!isSubscriptionWatcherUpdated) {
                        isSubscriptionWatcherUpdated = true
                        self.subscriptionWatcher?.cancel()
                        self.subscriptionWatcher = nil
                        self.subscriptionWatcher = updatedSubscriptionWatcher
                        dispatchGroup.leave()
                    }
                }), resultHandler: {[weak self] (result, transaction, error) in
                    // TODO: Improve error checking.
                    if let _ = error as? AWSAppSyncSubscriptionError {
                        if (success == nil) {
                            dispatchGroup.leave()
                            success = false
                        }
                    }
                    self?.handleSubscriptionCallback(result, transaction, error)
                })
                
            } catch {
                self.handleSubscriptionCallback(nil, nil, error)
                if(success == nil) {
                    success = false
                    dispatchGroup.leave()
                }
            }
            dispatchGroup.wait()
        } else {
            success = true
        }
        return success == true
    }
    
    func handleSubscriptionCallback(_ result: GraphQLResult<Subscription.Data>?, _ transaction: ApolloStore.ReadWriteTransaction?, _ error: Error?) {
        // TODO: Improve error checking.
        if let error = error as? AWSAppSyncSubscriptionError, error.additionalInfo == "Subscription Terminated." {
            // Do not give the developer a disconnect callback here. We have to retry the subscription once app comes from background to foreground or internet becomes available.
            AppSyncLog.debug("DS: Subscription terminated. Waiting for network to restart.")
            deltaSyncStatusCallback?(.interrupted)
        } else if let result = result, let transaction = transaction {
            subscriptionMessageDispatchQueue?.sync {
                if shouldQueueSubscriptionMessages {
                    // store arriaval timestamp as well to make sure we use it for maintaining last sync time.
                    AppSyncLog.debug("DS: Received subscription message, saving subscription message in queue.")
                    subscriptionMessagesQueue.append((result, Date()))
                } else {
                    AppSyncLog.debug("DS: Received subscription message, invoking customer callback.")
                    subscriptionHandler?(result, transaction, nil)
                    updateLastSyncTimeInMemoryAndCache(date: Date())
                }
            }
        } else {
            AppSyncLog.error("DS: Unable to start subscription.")
            deltaSyncStatusCallback?(.interrupted)
        }
    }
    
    /// Drains any messages from the subscription messages queue and updates last sync time to current time.
    func drainSubscriptionMessagesQueue() {
        if let subscriptionHandler = subscriptionHandler {
            AppSyncLog.debug("DS: Dequeuing any available messages from subscription messages queue.")
            AppSyncLog.debug("DS: Found \(subscriptionMessagesQueue.count) messages in queue.")
            for message in subscriptionMessagesQueue {
                do {
                    try self.appsyncClient?.store?.withinReadWriteTransaction({ (transaction) in
                        subscriptionHandler(message.0, transaction, nil)
                    }).await()
                    updateLastSyncTimeInMemoryAndCache(date: message.1)
                } catch {
                    subscriptionHandler(nil, nil, error)
                }
            }
        }
        
        AppSyncLog.debug("DS: Clearing subscription messages queue.")
        subscriptionMessagesQueue = []
    }
    
    
    /// This function generates a unique identifier hash for the combination of specified parameters including the GraphQL variables.
    /// The hash is always same for the same set of operations.
    ///
    /// - Returns: The unique hash for the specified queries & subscription.
    func getOperationHash() -> String {
        
        var baseString = ""
        
        if let baseQuery = baseQuery {
            let variables = baseQuery.variables?.description ?? ""
            baseString =  type(of: baseQuery).requestString + variables
        }
        
        if let subscription = subscription {
            let variables = subscription.variables?.description ?? ""
            baseString = type(of: subscription).requestString + variables
        }
        
        if let deltaQuery = deltaQuery {
            let variables = deltaQuery.variables?.description ?? ""
            baseString =  type(of: deltaQuery).requestString + variables
        }
        
        return AWSSignatureSignerUtility.hash(baseString.data(using: .utf8)!)!.base64EncodedString()
    }
    
    /// Responsible to update the last sync time in cache. Expected to be called when subs message is given to the customer or if base query or delta query is run.
    func updateLastSyncTimeInMemoryAndCache(date: Date) {
        do {
            let adjustedDate = date.addingTimeInterval(TimeInterval.init(exactly: -2)!)
            self.lastSyncTime = adjustedDate
            AppSyncLog.debug("DS: Updating lastSync time \(self.lastSyncTime.debugDescription)")
            try self.subscriptionMetadataCache?.updateLasySyncTime(for: getOperationHash(), with: adjustedDate)
        } catch {
            // ignore cache write failure, will be updated in next operation, is backed up by in-memory cache
        }
    }
    
    /// Fetches last sync time from the cache.
    func loadSyncTimeFromCache() {
        do {
            self.lastSyncTime = try self.subscriptionMetadataCache?.getLastSyncTime(operationHash: getOperationHash())
            AppSyncLog.debug("DS: lastSync \(self.lastSyncTime.debugDescription)")
        } catch {
            // could not find it in cache, do not update the instance variable of lasy sync time; assume no sync was done previously
        }
    }
    
    @objc func applicationWillEnterForeground() {
        // perform delta sync here
        // disconnect from sub and reconnect
        self.deltaSyncOperationQueue?.addOperation {
            AppSyncLog.debug("DS: Perform Sync Foreground")
            self.performDeltaSync()
        }
    }
    
    @objc func didConnectivityChange(notification: Notification) {
        // If internet was disconnected and is available now, perform deltaSync
        let connectionInfo = notification.object as! AppSyncConnectionInfo
        
        isNetworkAvailable = connectionInfo.isConnectionAvailable
        
        if (connectionInfo.isConnectionAvailable) {
            self.deltaSyncOperationQueue?.addOperation {
                AppSyncLog.debug("DS: Perform Sync Network")
                self.performDeltaSync()
            }
        }
    }
    
    deinit {
        internalCancel()
    }
    
    func internalCancel() {
        // handle cancel logic here.
        subscriptionWatcher?.cancel()
        subscriptionWatcher = nil
        NotificationCenter.default.removeObserver(self)
        activeTimer?.cancel()
    }
    
    // This is user-initiated cancel
    func cancel() {
        // perform user-cancelled tasks in this block
        userCancelledSubscription = true
        deltaSyncStatusCallback?(.cancelled)
        internalCancel()
    }
}
