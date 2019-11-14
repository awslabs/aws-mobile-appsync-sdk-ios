//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

struct RealtimeConnectionProviderResponse {

    /// Subscription Identifier
    ///
    let id: String?

    let payload: [String: AppSyncJSONValue]?

    let responseType: RealtimeConnectionProviderResponseType

    init(id: String? = nil,
         payload: [String: AppSyncJSONValue]? = nil,
         type: RealtimeConnectionProviderResponseType) {
        self.id = id
        self.responseType = type
        self.payload = payload
    }
}

/// Response types
enum RealtimeConnectionProviderResponseType: String, Decodable {

    case connectionAck = "connection_ack"

    case subscriptionAck = "start_ack"

    case unsubscriptionAck = "complete"

    case keepAlive = "ka"

    case data = "data"

    case error = "error"
}

extension RealtimeConnectionProviderResponse: Decodable {

    enum CodingKeys: String, CodingKey {
        case id
        case payload
        case responseType = "type"
    }
}
