//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

struct InternalS3ObjectDetails: AWSS3InputObjectProtocol, AWSS3ObjectProtocol {

    let bucket: String
    let key: String
    let region: String
    let mimeType: String
    let localUri: String

    init(bucket: String, key: String, region: String, mimeType: String, localUri: String) {
        self.bucket = bucket
        self.key = key
        self.region = region
        self.mimeType = mimeType
        self.localUri = localUri
    }

    // MARK: - AWSS3InputObjectProtocol

    func getLocalSourceFileURL() -> URL? {
        return URL(string: localUri)
    }

    func getMimeType() -> String {
        return mimeType
    }

    // MARK: - AWSS3ObjectProtocol

    func getBucketName() -> String {
        return bucket
    }

    func getKeyName() -> String {
        return key
    }

    func getRegion() -> String {
        return region
    }
}

struct InternalS3ObjectDetailsBuilder {
    var bucket: String?
    var key: String?
    var region: String?
    var mimeType: String?
    var localUri: String?

    /// Present a key/value pair for potential inclusion in the builder. If `key` matches one of the field names defined in
    /// `AWSS3ObjectFields` or `AWSS3InputObjectFields`, and if `value` is of type `String`, then the value will be assigned
    /// to the appropriate builder field.
    ///
    /// - Parameters:
    ///   - key: The map key. To be included in the builder, must be one of the field names defined in
    ///     `AWSS3ObjectFields` or `AWSS3InputObjectFields`
    ///   - value: The value to include. To be included in the builder, must be a `String`.
    /// - Returns: `true` if the value was successfully added to the builder
    @discardableResult mutating func offer(key: String, value: JSONEncodable?) -> Bool {
        guard let value = value as? String else {
            return false
        }

        var wasAdded = false
        switch key {
        case AWSS3ObjectFields.bucket:
            bucket = value
            wasAdded = true
        case AWSS3ObjectFields.key:
            self.key = value
            wasAdded = true
        case AWSS3ObjectFields.region:
            region = value
            wasAdded = true
        case AWSS3InputObjectFields.localUri:
            localUri = value
            wasAdded = true
        case AWSS3InputObjectFields.mimeType:
            mimeType = value
            wasAdded = true
        default:
            break
        }

        return wasAdded
    }

    func build() -> InternalS3ObjectDetails? {
        guard
            let bucket = bucket,
            let key = key,
            let region = region,
            let mimeType = mimeType,
            let localUri = localUri
            else {
                return nil
        }

        return InternalS3ObjectDetails(
            bucket: bucket,
            key: key,
            region: region,
            mimeType: mimeType,
            localUri: localUri)
    }
}
