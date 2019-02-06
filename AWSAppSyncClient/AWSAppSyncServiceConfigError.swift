//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

public enum AWSAppSyncServiceConfigError: String {
    /// An error occurred reading the configuration file, or the file did not contain a properly configured "AppSync" section
    case invalidConfigFile

    /// An error occurred loading the API endpoing URL
    case invalidAPIURL

    /// An error occurred loading the API region
    case invalidRegion

    /// An error occurred loading the auth mode
    case invalidAuthMode

    /// AuthMode was set to "API_KEY" but a valid value for API_KEY was not found
    case invalidAPIKey
}

extension AWSAppSyncServiceConfigError: Error {
    public var localizedDescription: String {
        return errorDescription ?? self.rawValue
    }
}

extension AWSAppSyncServiceConfigError: LocalizedError {
    public var errorDescription: String? {
        return self.rawValue
    }
}
