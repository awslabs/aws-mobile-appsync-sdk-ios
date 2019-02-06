//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

final class AppSyncSubscriptionWithSync<Subscription: GraphQLSubscription, BaseQuery: GraphQLQuery, DeltaQuery: GraphQLQuery>: Cancellable {

    // Incoming configuration options
    private weak var appSyncClient: AWSAppSyncClient?
    private weak var subscriptionMetadataCache: AWSSubscriptionMetaDataCache?
    private weak var handlerQueue: DispatchQueue?

    // Incoming queries & handlers
    private var baseQuery: BaseQuery
    private var baseQueryHandler: OperationResultHandler<BaseQuery>

    private var subscription: Subscription?
    private var subscriptionHandler: SubscriptionResultHandler<Subscription>?

    private var deltaQuery: DeltaQuery?
    private var deltaQueryHandler: DeltaQueryResultHandler<DeltaQuery>?

    // Internal state
    private var syncStrategy: SyncStrategy
    private var subscriptionWatcher: AWSAppSyncSubscriptionWatcher<Subscription>?

    private var currentSyncAttempts = 0

    /// Serializes sync setup, query, and teardown operations to ensure a consistent ordering of invocations.
    private var internalStateSyncQueue: OperationQueue

    /// Serializes processing of subscription messages received from service to ensure we process them in the order they were
    /// received. Note that this queue is private to this subscription instance, and does not guarantee consistent ordering with
    /// other subscriptions.
    ///
    /// This property is lazily initialized to allow us to declare the result handler with a `weak self`
    /// in the capture list.
    private lazy var subscriptionMessagesQueue: SubscriptionMessagesQueue<Subscription> = {
        return SubscriptionMessagesQueue<Subscription>(for: getOperationHash()) { [weak self] (result, date, transaction) in
            self?.deliverSubscriptionResult(result: result, date: date, transaction: transaction)
        }
    }()

    private var nextSyncTimer: DispatchSourceTimer?

    internal init(appSyncClient: AWSAppSyncClient,
                  baseQuery: BaseQuery,
                  deltaQuery: DeltaQuery,
                  subscription: Subscription,
                  baseQueryHandler: @escaping OperationResultHandler<BaseQuery>,
                  deltaQueryHandler: @escaping DeltaQueryResultHandler<DeltaQuery>,
                  subscriptionResultHandler: @escaping SubscriptionResultHandler<Subscription>,
                  subscriptionMetadataCache: AWSSubscriptionMetaDataCache?,
                  syncConfiguration: SyncConfiguration,
                  handlerQueue: DispatchQueue) {
        self.appSyncClient = appSyncClient
        self.subscriptionMetadataCache = subscriptionMetadataCache
        self.handlerQueue = handlerQueue

        self.baseQuery = baseQuery
        self.baseQueryHandler = baseQueryHandler

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

        syncStrategy = SyncStrategy(
            hasDeltaQuery: self.deltaQuery != nil,
            baseRefreshIntervalInSeconds: syncConfiguration.baseRefreshIntervalInSeconds
        )

        internalStateSyncQueue = OperationQueue()
        internalStateSyncQueue.maxConcurrentOperationCount = 1
        internalStateSyncQueue.name = "AppSync.DeltaSyncOperationQueue.\(getOperationHash())"

        performInitialSync()
    }

    // MARK: - Cancellable

    /// Cancel the subscription sync. This releases all internal resources and unregisters for system notifications.
    ///
    /// Callers must invoke `cancel` on subscription sync in order to release resources. Failure to do so will cause
    /// memory leaks.
    func cancel() {
        // perform user-cancellation tasks, if any, then internal ones.
        internalCancel()
    }

    // MARK: - Setup

    private func performInitialSync() {
        AppSyncLog.debug("Queuing operations for initial sync")
        internalStateSyncQueue.addOperation {
            self.registerForNotifications()
            self.initializeLastSyncTimeFromCache()
            self.initializeBaseQueryResultsFromCache()
            self.performSync()
        }
    }

    // MARK: - Sync time

    /// Fetches last sync time from local cache and updates `syncStrategy` with the retrieved value
    private func initializeLastSyncTimeFromCache() {
        do {
            let lastSyncTime = try self.subscriptionMetadataCache?.getLastSyncTime(operationHash: getOperationHash())
            syncStrategy.lastSyncTime = lastSyncTime
            AppSyncLog.debug("Loaded lastSyncTime from cache: \(lastSyncTime.debugDescription)")
        } catch {
            // could not find it in cache, assume no sync was done previously
        }
    }

    /// Updates the last sync time and persists it to `subscriptionMetadataCache` if present. Expected to
    /// be called when subscription message is given to the caller, or if base query or delta query is run.
    ///
    /// - Parameters:
    ///   - date: The date at which the last sync was successfully performed
    private func setLastSyncTime(date: Date) {
        do {
            let adjustedDate = date.addingTimeInterval(TimeInterval.init(exactly: -2)!)
            AppSyncLog.debug("Updating lastSync time \(adjustedDate)")
            self.syncStrategy.lastSyncTime = adjustedDate
            try subscriptionMetadataCache?.updateLastSyncTime(for: getOperationHash(), with: adjustedDate)
        } catch {
            // ignore cache write failure, be updated in next operation, is backed up by in-memory cache
        }
    }

    // MARK: - Base query handling

    /// Load base query results from cache, to quickly provide callers with the most recent results
    private func initializeBaseQueryResultsFromCache() {
        guard let appSyncClient = appSyncClient else {
            return
        }

        let semaphore = DispatchSemaphore(value: 0)

        AppSyncLog.info("Initializing base query results from cache")
        appSyncClient.fetch(query: baseQuery, cachePolicy: .returnCacheDataDontFetch) { [weak self] (result, error) in
            self?.baseQueryHandler(result, error)
            semaphore.signal()
        }

        semaphore.wait()
    }

    /// Load base query results from service, forcing a bypass of the local cache
    private func runBaseQueryFromService() -> Bool {
        guard let appSyncClient = appSyncClient else {
            return false
        }

        var success = false

        AppSyncLog.info("Refreshing base query results from service")

        let semaphore = DispatchSemaphore(value: 0)

        let networkFetchTime = Date()

        appSyncClient.fetch(query: baseQuery, cachePolicy: .fetchIgnoringCacheData) { [weak self] (result, error) in

            defer {
                semaphore.signal()
            }

            guard let self = self else {
                return
            }

            success = error == nil && result != nil
            self.baseQueryHandler(result, error)
        }

        semaphore.wait()

        if success {
            AppSyncLog.debug("Base query refresh from service successful. Updating last sync time.")
            self.setLastSyncTime(date: networkFetchTime)
        }

        return success
    }

    // MARK: - Subscription handling

    /// Initializes a subscription listener for `subscription`. This method returns after either receiving
    /// a connect callback, or an errored result.
    ///
    /// - Returns: true if the subscription was successfully started, or if `subscription` is nil.
    private func startSubscription() -> Bool {
        var success: Bool? = nil
        guard let subscription = subscription, let appSyncClient = appSyncClient else {
            return true
        }

        AppSyncLog.info("Starting subscription")

        let semaphore = DispatchSemaphore(value: 0)

        var oldSubscriptionWatcher = subscriptionWatcher
        let connectCallback = {
            oldSubscriptionWatcher?.cancel()
            oldSubscriptionWatcher = nil

            // Guard against multiple invocations of the connect callback
            if success == nil {
                success = true
                semaphore.signal()
            }
        }

        let resultHandler: SubscriptionResultHandler<Subscription> = { [weak self] (result, transaction, error) in
            // `subscribeWithConnectCallback` invokes `resultHandler` with an error if it encounters an error
            // during the connect phase. Handle that here by updating the success flag and signalling the
            // semaphore to end the method.
            if error != nil {
                if success == nil {
                    semaphore.signal()
                    success = false
                }
            }
            self?.handleSubscriptionCallback(result, transaction, error)
        }

        do {
            subscriptionWatcher = try appSyncClient.subscribeWithConnectCallback(
                subscription: subscription,
                queue: handlerQueue ?? DispatchQueue.main,
                connectCallback: connectCallback,
                resultHandler: resultHandler
            )
        } catch {
            AppSyncLog.error("Error subscribing: \(error.localizedDescription)")
            handleSubscriptionCallback(nil, nil, error)
            success = false
            semaphore.signal()
        }

        semaphore.wait()

        return success == true
    }

    private func handleSubscriptionCallback(_ result: GraphQLResult<Subscription.Data>?, _ transaction: ApolloStore.ReadWriteTransaction?, _ error: Error?) {

        if let error = error as? AWSAppSyncSubscriptionError, error.additionalInfo == "Subscription Terminated." {
            // Do not give the developer a disconnect callback here. We have to retry the subscription once app
            // comes from background to foreground or internet becomes available.
            AppSyncLog.debug("Subscription terminated. Waiting for network to restart.")
            return
        }

        guard error == nil else {
            subscriptionHandler?(nil, nil, error)
            return
        }

        guard let result = result else {
            AppSyncLog.error("Unable to start subscription")
            return
        }

        subscriptionMessagesQueue.append(result, transaction: transaction)
    }

    /// Delivers a subscription result message to the caller
    private func deliverSubscriptionResult(result: GraphQLResult<Subscription.Data>, date: Date, transaction: ApolloStore.ReadWriteTransaction? = nil) {
        if let handlerQueue = handlerQueue, let subscriptionHandler = subscriptionHandler {
            if let transaction = transaction {
                handlerQueue.async {
                    subscriptionHandler(result, transaction, nil)
                }
            } else {
                do {
                    try appSyncClient?.store?.withinReadWriteTransaction { transaction in
                        handlerQueue.async {
                            subscriptionHandler(result, transaction, nil)
                        }
                    }.await()
                    setLastSyncTime(date: date)
                } catch {
                    handlerQueue.async {
                        subscriptionHandler(nil, nil, error)
                    }
                }
            }
        }
    }

    // MARK: - Delta query handling

    /// Runs the delta query based on the given criterias.
    ///
    /// - Returns: true if the operation is executed successfully, or if delta query is nil,
    /// or if the query has never been synced
    private func runDeltaQuery() -> Bool {
        guard let deltaQuery = deltaQuery else {
            return true
        }

        guard let networkTransport = appSyncClient?.httpTransport as? AWSAppSyncHTTPNetworkTransport else {
            AppSyncLog.error("Invalid network transport \(String(describing: appSyncClient?.httpTransport))")
            return false
        }

        var overrideMap: [String: Int] = [:]
        if let lastSyncTime = syncStrategy.lastSyncTime {
            AppSyncLog.debug("Using last sync time \(lastSyncTime.description)")
            overrideMap["lastSync"] = Int(lastSyncTime.timeIntervalSince1970)
        } else {
            AppSyncLog.error("No last sync time available--delta sync should not be invoked without first populating local data with base query")
        }

        let notifyResultHandler: OperationResultHandler<DeltaQuery> = { [weak self] (result, error) in
            guard let self = self else {
                return
            }

            if let error = error {
                AppSyncLog.error("Error in delta query result: \(error.localizedDescription)")
            } else {
                self.setLastSyncTime(date: Date())
            }

            guard let store = self.appSyncClient?.store else {
                return
            }

            _ = store.withinReadWriteTransaction { transaction in
                self.handlerQueue?.async {
                    self.deltaQueryHandler?(result, transaction, error)
                }
            }
        }

        AppSyncLog.info("Running Delta query")
        let semaphore = DispatchSemaphore(value: 0)

        _ = networkTransport.send(operation: deltaQuery, overrideMap: overrideMap) { [weak self] (response, error) in

            defer {
                semaphore.signal()
            }

            guard let self = self, let store = self.appSyncClient?.store else {
                return
            }

            guard let response = response else {
                notifyResultHandler(nil, error)
                return
            }

            // we have the parsing logic here to perform custom actions in cache,
            // e.g. if we receive a delete type event, we can remove it from store
            firstly {
                try response.parseResult(cacheKeyForObject: store.cacheKeyForObject)
            }
            .andThen { (result, records) in
                notifyResultHandler(result, nil)
                guard let records = records else {
                    return
                }
                store.publish(records: records, context: nil)
                    .catch { error in
                        preconditionFailure(error.localizedDescription)
                }
            }
            .catch { error in
                notifyResultHandler(nil, error)
            }
        }

        semaphore.wait()

        return true
    }

    /// Syncs local cached data from the service. Internally, this method:
    /// - Sets a flag to queue received subscription messages while it processes sync results
    /// - Sets up a new subscription listener
    /// - Performs either a partial (delta) query, or a full (base) query. Determining whether to perform
    ///   a delta or base query is the responsibility of `SyncStrategy`
    /// - See Also: SyncStrategy
    private func performSync() {
        AppSyncLog.debug("Starting sync")
        subscriptionMessagesQueue.stopDelivery()

        var isSyncOperationSuccessful = false

        let baseQueryDispatchTime = DispatchTime.now()
        
        // TODO: start subscription should happen outside initial delta sync setup. Depends on enhanced
        // subscription state tracking
        guard startSubscription() else {
            return
        }

        defer {
            subscriptionMessagesQueue.startDelivery()
            scheduleNextSync(from: baseQueryDispatchTime, lastSyncWasSuccessful: isSyncOperationSuccessful)
        }

        // If within time frame, fetch using delta query.
        // If lastSyncTime or deltaQuery not available, run base query.
        let syncMethodToUse = syncStrategy.methodToUseForSync

        if case .partial = syncMethodToUse {
            // If we ran baseQuery in this iteration of sync, we do not run the delta query
            guard runDeltaQuery() else {
                currentSyncAttempts += 1
                return
            }
        } else {
            guard runBaseQueryFromService() else {
                currentSyncAttempts += 1
                return
            }
        }
        
        isSyncOperationSuccessful = true
        currentSyncAttempts = 0
    }

    /// Schedules the next sync with a delay after the last sync was started, based on whether the last sync was
    /// successful or not.
    ///
    /// - Parameters:
    ///   - lastSyncStartTime: The time at which the last sync started
    ///   - lastSyncWasSuccessful: `true` if the last sync was successful, false otherwise.
    ///     A `false` value will cause the next sync to be scheduled using an exponential backoff strategy
    private func scheduleNextSync(from lastSyncStartTime: DispatchTime, lastSyncWasSuccessful: Bool) {
        let interval: DispatchTimeInterval
        if lastSyncWasSuccessful {
            AppSyncLog.debug("Setting up baseQuery timer")
            interval = syncStrategy.baseRefreshIntervalInSeconds.asDispatchTimeInterval
        } else {
            AppSyncLog.debug("Setting up retry timer")
            let delayForCurrentAttempt = AWSAppSyncRetryHandler.retryDelayInMillseconds(for: currentSyncAttempts)
            let delay = min(delayForCurrentAttempt, AWSAppSyncRetryHandler.maxWaitMilliseconds)
            interval = .milliseconds(delay)
        }
        let deadline = lastSyncStartTime + interval
        performSync(at: deadline)
    }

    /// Sets `self.nextSyncTimer` to perform a sync at `deadline`
    ///
    /// - Parameters:
    ///   - deadline: The time to perform the sync
    private func performSync(at deadline: DispatchTime) {
        // Invalidate existing time and restart again
        nextSyncTimer?.cancel()

        guard let handlerQueue = handlerQueue else {
            return
        }

        nextSyncTimer = makeOneOffDispatchSourceTimer(deadline: deadline, queue: handlerQueue) {
            AppSyncLog.debug("Timer fired, queueing sync operation")
            self.internalStateSyncQueue.addOperation {
                AppSyncLog.debug("Perform sync queued by timer")
                self.performSync()
            }
        }

        nextSyncTimer?.resume()
    }

    /// Convenience function to encapsulate creation of a one-off DispatchSourceTimer for different versions of Swift
    /// - Parameters:
    ///   - deadline: The time to fire the timer
    ///   - queue: The queue on which the timer should perform its block
    ///   - block: The block to invoke when the timer is fired
    private func makeOneOffDispatchSourceTimer(deadline: DispatchTime, queue: DispatchQueue, block: @escaping () -> Void ) -> DispatchSourceTimer {
        let timer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: 0), queue: queue)
        #if swift(>=4)
        timer.schedule(deadline: deadline)
        #else
        timer.scheduleOneshot(deadline: deadline)
        #endif
        timer.setEventHandler(handler: block)
        return timer
    }

    /// This function generates a unique identifier hash for the combination of specified parameters in the
    /// supplied GraphQL operations. The hash is always same for the same set of operations.
    /// - Returns: The unique hash for the specified queries & subscription.
    private func getOperationHash() -> String {
        
        var baseString = ""
        
        let variables = baseQuery.variables?.description ?? ""
        baseString = type(of: baseQuery).requestString + variables

        if let subscription = subscription {
            let variables = subscription.variables?.description ?? ""
            baseString = type(of: subscription).requestString + variables
        }
        
        if let deltaQuery = deltaQuery {
            let variables = deltaQuery.variables?.description ?? ""
            baseString = type(of: deltaQuery).requestString + variables
        }
        
        return AWSSignatureSignerUtility.hash(baseString.data(using: .utf8)!)!.base64EncodedString()
    }
    
    deinit {
        internalCancel()
        // Defensively remove from any remaining notifications, but this should have already been handled in
        // `unregisterForNotifications()`
        NotificationCenter.default.removeObserver(self)
    }

    /// Cancels and releases the subscription watcher, cancels active timers, and unregisters for system notifications. After
    /// invoking this method, the instance will be eligible for release.
    private func internalCancel() {
        unregisterForNotifications()
        nextSyncTimer?.cancel()
        subscriptionWatcher?.cancel()
        subscriptionWatcher = nil
    }

    // MARK: - Notifications

    /// Registers for notifications to resume sync after lifecycle or network reachability events
    private func registerForNotifications() {
        AppSyncLog.debug("Registering for notifications")
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(AppSyncSubscriptionWithSync.applicationWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(AppSyncSubscriptionWithSync.didConnectivityChange(notification:)),
            name: .appSyncReachabilityChanged,
            object: nil
        )
    }

    private func unregisterForNotifications() {
        AppSyncLog.debug("Unregistering for notifications")
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: .appSyncReachabilityChanged, object: nil)
    }

    @objc private func applicationWillEnterForeground() {
        // perform delta sync here
        // disconnect from sub and reconnect
        self.internalStateSyncQueue.addOperation {
            AppSyncLog.debug("App entered foreground, syncing")
            self.performSync()
        }
    }

    @objc private func didConnectivityChange(notification: Notification) {
        // If internet was disconnected and is available now, perform deltaSync
        let connectionInfo = notification.object as! AppSyncConnectionInfo

        if connectionInfo.isConnectionAvailable {
            self.internalStateSyncQueue.addOperation {
                AppSyncLog.debug("Network connectivity restored, syncing")
                self.performSync()
            }
        }
    }

}
