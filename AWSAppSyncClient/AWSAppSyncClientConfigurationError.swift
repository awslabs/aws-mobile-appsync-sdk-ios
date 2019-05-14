//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

public enum AWSAppSyncClientConfigurationError {
    case invalidAuthConfiguration(String)
    case cacheConfigurationAlreadyInUse(String)
}

extension AWSAppSyncClientConfigurationError: Error {
    var localizedDescription: String {
        return errorDescription ?? String(describing: self)
    }
}

extension AWSAppSyncClientConfigurationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidAuthConfiguration(let message):
            return "Invalid Auth Configuration: \(message)"
        case .cacheConfigurationAlreadyInUse(let message):
            return "Cache Configuration Already In Use: \(message)"
        }
    }
}
