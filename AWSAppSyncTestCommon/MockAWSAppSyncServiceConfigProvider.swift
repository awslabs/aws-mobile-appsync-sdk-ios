//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
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
