//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
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

    /// NOTE: Force-unwraps `serviceConfig.apiKey`
    init(with serviceConfig: AWSAppSyncServiceConfig) {
        apiKey = serviceConfig.apiKey!
    }

    func getAPIKey() -> String {
        return apiKey
    }
}

struct MockAWSAPIKeyAuthProviderForIAMEndpoint: AWSAPIKeyAuthProvider {
    var apiKey: String

    init(with configuration: AppSyncClientTestConfiguration) {
        apiKey = configuration.apiKeyForCognitoPoolEndpoint
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
