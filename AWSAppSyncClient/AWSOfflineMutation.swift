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

import Foundation

public enum MutationRecordState: String {
    case inProgress
    case inQueue
    case isDone
}

public enum MutationType: String {
    case graphQLMutation
    case graphQLMutationWithS3Object
}

final class InternalS3ObjectDetails: AWSS3InputObjectProtocol, AWSS3ObjectProtocol {

    let bucket: String
    let key: String
    let region: String
    let mimeType: String
    let localUri: String

    init(bucket: String, key: String, region: String, contentType: String, localUri: String) {
        self.bucket = bucket
        self.key = key
        self.region = region
        self.mimeType = contentType
        self.localUri = localUri
    }

    // MARK: AWSS3InputObjectProtocol

    func getLocalSourceFileURL() -> URL? {
        return URL(string: localUri)
    }

    func getMimeType() -> String {
        return mimeType
    }

    // MARK: AWSS3ObjectProtocol

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

final class AWSAppSyncOfflineMutation {
    var jsonRecord: JSONObject?
    var data: Data?
    var contentMap: GraphQLMap?
    var recordIdentitifer: String
    var recordState: MutationRecordState = .inQueue
    var timestamp: Date
    var type: MutationType
    var s3ObjectInput: InternalS3ObjectDetails?
    var operationString: String?

    init(
        recordIdentifier: String = UUID().uuidString,
        timestamp: Date = Date(),
        type: MutationType = .graphQLMutation) {
        self.recordIdentitifer = recordIdentifier
        self.timestamp = timestamp
        self.type = type
    }
}

// MARK: - CustomStringConvertible

extension AWSAppSyncOfflineMutation: CustomStringConvertible {

    var description: String {
        var desc: String = "<\(self):\(recordIdentitifer)"
        desc.append("\tID: \(recordIdentitifer)")
        desc.append("\ttimestamp: \(timestamp)")
        desc.append("\thasS3Object: \(s3ObjectInput != nil ? true : false)")
        desc.append(">")

        return desc
    }
}
