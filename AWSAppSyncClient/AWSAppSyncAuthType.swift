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

/// Supported authentication types for the AppSyncClient
public enum AWSAppSyncAuthType: String {
    /// AWS Identity and Access Management (IAM), for role-based authentication
    case awsIAM = "AWS_IAM"

    /// A single API key for all app users
    case apiKey = "API_KEY"

    /// OpenID Connect
    case oidcToken = "OPENID_CONNECT"

    /// User directory based authentication
    case amazonCognitoUserPools = "AMAZON_COGNITO_USER_POOLS"

    /// Convenience method to use instead of `AuthType(rawValue:)`
    public static func getAuthType(rawValue: String) throws -> AWSAppSyncAuthType {
        guard let authType = AWSAppSyncAuthType(rawValue: rawValue) else {
            throw AWSAppSyncClientConfigurationError.invalidAuthConfiguration("AuthType not recognized. Pass in a valid AuthType.")
        }
        return authType
    }
}
