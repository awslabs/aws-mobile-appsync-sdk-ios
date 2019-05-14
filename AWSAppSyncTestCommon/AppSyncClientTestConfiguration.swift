//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
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
        static let apiKeyForCognitoPoolEndpoint = "AppSyncMultiAuthAPIKey"

        static let bucketName = "BucketName"
        static let bucketRegion = "BucketRegion"
    }

    /// Returns a configuration with bogus values to be used for unit testing. This will validate, but not contain valid
    /// information for network or service connections.
    static let forUnitTests: AppSyncClientTestConfiguration = {
        return AppSyncClientTestConfiguration(apiKey: "FOR_UNIT_TESTING",
                                              apiKeyEndpointURL: URL(string: "http://www.amazon.com/for_unit_testing")!,
                                              apiKeyEndpointRegion: .USEast1,
                                              cognitoPoolId: "FOR_UNIT_TESTING",
                                              cognitoPoolRegion: .USEast1,
                                              cognitoPoolEndpointURL: URL(string: "http://www.amazon.com/for_unit_testing")!,
                                              cognitoPoolEndpointRegion: .USEast1,
                                              bucketName: "FOR_UNIT_TESTING",
                                              bucketRegion: .USEast1,
                                              clientDatabasePrefix: "",
                                              apiKeyForCognitoPoolEndpoint: "FOR_UNIT_TESTING")
    }()

    let apiKey: String
    let apiKeyEndpointURL: URL
    let apiKeyEndpointRegion: AWSRegionType

    let cognitoPoolId: String
    let cognitoPoolRegion: AWSRegionType
    let cognitoPoolEndpointURL: URL
    let cognitoPoolEndpointRegion: AWSRegionType
    let apiKeyForCognitoPoolEndpoint: String

    let bucketName: String
    let bucketRegion: AWSRegionType

    let clientDatabasePrefix: String
    
    var isValid: Bool {
        return apiKey != "YOUR_API_KEY"
            && apiKeyEndpointURL.absoluteString != "https://localhost"
            && cognitoPoolId != "YOUR_POOL_ID"
            && cognitoPoolEndpointURL.absoluteString != "https://localhost"
            && bucketName != "YOUR_BUCKET_NAME"
    }

    init() {
        self.init(apiKey: AppSyncClientTestConfigurationDefaults.apiKey,
                  apiKeyEndpointURL: AppSyncClientTestConfigurationDefaults.apiKeyEndpointURL,
                  apiKeyEndpointRegion: AppSyncClientTestConfigurationDefaults.apiKeyEndpointRegion,
                  cognitoPoolId: AppSyncClientTestConfigurationDefaults.cognitoPoolId,
                  cognitoPoolRegion: AppSyncClientTestConfigurationDefaults.cognitoPoolRegion,
                  cognitoPoolEndpointURL: AppSyncClientTestConfigurationDefaults.cognitoPoolEndpointURL,
                  cognitoPoolEndpointRegion: AppSyncClientTestConfigurationDefaults.cognitoPoolEndpointRegion,
                  bucketName: AppSyncClientTestConfigurationDefaults.bucketName,
                  bucketRegion: AppSyncClientTestConfigurationDefaults.bucketRegion,
                  clientDatabasePrefix: "",
                  apiKeyForCognitoPoolEndpoint: AppSyncClientTestConfigurationDefaults.apiKeyForCognitoPoolEndpoint)
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

        guard let apiKeyForCognitoPoolEndpoint = jsonObject[JSONKeys.apiKeyForCognitoPoolEndpoint] as? String else {
            return nil
        }
        self.apiKeyForCognitoPoolEndpoint = apiKeyForCognitoPoolEndpoint

        guard let bucketName = jsonObject[JSONKeys.bucketName] as? String else {
            return nil
        }
        self.bucketName = bucketName

        guard let bucketRegionString = jsonObject[JSONKeys.bucketRegion] as? String else {
            return nil
        }
        self.bucketRegion = bucketRegionString.aws_regionTypeValue()
        self.clientDatabasePrefix = ""
    }

    private init(apiKey: String,
                 apiKeyEndpointURL: URL,
                 apiKeyEndpointRegion: AWSRegionType,
                 cognitoPoolId: String,
                 cognitoPoolRegion: AWSRegionType,
                 cognitoPoolEndpointURL: URL,
                 cognitoPoolEndpointRegion: AWSRegionType,
                 bucketName: String,
                 bucketRegion: AWSRegionType,
                 clientDatabasePrefix: String?,
                 apiKeyForCognitoPoolEndpoint: String) {
        self.apiKey = apiKey
        self.apiKeyEndpointURL = apiKeyEndpointURL
        self.apiKeyEndpointRegion = apiKeyEndpointRegion
        self.cognitoPoolId = cognitoPoolId
        self.cognitoPoolRegion = cognitoPoolRegion
        self.cognitoPoolEndpointURL = cognitoPoolEndpointURL
        self.cognitoPoolEndpointRegion = cognitoPoolEndpointRegion
        self.bucketName = bucketName
        self.bucketRegion = bucketRegion
        self.clientDatabasePrefix = clientDatabasePrefix ?? ""
        self.apiKeyForCognitoPoolEndpoint = apiKeyForCognitoPoolEndpoint
    }

}
