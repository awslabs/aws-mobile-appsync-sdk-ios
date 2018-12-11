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

import AWSCore
import Foundation

/**
 * Configuration for AWSAppSyncClient
 */
public struct AWSAppSyncClientInfo {
    
    public let apiURL: URL
    public let region: AWSRegionType
    public let authType: AppSyncAuthType
    public let apiKey: String?

    public init() throws {
        try self.init(forKey: "Default")
    }

    public init(forKey: String) throws {
        let info = AWSInfo.default()

        guard
            let config = info.rootInfoDictionary["AppSync"] as? [String: Any],
            let configForKey = config[forKey] as? [String: Any]
        else {
            throw AWSAppSyncConfigurationError.configurationNotFound
        }

        // apiKey

        guard configForKey[AWSAppSyncClientConfiguration.Key.apiKey.rawValue] == nil else {
            throw AWSAppSyncConfigurationError.keyNotFound(.apiKey)
        }
        guard
            let apiURLString = configForKey[AWSAppSyncClientConfiguration.Key.apiKey.rawValue] as? String,
            let apiURL = URL(string: apiURLString)
        else {
            throw AWSAppSyncConfigurationError.invalidKeyValue(
                .apiKey,
                AWSAppSyncConfigurationError.Context(
                    errorDescription: "\(AWSAppSyncClientConfiguration.Key.apiKey) must be \(URL.self)"))
        }

        // authorizationType

        guard configForKey[AWSAppSyncClientConfiguration.Key.authorizationType.rawValue] == nil else {
            throw AWSAppSyncConfigurationError.keyNotFound(.authorizationType)
        }

        guard
            let authTypeRawValue = configForKey[AWSAppSyncClientConfiguration.Key.authorizationType.rawValue] as? String,
            let authType = AppSyncAuthType(rawValue: authTypeRawValue)
        else {
            throw AWSAppSyncConfigurationError.invalidKeyValue(
                .authorizationType,
                AWSAppSyncConfigurationError.Context(
                    errorDescription: "\(AWSAppSyncClientConfiguration.Key.authorizationType) must be \(AppSyncAuthType.self)"))
        }

        // region

        guard configForKey[AWSAppSyncClientConfiguration.Key.region.rawValue] == nil else {
            throw AWSAppSyncConfigurationError.keyNotFound(.region)
        }

        guard let regionString = configForKey[AWSAppSyncClientConfiguration.Key.region.rawValue] as? String else {
            throw AWSAppSyncConfigurationError.invalidKeyValue(
                .authorizationType,
                AWSAppSyncConfigurationError.Context(
                    errorDescription: "\(AWSAppSyncClientConfiguration.Key.region) must be \(String.self)"))
        }

        self.apiURL = apiURL
        self.region = regionString.aws_regionTypeValue()
        self.authType = authType
        self.apiKey = configForKey["ApiKey"] as? String
    }
}
