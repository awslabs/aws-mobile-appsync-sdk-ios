//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

extension AppSyncMessage: Encodable {
    enum CodingKeys: String, CodingKey {
        case id
        case payload
        case messageType = "type"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let id = id {
            try container.encode(id, forKey: .id)
        }
        if let payload = payload {
            try container.encode(payload, forKey: .payload)
        }
        try container.encode(messageType.getValue(), forKey: .messageType)
    }
}

extension AppSyncMessage.Payload: Encodable {
    
    enum CodingKeys: String, CodingKey {
        case data
        case extensions
    }

    enum ExtensionsKeys: String, CodingKey {
        case authHeader = "authorization"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let data = data {
            try container.encode(data, forKey: .data)
        }
        if let authorization = authHeader {
            var extensions = container.nestedContainer(keyedBy: ExtensionsKeys.self, forKey: .extensions)
            try extensions.encode(authorization, forKey: .authHeader)
        }
    }
}
