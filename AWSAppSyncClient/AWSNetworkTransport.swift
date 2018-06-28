//
//  AWSNetworkTransport.swift
//  AWSAppSyncClient
//

import Foundation

public protocol AWSNetworkTransport: AnyObject, NetworkTransport {
    func send(data: Data, completionHandler: ((JSONObject?, Error?) -> Void)?)
    func sendSubscriptionRequest<Operation: GraphQLOperation>(operation: Operation, completionHandler: @escaping (JSONObject?, Error?) -> Void) throws -> Cancellable
}
