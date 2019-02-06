//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
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
            throw AWSAppSyncQueriesCacheError.invalidRecordShape(object: object)
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
                throw AWSAppSyncQueriesCacheError.invalidRecordValue(value: fieldJSONValue)
            }
            return Reference(key: reference)
        case let array as [JSONValue]:
            return try array.map { try deserialize(fieldJSONValue: $0) }
        default:
            return fieldJSONValue
        }
    }
}
