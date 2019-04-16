//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

/// This class is responsible to create a timer and watch for network up events and
/// retry the mutation when the timer expires or network up event is received.
/// Note: -  This class can also be used by `sync` to watch for network events and back-off based on timer in future.
final class AWSMutationRetryNotifier: Cancellable {
    private var nextSyncTimer: DispatchSourceTimer?
    private var retryAttemptNumber: Int
    private var retryStrategy: AWSAppSyncRetryStrategy = .exponential
    /// Ensures ordered callback of retry notification dispatch in case of multiple attempts.
    private var retryOperationQueue: OperationQueue
    private var handlerQueue: DispatchQueue = DispatchQueue.global(qos: .utility)
    // callback to the operation to perform the mutation from part where its failed.
    var retrySignalCallback: () -> Void
    
    init(retryAttemptNumber: Int,
         retrySignalCallback: @escaping () -> Void) {
        self.retryAttemptNumber = retryAttemptNumber
        self.retrySignalCallback = retrySignalCallback
        
        retryOperationQueue = OperationQueue()
        retryOperationQueue.maxConcurrentOperationCount = 1
        retryOperationQueue.name = "com.amazonaws.service.appsync.retryoperationqueue"
        
        //  Enable notification for reachability.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(AWSMutationRetryNotifier.didConnectivityChange(notification:)),
            name: .appSyncReachabilityChanged,
            object: nil
        )
        
        // Start timer as well for retrying  mutation.
        // The timer is started on the operation queue to avoid any potential data races in the requester.
        retryOperationQueue.addOperation {
            let delayForCurrentAttempt = AWSAppSyncRetryHandler.retryDelayInMillseconds(for: retryAttemptNumber, retryStrategy: self.retryStrategy)
            // Either follow the advice from retry strategy or fallback to max wait.
            let delay = min(delayForCurrentAttempt, AWSAppSyncRetryHandler.maxWaitMilliseconds)
            let interval: DispatchTimeInterval = .milliseconds(delay)
            let deadline = DispatchTime.now() + interval
            self.scheduleTimer(at: deadline)
        }
        
    }
    
    deinit {
        cancel()
        // Defensively remove from any remaining notifications, but this should have already been handled in
        // `unregisterForNotifications()`
        NotificationCenter.default.removeObserver(self)
    }
    
    private func scheduleTimer(at deadline: DispatchTime) {
        let currentRetryNumber = self.retryAttemptNumber
        nextSyncTimer = DispatchSource.makeOneOffDispatchSourceTimer(deadline: deadline, queue: handlerQueue) {
            AppSyncLog.debug("Timer fired, attempting mutation operation. Retry number: \(currentRetryNumber)")
            self.retryOperationQueue.addOperation {
                self.notifyCallback()
            }
        }
        
        nextSyncTimer?.resume()
    }
    
    private func unregisterForNotifications() {
        AppSyncLog.debug("Unregistering for notifications")
        NotificationCenter.default.removeObserver(self, name: .appSyncReachabilityChanged, object: nil)
    }
    
    func cancel() {
        unregisterForNotifications()
        nextSyncTimer?.cancel()
    }
    
    func notifyCallback() {
        // Call the cancel routine as the purpose of retry is fulfilled
        cancel()
        retrySignalCallback()
    }
    
    @objc private func didConnectivityChange(notification: Notification) {
        // If internet was disconnected and is available now, perform mutation
        let connectionInfo = notification.object as! AppSyncConnectionInfo
        
        if connectionInfo.isConnectionAvailable {
            AppSyncLog.debug("Connection state updated, attempting mutation operation. Retry number: \(retryAttemptNumber)")
            retryOperationQueue.addOperation {
                self.notifyCallback()
            }
        }
    }
}
