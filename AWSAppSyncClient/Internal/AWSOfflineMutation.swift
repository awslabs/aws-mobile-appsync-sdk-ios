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
