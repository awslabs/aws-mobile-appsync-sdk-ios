//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
@testable import AWSAppSync

public struct MockAWSAppSyncServiceConfig: AWSAppSyncServiceConfigProvider {
    public let endpoint: URL
    public let region: AWSRegionType
    public let authType: AWSAppSyncAuthType
    public let apiKey: String?
    public let clientDatabasePrefix: String?

    init(endpoint: URL,
         region: AWSRegionType,
         authType: AWSAppSyncAuthType,
         apiKey: String? = nil,
         clientDatabasePrefix: String? = nil) {
        self.endpoint = endpoint
        self.region = region
        self.authType = authType
        self.apiKey = apiKey
        self.clientDatabasePrefix = clientDatabasePrefix
    }
}
