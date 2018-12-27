//
// Copyright 2010-2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
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
