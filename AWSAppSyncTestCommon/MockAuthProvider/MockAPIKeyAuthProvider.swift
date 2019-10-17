//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
@testable import AWSAppSync

class MockAPIKeyAuthProvider: AWSAPIKeyAuthProvider {

    func getAPIKey() -> String {
        return "mock_api_key"
    }
}
