//
//  AppSyncClientTestConfigurationDefaults.swift
//  AWSAppSyncTests
//
//  Created by Schmelter, Tim on 12/11/18.
//  Copyright © 2018 Amazon Web Services. All rights reserved.
//

import Foundation
import AWSCore

// Override these defaults if you are not using the `AppSyncTests/appsync_test_credentials.json` file to manage your
// test client configuration.
//
// Note: You must either provide all values in the `AppSyncTests/appsync_test_credentials.json` or in this
// structure. There is no mechanism to handle partial overrides of one source with the other. All values must be
// specified before running the functional tests.
struct AppSyncClientTestConfigurationDefaults {

    // MARK: - Values used for API Key-based tests

    // Equivalent to the JSON key "AppSyncAPIKey"
    static let apiKey = "YOUR_API_KEY"

    // Equivalent to the JSON key "AppSyncEndpointAPIKey"
    static let apiKeyEndpointURL = URL(string: "https://localhost")!

    // Equivalent to the JSON key "AppSyncEndpointAPIKeyRegion"
    static let apiKeyEndpointRegion = AWSRegionType.USEast1

    // MARK: - Values used for IAM-based tests

    // Equivalent to the JSON key "CognitoIdentityPoolId"
    static let cognitoPoolId = "YOUR_POOL_ID"

    // Equivalent to the JSON key "CognitoIdentityPoolRegion"
    static let cognitoPoolRegion = AWSRegionType.USEast1

    // Equivalent to the JSON key "AppSyncEndpoint"
    static let cognitoPoolEndpointURL = URL(string: "https://localhost")!

    // Equivalent to the JSON key "AppSyncRegion"
    static let cognitoPoolEndpointRegion = AWSRegionType.USEast1
}
