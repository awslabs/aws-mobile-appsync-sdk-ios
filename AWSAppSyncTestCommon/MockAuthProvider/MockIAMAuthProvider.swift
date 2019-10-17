//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
@testable import AWSAppSync

class MockIAMAuthProvider: NSObject, AWSCredentialsProvider {

    func credentials() -> AWSTask<AWSCredentials> {
        let credentials = AWSCredentials(accessKey: "accessKey",
                                         secretKey: "secretKey",
                                         sessionKey: "sessionKey",
                                         expiration: Date())
        return AWSTask(result: credentials)
    }

    func invalidateCachedTemporaryCredentials() {

    }

    
}
