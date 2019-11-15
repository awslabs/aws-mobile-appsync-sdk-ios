//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
@testable import AWSAppSync

class MockUserPoolsAuthProvider: AWSCognitoUserPoolsAuthProviderAsync {

    func getLatestAuthToken(_ callback: @escaping (String?, Error?) -> Void) {
        callback("jwtToken", nil)
    }
}
