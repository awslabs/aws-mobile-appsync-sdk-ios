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

/// Describes the shape of the 'AppSync' section of the `awsconfiguration.json` file
struct AWSConfigurationFile {
    static let fileName = "awsconfiguration.json"

    struct Keys {
        /// The root of the AppSync configuration section
        static let root = "AppSync"

        /// The endpoint URL for the AppSync API described by this configuration
        static let apiURL = "ApiUrl"

        /// The AWS region of the AppSync API. The value must be a string that can be resolved to an `AWSRegionType`
        static let region = "Region"

        /// The Auth mode of the API. The value must be a string that is a raw value of the `AWSAppSyncAuthType` enum
        static let authMode = "AuthMode"

        /// If the `authMode` value is "API_KEY", this value should be filled in with a valid value. If not, then the AppSync
        /// constructors must be provided with an already-configured apiKeyProvider.
        static let apiKey = "ApiKey"
    }
}
