//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Starscream

extension AppSyncSubscriptionConnection {
    func handleError(error: Error) {
        guard let subscriptionItem = subscriptionItem else {
            AppSyncLogger.warn("[AppSyncSubscriptionConnection] \(#function): missing subscription item")
            return
        }

        // If the error identifier is not for the this subscription
        // we return immediately without handling the error.
        if case let ConnectionProviderError.subscription(identifier, _) = error,
            identifier != subscriptionItem.identifier {
            return
        }
        if case let ConnectionProviderError.limitExceeded(identifier) = error, identifier != subscriptionItem.identifier {
            return
        }

        AppSyncSubscriptionConnection.logExtendedErrorInfo(for: error)

        subscriptionState = .notSubscribed
        guard let retryHandler = retryHandler,
            let connectionError = error as? ConnectionProviderError
        else {
            subscriptionItem.subscriptionEventHandler(.failed(error), subscriptionItem)
            connectionProvider?.removeListener(identifier: subscriptionItem.identifier)
            return
        }

        let retryAdvice = retryHandler.shouldRetryRequest(for: connectionError)
        if retryAdvice.shouldRetry, let retryInterval = retryAdvice.retryInterval {
            AppSyncLogger.debug("[AppSyncSubscriptionConnection] Retrying subscription \(subscriptionItem.identifier) after \(retryInterval)")
            DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval) {
                self.connectionProvider?.connect()
            }
        } else {
            subscriptionItem.subscriptionEventHandler(.failed(error), subscriptionItem)
            connectionProvider?.removeListener(identifier: subscriptionItem.identifier)
        }
    }

    public static func logExtendedErrorInfo(for error: Error) {
        switch error {
        case let typedError as ConnectionProviderError:
            logExtendedErrorInfo(for: typedError)
        case let typedError as WSError:
            logExtendedErrorInfo(for: typedError)
        case let typedError as NSError:
            logExtendedErrorInfo(for: typedError)
        default:
            AppSyncLogger.error(error)
        }
    }

    private static func logExtendedErrorInfo(for error: ConnectionProviderError) {
        switch error {
        case .connection:
            AppSyncLogger.error("ConnectionProviderError.connection")
        case .jsonParse(let identifier, let underlyingError):
            AppSyncLogger.error(
                """
                ConnectionProviderError.jsonParse; \
                identifier=\(identifier ?? "(N/A)"); \
                underlyingError=\(underlyingError?.localizedDescription ?? "(N/A)")
                """
            )
        case .limitExceeded(let identifier):
            AppSyncLogger.error(
                """
                ConnectionProviderError.limitExceeded; \
                identifier=\(identifier ?? "(N/A)");
                """
            )
        case .subscription(let identifier, let errorPayload):
            AppSyncLogger.error(
                """
                ConnectionProviderError.jsonParse; \
                identifier=\(identifier); \
                additionalInfo=\(String(describing: errorPayload))
                """
            )
        case .other:
            AppSyncLogger.error("ConnectionProviderError.other")
        }
    }

    private static func logExtendedErrorInfo(for error: WSError) {
        AppSyncLogger.error(error)
    }

    private static func logExtendedErrorInfo(for error: NSError) {
        AppSyncLogger.error(
            """
            NSError:\(error.domain); \
            code:\(error.code); \
            userInfo:\(error.userInfo)
            """
        )
    }

}

extension WSError: CustomStringConvertible {
    public var description: String {
        """
        WSError:\(message); \
        code:\(code); \
        type:\(type)
        """
    }
}
