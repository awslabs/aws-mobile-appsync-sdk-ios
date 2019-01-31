//
// Copyright 2010-2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
import SQLite

final class SQLiteSerialization {
    private static let serializedReferenceKey = "$reference"

    static func serialize(fields: Record.Fields) throws -> Data {
        var objectToSerialize = JSONObject()
        for (key, value) in fields {
            objectToSerialize[key] = try serialize(fieldValue: value)
        }
        return try JSONSerialization.data(withJSONObject: objectToSerialize, options: [])
    }

    private static func serialize(fieldValue: Record.Value) throws -> JSONValue {
        switch fieldValue {
        case let reference as Reference:
            return [serializedReferenceKey: reference.key]
        case let array as [Record.Value]:
            return try array.map { try serialize(fieldValue: $0) }
        default:
            return fieldValue
        }
    }

    static func deserialize(data: Data) throws -> Record.Fields {
        let object = try JSONSerialization.jsonObject(with: data, options: [])
        guard let jsonObject = object as? JSONObject else {
            throw AWSSQLLiteNormalizedCacheError.invalidRecordShape(object: object)
        }
        var fields = Record.Fields()
        for (key, value) in jsonObject {
            fields[key] = try deserialize(fieldJSONValue: value)
        }
        return fields
    }

    private static func deserialize(fieldJSONValue: JSONValue) throws -> Record.Value {
        switch fieldJSONValue {
        case let dictionary as JSONObject:
            guard let reference = dictionary[serializedReferenceKey] as? String else {
                throw AWSSQLLiteNormalizedCacheError.invalidRecordValue(value: fieldJSONValue)
            }
            return Reference(key: reference)
        case let array as [JSONValue]:
            return try array.map { try deserialize(fieldJSONValue: $0) }
        default:
            return fieldJSONValue
        }
    }
}
