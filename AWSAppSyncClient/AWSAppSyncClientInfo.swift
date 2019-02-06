//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

/**
 * Configuration for AWSAppSyncClient as read from `awsconfiguration.json`
 */
@available(*, deprecated, message: "Use a AWSAppSyncServiceConfigProviding instance like AWSAppSyncServiceConfig")
public class AWSAppSyncClientInfo {
    public let apiUrl: String
    public let region: String
    public let authType: String
    public let apiKey: String

    /// Reads configuration from `awsconfiguration.json` using the supplied key. If no key is supplied, reads configuration from
    /// "Default".
    ///
    /// - Parameter key: The key from which to read the configuration values. Defaults to "Default"
    /// - Throws: AWSAppSyncClientInfoError if the `awsconfiguration.json` file cannot be read, if the "AppSync" configuration
    ///   is not present, or if the configuration is not valid.
    public init(forKey key: String = "Default") throws {
        do {
            let info = try AWSAppSyncServiceConfig(forKey: key)
            apiUrl = info.endpoint.absoluteString
            region = try AWSAppSyncClientInfo.getRawRegionStringFromConfigFile(forKey: key)
            authType = info.authType.rawValue
            apiKey = info.apiKey ?? ""
        } catch AWSAppSyncServiceConfigError.invalidConfigFile {
            // Re-throw as AWSAppSyncClientInfoError
            throw AWSAppSyncClientInfoError(errorMessage: "Cannot read configuration from \(AWSConfigurationFile.fileName)")
        } catch AWSAppSyncServiceConfigError.invalidAPIKey {
            // Re-throw as AWSAppSyncClientInfoError
            throw AWSAppSyncClientInfoError(errorMessage: "\(AWSAppSyncAuthType.apiKey.rawValue) AuthMode found in configuration but a valid \(AWSConfigurationFile.Keys.apiKey) is not found")
        }
    }

    /// A utility method to get the raw value of the `region` string from the `awsconfiguration.json` file. This is provided
    /// only for backwards-compatibility with the AWSAppSyncClientInfo.region API; consumers of client info use AWSRegionType
    /// values.
    ///
    /// - Parameter key: The key from which to read the configuration values. Defaults to "Default"
    /// - Throws: AWSAppSyncClientInfoError if the `awsconfiguration.json` file cannot be read, if the "AppSync" configuration
    ///   is not present, or if the configuration is not valid.
    private static func getRawRegionStringFromConfigFile(forKey key: String) throws -> String {
        let info = AWSInfo.default()

        guard
            let config = info.rootInfoDictionary[AWSConfigurationFile.Keys.root] as? [String: Any],
            let configForKey = config[key] as? [String: Any]
            else {
                throw AWSAppSyncClientInfoError(errorMessage: "Cannot read configuration from \(AWSConfigurationFile.fileName)")
        }

        guard
            let regionString = configForKey[AWSConfigurationFile.Keys.region] as? String
            else {
                throw AWSAppSyncClientInfoError(errorMessage: "Cannot read \(AWSConfigurationFile.Keys.region) from \(AWSConfigurationFile.fileName)")
        }

        return regionString
    }
}
