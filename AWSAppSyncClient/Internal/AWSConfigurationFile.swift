//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
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

        /// This prefix is used to partition the caches and on-disk stores used by the client. Changing this value will
        /// orphan resources created by previous instances of the client.
        static let clientDatabasePrefix = "ClientDatabasePrefix"
    }
}
