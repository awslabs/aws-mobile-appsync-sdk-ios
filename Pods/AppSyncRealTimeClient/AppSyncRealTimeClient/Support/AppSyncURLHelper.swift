//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public enum AppSyncURLHelper {

    // A standard AppSync URL has the format of
    // https://[DOMAIN].appsync-api.[REGION].amazonaws.com/graphql
    // The regex `\w{26}` is used to check that the DOMAIN is 26 alphanumeric characters long.
    // The regex `\w{2}(?:(?:-\w{2,})+)-\d` is used to check that the REGION matches the pattern
    // {2letterword}{atleast one instance of pattern {{-}{word with atleast 2 letters}}}{-}{single digit}.
    // for example, "us-west-1'
    // AppSync endpoints reference : https://docs.aws.amazon.com/general/latest/gr/appsync.html
    public static let standardDomainPattern =
    "^https://\\w{26}.appsync-api.\\w{2}(?:(?:-\\w{2,})+)-\\d.amazonaws.com/graphql$"

    // Check whether the provided GraphQL endpoint has standard appsync domain
    public static func isStandardAppSyncGraphQLEndpoint(url: URL) -> Bool {
        return url.absoluteString.range(
            of: standardDomainPattern,
            options: [
                .regularExpression,
                .caseInsensitive
            ],
            range: nil,
            locale: nil
        ) != nil
    }
}
