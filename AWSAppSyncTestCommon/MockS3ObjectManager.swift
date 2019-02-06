//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

@testable import AWSAppSync

typealias S3ResultHandler = (Bool, Error?) -> Void

/// A mock to allow interception of calls to upload and download S3 objects
class MockS3ObjectManager: AWSS3ObjectManager {
    /// A handler to call when `upload` is invoked. Handler is invoked with same arguments
    /// to `upload`
    var uploadHandler: (AWSS3ObjectProtocol & AWSS3InputObjectProtocol, @escaping S3ResultHandler) -> Void = { _, _ in }
    func upload(s3Object: AWSS3ObjectProtocol & AWSS3InputObjectProtocol, completion: @escaping S3ResultHandler) {
        uploadHandler(s3Object, completion)
    }

    /// A handler to call when `download` is invoked. Handler is invoked with the same arguments
    /// to `download`
    var downloadHandler: (AWSS3ObjectProtocol, URL, @escaping S3ResultHandler) -> Void = { _, _, _ in }
    func download(s3Object: AWSS3ObjectProtocol, toURL: URL, completion: @escaping S3ResultHandler) {
        downloadHandler(s3Object, toURL, completion)
    }
}
