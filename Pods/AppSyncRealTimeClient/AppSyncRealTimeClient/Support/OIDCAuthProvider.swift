//
// Copyright 2018-2021 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol OIDCAuthProvider {
    func getLatestAuthToken() -> Result<String, Error>
}
