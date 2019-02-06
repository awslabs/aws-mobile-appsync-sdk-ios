//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
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
