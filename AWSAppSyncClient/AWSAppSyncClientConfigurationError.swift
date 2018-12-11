//
//  AWSAppSyncClientConfigurationError.swift
//  AWSAppSync
//
//  Created by Ilya Laryionau on 11/12/2018.
//  Copyright © 2018 Dubal, Rohan. All rights reserved.
//

import Foundation

public enum AWSAppSyncConfigurationError: Error {

    public struct Context {
        public let errorDescription: String?

        public init(
            errorDescription: String? = nil) {
            self.errorDescription = errorDescription
        }
    }

    case configurationNotFound
    case insufficientParams(
        AWSAppSyncClientConfiguration.Key, AWSAppSyncConfigurationError.Context)
    case invalidKeyValue(
        AWSAppSyncClientConfiguration.Key, AWSAppSyncConfigurationError.Context)
    case keyNotFound(AWSAppSyncClientConfiguration.Key)
}

// MARK: - LocalizedError

extension AWSAppSyncConfigurationError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .configurationNotFound:
            return "Cannot read AppSync configuration from the awsconfiguration.json"
        case let .insufficientParams(_, context):
            return context.errorDescription
        case let .invalidKeyValue(_, context):
            return context.errorDescription
        case let .keyNotFound(key):
            return "\(key) not found in AppSync configuration"
        }
    }
}
