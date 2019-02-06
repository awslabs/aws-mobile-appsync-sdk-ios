//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

public protocol AWSS3InputObjectProtocol {
    func getLocalSourceFileURL() -> URL?
    func getMimeType() -> String
}

public protocol AWSS3ObjectProtocol {
    func getBucketName() -> String
    func getKeyName() -> String
    func getRegion() -> String
}

public protocol AWSS3ObjectPresignedURLGenerator {
    func getPresignedURL(s3Object: AWSS3ObjectProtocol) -> URL?
}

public protocol AWSS3ObjectManager {
    func upload(s3Object: AWSS3ObjectProtocol & AWSS3InputObjectProtocol, completion: @escaping ((_ success: Bool, _ error: Error?) -> Void))
    func download(s3Object: AWSS3ObjectProtocol, toURL: URL, completion: @escaping ((_ success: Bool, _ eror: Error?) -> Void))
}

/// In order for AppSync to treat a GraphQL type as an S3Object, the type must contain all of these field names,
/// of type `String!`
public struct AWSS3ObjectFields {
    public static let bucket = "bucket"
    public static let key = "key"
    public static let region = "region"
}

/// In order for the AWSAppSyncClient to automatically upload a GraphQL type as an S3Object, the type must contain
/// all of these field names, of type `String!`, in addition to the fields specified in `AWSS3ObjectFields`
public struct AWSS3InputObjectFields {
    public static let localUri = "localUri"
    public static let mimeType = "mimeType"
}

/// A convenience type for modeling S3 uploads
public struct S3Object: GraphQLMapConvertible {
    public var graphQLMap: GraphQLMap

    public init(bucket: String, key: String, region: String, localUri: String, mimeType: String) {
        graphQLMap = [
            AWSS3ObjectFields.bucket: bucket,
            AWSS3ObjectFields.key: key,
            AWSS3ObjectFields.region: region
        ]
    }

    public var bucket: String {
        get {
            return graphQLMap[AWSS3ObjectFields.bucket] as! String
        }
        set {
            graphQLMap.updateValue(newValue, forKey: AWSS3ObjectFields.bucket)
        }
    }

    public var key: String {
        get {
            return graphQLMap[AWSS3ObjectFields.key] as! String
        }
        set {
            graphQLMap.updateValue(newValue, forKey: AWSS3ObjectFields.key)
        }
    }

    public var region: String {
        get {
            return graphQLMap[AWSS3ObjectFields.region] as! String
        }
        set {
            graphQLMap.updateValue(newValue, forKey: AWSS3ObjectFields.region)
        }
    }
}

/// Conform S3Object to AppSync's S3Object protocol which defines behaviors necessary for
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
