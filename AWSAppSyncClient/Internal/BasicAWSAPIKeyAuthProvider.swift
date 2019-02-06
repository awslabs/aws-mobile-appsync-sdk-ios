//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

class BasicAWSAPIKeyAuthProvider: AWSAPIKeyAuthProvider {
    var apiKey: String

    init(key: String) {
        apiKey = key
    }

    func getAPIKey() -> String {
        return apiKey
    }
}
