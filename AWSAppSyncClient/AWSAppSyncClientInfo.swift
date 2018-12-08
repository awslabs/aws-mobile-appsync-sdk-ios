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

public struct AWSAppSyncClientInfoError: Error, LocalizedError {

    public let errorMessage: String?

    // MARK: LocalizedError

    public var errorDescription: String? {
        return errorMessage
    }
}

private let configFileName = "awsconfiguration.json"

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
            throw AWSAppSyncClientInfoError(errorMessage: "Cannot read configuration from the \(configFileName)")
        }

        guard
            let apiURLString = configForKey["ApiUrl"] as? String,
            let apiURL = URL(string: apiURLString)
        else {
            throw AWSAppSyncClientInfoError(errorMessage: "Cannot read ApiUrl from the \(configFileName)")
        }

        guard
            let authTypeRawValue = configForKey["AuthMode"] as? String,
            let authType = AppSyncAuthType(rawValue: authTypeRawValue)
        else {
            throw AWSAppSyncClientInfoError(errorMessage: "Cannot read AuthMode from the \(configFileName)")
        }

        guard
            let regionString = configForKey["Region"] as? String else {
            throw AWSAppSyncClientInfoError(errorMessage: "Cannot read Region from the \(configFileName)")
        }

        self.apiURL = apiURL
        self.region = regionString.aws_regionTypeValue()
        self.authType = authType
        self.apiKey = configForKey["ApiKey"] as? String
    }
}
