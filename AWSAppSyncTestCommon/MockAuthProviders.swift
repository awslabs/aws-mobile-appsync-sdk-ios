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

@testable import AWSAppSync

struct MockAWSAPIKeyAuthProvider: AWSAPIKeyAuthProvider {
    var apiKey: String

    init(with apiKey: String = "THE_API_KEY") {
        self.apiKey = apiKey
    }

    init(with configuration: AppSyncClientTestConfiguration) {
        apiKey = configuration.apiKey
    }

    @available(*, deprecated, message: "Will be removed when we remove AWSAppSyncClientInfo")
    init(with clientInfo: AWSAppSyncClientInfo) {
        apiKey = clientInfo.apiKey
    }

    /// NOTE: Force-unwraps `serviceConfig.apiKey`
    init(with serviceConfig: AWSAppSyncServiceConfig) {
        apiKey = serviceConfig.apiKey!
    }

    func getAPIKey() -> String {
        return apiKey
    }
}

class MockAWSCredentialsProvider: NSObject, AWSCredentialsProvider {
    static let mockCredentials = AWSCredentials(accessKey: "THE_ACCESS_KEY",
                                                secretKey: "THE_SECRET_KEY",
                                                sessionKey: "THE_SESSION_KEY",
                                                expiration: Date(timeIntervalSinceNow: 86_400))

    let storedCredentials: AWSCredentials

    init(with credentials: AWSCredentials = MockAWSCredentialsProvider.mockCredentials) {
        self.storedCredentials = credentials
    }

    func credentials() -> AWSTask<AWSCredentials> {
        return AWSTask<AWSCredentials>(result: storedCredentials)
    }

    func invalidateCachedTemporaryCredentials() { }
}

struct MockAWSOIDCAuthProvider: AWSOIDCAuthProvider {
    var token: String

    init(with token: String = "THE_OIDC_TOKEN") {
        self.token = token
    }

    func getLatestAuthToken() -> String {
        return token
    }
}

struct MockAWSCognitoUserPoolsAuthProvider: AWSCognitoUserPoolsAuthProvider {
    var token: String

    init(with token: String = "THE_USER_POOLS_TOKEN") {
        self.token = token
    }

    func getLatestAuthToken() -> String {
        return token
    }
}
