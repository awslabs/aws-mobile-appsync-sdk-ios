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

public protocol AWSAppSyncClientInfoProviding {
    var apiUrl: String { get }
    var region: String { get }
    var authType: String { get }
    var apiKey: String { get }
}

/**
 * Configuration for AWSAppSyncClient as read from `awsconfiguration.json`
 */
public class AWSAppSyncClientInfo: AWSAppSyncClientInfoProviding {
    private struct ConfigFileKeys {
        static let root = "AppSync"
        static let apiURL = "ApiUrl"
        static let region = "Region"
        static let authMode = "AuthMode"
        static let apiKey = "ApiKey"
    }

    public let apiUrl: String
    public let region: String
    public let authType: String
    public let apiKey: String

    /// Reads configuration from `awsconfiguration.json` using the supplied key. If no key is supplied, reads configuration from
    /// "Default".
    ///
    /// - Parameter key: The key from which to read the configuration values. Defaults to "Default"
    /// - Throws: AWSAppSyncCLientInfoError if the `awsconfiguration.json` file cannot be read, if the "AppSync" configuration
    ///   is not present, or if the configuration is not valid.
    public init(forKey key: String = "Default") throws {
        if AWSInfo.default().rootInfoDictionary[ConfigFileKeys.root] == nil {
            throw AWSAppSyncClientInfoError(errorMessage: "Cannot read configuration from awsconfiguration.json")
        }

        let appSyncConfig: [String: Any] = (AWSInfo.default().rootInfoDictionary[ConfigFileKeys.root] as? [String: Any])!
        let configForKey: [String: Any] = (appSyncConfig[key] as? [String: Any])!

        apiUrl = configForKey[ConfigFileKeys.apiURL] as! String
        region = configForKey[ConfigFileKeys.region] as! String
        authType = configForKey[ConfigFileKeys.authMode] as! String
        apiKey = configForKey[ConfigFileKeys.apiKey] as? String ?? ""

        guard authType != AuthType.apiKey.rawValue || !apiKey.isEmpty else {
            throw AWSAppSyncClientInfoError(errorMessage: "\(AuthType.apiKey.rawValue) AuthMode found in configuration but a valid \(ConfigFileKeys.apiKey) is not found")
        }
    }
}

public struct AWSAppSyncClientInfoError: Error, LocalizedError {
    public let errorMessage: String?

    public var errorDescription: String? {
        return errorMessage
    }
}
