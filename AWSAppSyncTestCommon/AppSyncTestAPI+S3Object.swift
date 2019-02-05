//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
import AWSAppSync

// Extensions to allow Various `File` fields of the GraphQL API to work with S3ObjectManager

extension GetPostQuery.Data.GetPost.File: AWSS3ObjectProtocol {
    public func getBucketName() -> String {
        return bucket
    }

    public func getKeyName() -> String {
        return key
    }

    public func getRegion() -> String {
        return region
    }
}
