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

final class AWSRequestBuilder {

    /// Given a `GraphQLMap` (e.g., parameters to a mutation, or an input type for a mutation), inspects the graph
    /// to find a set of variables that can be cast to an S3InputObject. This currently only supports one S3Object per
    /// GraphQLMap. The behavior of maps containing multiple S3 objects is undefined.
    static func s3Object(from variables: GraphQLMap?) -> InternalS3ObjectDetails? {
        guard let variables = variables else {
            return nil
        }

        var builder = InternalS3ObjectDetailsBuilder()

        for (key, value) in variables {
            guard let value = value else {
                continue
            }

            if let nestedMap = value as? GraphQLMapConvertible {
                if let s3Object = s3Object(from: nestedMap.graphQLMap) {
                    return s3Object
                }
            }

            builder.offer(key: key, value: value)
        }

        return builder.build()
    }

    static func requestBody<Operation: GraphQLOperation>(
        from operation: Operation) -> GraphQLMap {
        return [
            "query": type(of: operation).requestString,
            "variables": operation.variables]
    }
}
