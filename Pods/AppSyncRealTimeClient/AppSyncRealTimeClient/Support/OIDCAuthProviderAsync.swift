//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if swift(>=5.5.2)

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public protocol OIDCAuthProviderAsync {
    func getLatestAuthToken() async throws -> String
}
#endif
