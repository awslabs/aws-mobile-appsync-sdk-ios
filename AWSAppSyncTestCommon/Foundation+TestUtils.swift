//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

// Conform String to error module so we can easily use bare strings in Result failures
extension String: Error, LocalizedError {
    public var errorDescription: String? {
        return self
    }

    public var localizedDescription: String {
        return self
    }
}
