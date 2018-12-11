//
//  AppSyncClientTestConfiguration.swift
//  AWSAppSyncTests
//
//  Created by Schmelter, Tim on 12/5/18.
//  Copyright © 2018 Amazon Web Services. All rights reserved.
//

import Foundation
import AWSAppSync
import AWSCore

struct AppSyncClientTestConfiguration {
    private struct JSONKeys {
        static let apiKey = "AppSyncAPIKey"
        static let apiKeyEndpointURL = "AppSyncEndpointAPIKey"
        static let apiKeyEndpointRegion = "AppSyncEndpointAPIKeyRegion"

        static let cognitoPoolId = "CognitoIdentityPoolId"
        static let cognitoPoolRegion = "CognitoIdentityPoolRegion"
        static let cognitoPoolEndpointURL = "AppSyncEndpoint"
        static let cognitoPoolEndpointRegion = "AppSyncRegion"
    }

    let apiKey: String
    let apiKeyEndpointURL: URL
    let apiKeyEndpointRegion: AWSRegionType

    let cognitoPoolId: String
    let cognitoPoolRegion: AWSRegionType
    let cognitoPoolEndpointURL: URL
    let cognitoPoolEndpointRegion: AWSRegionType

    var isValid: Bool {
        return apiKey != "YOUR_API_KEY"
            && apiKeyEndpointURL.absoluteString != "https://localhost"
            && cognitoPoolId != "YOUR_POOL_ID"
            && cognitoPoolEndpointURL.absoluteString != "https://localhost"
    }

    init() {
        apiKey = AppSyncClientTestConfigurationDefaults.apiKey
        apiKeyEndpointURL = AppSyncClientTestConfigurationDefaults.apiKeyEndpointURL
        apiKeyEndpointRegion = AppSyncClientTestConfigurationDefaults.apiKeyEndpointRegion

        cognitoPoolId = AppSyncClientTestConfigurationDefaults.cognitoPoolId
        cognitoPoolRegion = AppSyncClientTestConfigurationDefaults.cognitoPoolRegion
        cognitoPoolEndpointURL = AppSyncClientTestConfigurationDefaults.cognitoPoolEndpointURL
        cognitoPoolEndpointRegion = AppSyncClientTestConfigurationDefaults.cognitoPoolEndpointRegion
    }

    init?(with bundle: Bundle) {
        guard let credentialsPath = bundle.path(forResource: "appsync_test_credentials", ofType: "json") else {
            return nil
        }

        guard let credentialsData = try? Data.init(contentsOf: URL(fileURLWithPath: credentialsPath)) else {
            return nil
        }

        print("json path: \(credentialsPath)")

        let json = try? JSONSerialization.jsonObject(with: credentialsData, options: JSONSerialization.ReadingOptions.allowFragments)

        guard let jsonObject = json as? JSONObject else {
            return nil
        }

        guard let apiKey = jsonObject[JSONKeys.apiKey] as? String else {
            return nil
        }
        self.apiKey = apiKey

        guard let apiKeyEndpointURLString = jsonObject[JSONKeys.apiKeyEndpointURL] as? String,
            let endpointURL = URL(string: apiKeyEndpointURLString) else {
                return nil
        }
        self.apiKeyEndpointURL = endpointURL

        guard let apiKeyEndpointRegionString = jsonObject[JSONKeys.apiKeyEndpointRegion] as? String else {
            return nil
        }
        self.apiKeyEndpointRegion = apiKeyEndpointRegionString.aws_regionTypeValue()

        guard let cognitoPoolId = jsonObject[JSONKeys.cognitoPoolId] as? String else {
            return nil
        }
        self.cognitoPoolId = cognitoPoolId

        guard let cognitoPoolRegionString = jsonObject[JSONKeys.cognitoPoolRegion] as? String else {
            return nil
        }
        self.cognitoPoolRegion = cognitoPoolRegionString.aws_regionTypeValue()

        guard let cognitoPoolEndpointURLString = jsonObject[JSONKeys.cognitoPoolEndpointURL] as? String,
            let cognitoPoolEndpointURL = URL(string: cognitoPoolEndpointURLString) else {
                return nil
        }
        self.cognitoPoolEndpointURL = cognitoPoolEndpointURL

        guard let cognitoPoolEndpointRegionString = jsonObject[JSONKeys.cognitoPoolEndpointRegion] as? String else {
            return nil
        }
        self.cognitoPoolEndpointRegion = cognitoPoolEndpointRegionString.aws_regionTypeValue()
    }

}
