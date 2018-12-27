//
// Copyright 2010-2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//

import AWSAppSync
import AWSS3

/// A convenience type for modeling S3 uploads
public struct S3Object: GraphQLMapConvertible {
    public var graphQLMap: GraphQLMap

    public init(bucket: String, key: String, region: String, localUri: String, mimeType: String) {
        graphQLMap = ["bucket": bucket, "key": key, "region": region]
    }

    public var bucket: String {
        get {
            return graphQLMap["bucket"] as! String
        }
        set {
            graphQLMap.updateValue(newValue, forKey: "bucket")
        }
    }

    public var key: String {
        get {
            return graphQLMap["key"] as! String
        }
        set {
            graphQLMap.updateValue(newValue, forKey: "key")
        }
    }

    public var region: String {
        get {
            return graphQLMap["region"] as! String
        }
        set {
            graphQLMap.updateValue(newValue, forKey: "region")
        }
    }
}

/// Conform S3Object to AppSync's S3Object protocol which defines behaviors necessary for uploading &
/// downloading objects
extension S3Object: AWSS3ObjectProtocol {
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

/// Conform the default `input` type, S3ObjectInput, to the necessary protocols to allow complex objects
/// to be discovered and automatically uploaded in a mutation.
extension S3ObjectInput: AWSS3ObjectProtocol {
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

/// Conform the default `input` type, S3ObjectInput, to the necessary protocols to allow complex objects
/// to be discovered and automatically uploaded in a mutation.
extension S3ObjectInput: AWSS3InputObjectProtocol {
    public func getLocalSourceFileURL() -> URL? {
        return URL(string: localUri)
    }

    public func getMimeType() -> String {
        return mimeType
    }
}

/// Allow `AWSS3PreSignedURLBuilder` to be passed as AppSync's `presignedURLBuilder` for uploading and downloading S3 objects
/// via AppSync
extension AWSS3PreSignedURLBuilder: AWSS3ObjectPresignedURLGenerator  {
    public func getPresignedURL(s3Object: AWSS3ObjectProtocol) -> URL? {
        let request = AWSS3GetPreSignedURLRequest()
        request.bucket = s3Object.getBucketName()
        request.key = s3Object.getKeyName()
        var url : URL?
        self.getPreSignedURL(request).continueWith { task -> Any? in
            url = task.result as URL?
            }.waitUntilFinished()
        return url
    }
}

/// Allow `AWSS3TransferUtility` to be passed as AppSync's `s3ObjectManager`
extension AWSS3TransferUtility: AWSS3ObjectManager {
    public func download(s3Object: AWSS3ObjectProtocol, toURL: URL, completion: @escaping ((Bool, Error?) -> Void)) {
        let completionBlock: AWSS3TransferUtilityDownloadCompletionHandlerBlock = { task, url, data, error -> Void in
            if let _ = error {
                completion(false, error)
            } else {
                completion(true, nil)
            }
        }

        let _ = self.download(
            to: toURL,
            bucket: s3Object.getBucketName(),
            key: s3Object.getKeyName(),
            expression: nil,
            completionHandler: completionBlock)
    }

    public func upload(s3Object: AWSS3ObjectProtocol & AWSS3InputObjectProtocol,
                       completion: @escaping ((_ success: Bool, _ error: Error?) -> Void)) {
        let completionBlock: AWSS3TransferUtilityUploadCompletionHandlerBlock = { task, error -> Void in
            if let _ = error {
                completion(false, error)
            } else {
                completion(true, nil)
            }
        }

        let _ = self.uploadFile(
            s3Object.getLocalSourceFileURL()!,
            bucket: s3Object.getBucketName(),
            key: s3Object.getKeyName(),
            contentType: s3Object.getMimeType(),
            expression: nil,
            completionHandler: completionBlock
            ).continueWith { (task) -> Any? in
                if let err = task.error {
                    completion(false, err)
                }
                return nil
        }

    }
}
