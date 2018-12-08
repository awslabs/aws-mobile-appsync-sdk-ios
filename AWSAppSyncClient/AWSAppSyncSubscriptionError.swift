//
//  AWSAppSyncSubscriptionError.swift
//  AWSAppSync
//
//  Created by Ilya Laryionau on 08/12/2018.
//  Copyright © 2018 Dubal, Rohan. All rights reserved.
//

import Foundation

public struct AWSAppSyncSubscriptionError: Error, LocalizedError {
    let additionalInfo: String?
    let errorDetails: [String: String]?

    // MARK: LocalizedError

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
