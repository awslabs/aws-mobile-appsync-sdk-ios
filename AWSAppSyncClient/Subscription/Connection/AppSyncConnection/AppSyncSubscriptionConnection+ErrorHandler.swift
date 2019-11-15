//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

extension AppSyncSubscriptionConnection {

    func handleError(error: Error) {
        // If the error identifier is not for the this connection
        // we return immediately without handling the error.
        if case let ConnectionProviderError.subscription(identifier, _) = error,
            identifier != subscriptionItem.identifier {
            return
        }
        AppSyncLog.error(error)
        subscriptionState = .notSubscribed
        guard let retryHandler = retryHandler,
            let connectionError = error as? ConnectionProviderError  else {
                subscriptionItem.subscriptionEventHandler(.failed(error), subscriptionItem)
                return
        }

        let retryAdvice = retryHandler.shouldRetryRequest(for: connectionError)
        if retryAdvice.shouldRetry, let retryInterval = retryAdvice.retryInterval {
            AppSyncLog.debug("Retrying subscription \(subscriptionItem.identifier) after \(retryInterval)")
            DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval) {
                self.connectionProvider?.connect()
            }
        } else {
            subscriptionItem.subscriptionEventHandler(.failed(error), subscriptionItem)
        }
    }
}
