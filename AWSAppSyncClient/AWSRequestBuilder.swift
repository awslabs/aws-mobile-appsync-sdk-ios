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

    static func s3Object(from variables: GraphQLMap?) -> InternalS3ObjectDetails? {
        guard let variables = variables else { return nil }

        for case let object as [String: String] in variables.values {
            guard let bucket = object["bucket"] else { continue }
            guard let key = object["key"] else { continue }
            guard let region = object["region"] else { continue }
            guard let contentType = object["mimeType"] else { continue }
            guard let localUri = object["localUri"] else { continue }

            return InternalS3ObjectDetails(
                bucket: bucket,
                key: key,
                region: region,
                contentType: contentType,
                localUri: localUri)
        }

        return nil
    }

    static func requestBody<Operation: GraphQLOperation>(
        from operation: Operation) -> GraphQLMap {
        return [
            "query": type(of: operation).requestString,
            "variables": operation.variables]
    }
}
