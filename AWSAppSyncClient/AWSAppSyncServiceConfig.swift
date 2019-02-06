//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

/// Client-side configurations of an AWSAppSync service instance
public protocol AWSAppSyncServiceConfigProvider {
    /// The API endpoint
    var endpoint: URL { get }

    /// The AWS region of the API endpoint
    var region: AWSRegionType { get }

    /// The authentication method used to access the API. If this value is `.apiKey`, then the config must also provide a value
    /// for `apiKey`
    var authType: AWSAppSyncAuthType { get }

    /// If `authType` is `.apiKey`, this value must provided
    var apiKey: String? { get }
}

/// Client-side configurations of an AWSAppSync service instance
public struct AWSAppSyncServiceConfig: AWSAppSyncServiceConfigProvider {
    public let endpoint: URL
    public let region: AWSRegionType
    public let authType: AWSAppSyncAuthType
    public let apiKey: String?

    /// Reads configuration from `awsconfiguration.json` using the supplied key. If no key is supplied, reads configuration from
    /// "Default".
    ///
    /// - Parameter key: The key from which to read the configuration values. Defaults to "Default"
    /// - Throws: AWSAppSyncClientInfoError if the `awsconfiguration.json` file cannot be read, if the "AppSync" configuration
    ///   is not present, or if the configuration is not valid.
    public init(forKey key: String = "Default") throws {
        let info = AWSInfo.default()

        guard
            let config = info.rootInfoDictionary[AWSConfigurationFile.Keys.root] as? [String: Any],
            let configForKey = config[key] as? [String: Any]
            else {
                throw AWSAppSyncServiceConfigError.invalidConfigFile
        }

        guard
            let apiURLString = configForKey[AWSConfigurationFile.Keys.apiURL] as? String,
            let endpoint = URL(string: apiURLString)
            else {
                throw AWSAppSyncServiceConfigError.invalidAPIURL
        }
        self.endpoint = endpoint

        guard
            let regionString = configForKey[AWSConfigurationFile.Keys.region] as? String
            else {
                throw AWSAppSyncServiceConfigError.invalidRegion
        }
        self.region = regionString.aws_regionTypeValue()

        guard
            let authTypeRawValue = configForKey[AWSConfigurationFile.Keys.authMode] as? String,
            let authType = AWSAppSyncAuthType(rawValue: authTypeRawValue)
            else {
                throw AWSAppSyncServiceConfigError.invalidAuthMode
        }
        self.authType = authType

        apiKey = configForKey[AWSConfigurationFile.Keys.apiKey] as? String

        guard authType != AWSAppSyncAuthType.apiKey || !apiKey.isEmpty else {
            throw AWSAppSyncServiceConfigError.invalidAPIKey
        }
    }
}
