//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

public struct AWSAppSyncClientInfoError {
    public let errorMessage: String?
}

extension AWSAppSyncClientInfoError: Error {
    public var localizedDescription: String {
        return errorDescription ?? errorMessage ?? String(describing: self)
    }
}

extension AWSAppSyncClientInfoError: LocalizedError {
    public var errorDescription: String? {
        return errorMessage
    }
}
