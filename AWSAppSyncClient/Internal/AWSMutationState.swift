//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

/// Determines the next step in a mutation operation.
///
/// - unknown: when the next step of mutation is not determined yet
/// - s3Upload: the mutation is required to do a s3 upload before the graphql call
/// - graphqlOperation: the mutation to complete needs to make a graphql call
enum MutationState {
    case unknown, s3Upload, graphqlOperation
}
