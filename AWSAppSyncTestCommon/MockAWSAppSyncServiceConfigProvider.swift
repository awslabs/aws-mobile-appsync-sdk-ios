//
// Copyright 2010-2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

@testable import AWSAppSync

struct MockAWSAppSyncServiceConfigProvider: AWSAppSyncServiceConfigProvider {
    public let endpoint: URL
    public let region: AWSRegionType
    public let authType: AWSAppSyncAuthType
    public let apiKey: String?

    init(endpoint: URL,
         region: AWSRegionType,
         authType: AWSAppSyncAuthType,
         apiKey: String?) {
        self.endpoint = endpoint
        self.region = region
        self.authType = authType
        self.apiKey = apiKey
    }

    /// Convenience initializer to return a service config for APIKey auth
    init(with testConfiguration: AppSyncClientTestConfiguration) {
        self.endpoint = testConfiguration.apiKeyEndpointURL
        self.region = testConfiguration.apiKeyEndpointRegion
        self.authType = .apiKey
        self.apiKey = testConfiguration.apiKey
    }
}
