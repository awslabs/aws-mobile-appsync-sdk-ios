//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

final class AWSAppSyncMutationRecord {
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

extension AWSAppSyncMutationRecord: CustomStringConvertible {

    var description: String {
        var desc: String = "<\(self):\(recordIdentitifer)"
        desc.append("\tID: \(recordIdentitifer)")
        desc.append("\ttimestamp: \(timestamp)")
        desc.append("\thasS3Object: \(s3ObjectInput != nil ? true : false)")
        desc.append(">")

        return desc
    }
}
