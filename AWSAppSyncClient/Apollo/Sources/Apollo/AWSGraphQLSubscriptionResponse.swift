//
//  AWSGraphQLSubscriptionResponse.swift
//  Apollo
//

import Foundation

/// Represents the result of a GraphQL operation.
public struct AWSGraphQLSubscriptionResponse {
    /// A list of errors, or `nil` if the operation completed without encountering any errors.
    public let errors: [GraphQLError]?
    public let newTopics: [String]?
    public let subscriptionInfo: [AWSSubscriptionInfo]?
    
    init(errors: [GraphQLError]?, newTopics: [String]?, subscriptionInfo: [AWSSubscriptionInfo]?) {
        self.errors = errors
        self.subscriptionInfo = subscriptionInfo
        self.newTopics = newTopics
    }
}

public struct AWSSubscriptionInfo {
    public let clientId: String
    public let url: String
    public let topics: [String]
    
    init(clientId: String, url: String, topics: [String]) {
        self.clientId = clientId
        self.url = url
        self.topics = topics
    }
}

/// Represents a GraphQL Subscription response received from AppSync.
public final class AWSGraphQLSubscriptionResponseParser {
    public let body: JSONObject
    
    public init(body: JSONObject) {
        self.body = body
    }
    
    public func parseResult() throws -> AWSGraphQLSubscriptionResponse  {
        let errors: [GraphQLError]?
        
        if let errorsEntry = body["errors"] as? [JSONObject] {
            errors = errorsEntry.map(GraphQLError.init)
        } else {
            errors = nil
        }
        
        if let dataEntry = body["extensions"] as? JSONObject {
            if let extensionsEntry = dataEntry["subscription"] as? JSONObject {
                if let subscriptionsEntry = extensionsEntry["mqttConnections"] as? [JSONObject] {
                    var allSubscriptionsInfo = [AWSSubscriptionInfo]()
                    for subscription in subscriptionsEntry {
                        guard let clientId = subscription["client"] as? String,
                            let url = subscription["url"] as? String,
                            let topics = subscription["topics"] as? [String] else {
                                throw GraphQLError.init("Invalid response")
                        }
                        let subsInfo = AWSSubscriptionInfo(clientId: clientId, url: url, topics: topics)
                        allSubscriptionsInfo.append(subsInfo)
                    }
                    
                    guard let newSubscriptions = extensionsEntry["newSubscriptions"] as? JSONObject else {
                        throw GraphQLError.init("Invalid response")
                    }
                    
                    let newTopicsDictKeys = newSubscriptions.keys
                    var newTopics = [String]()
                    for key in newTopicsDictKeys {
                        newTopics.append((newSubscriptions[key]! as! JSONObject)["topic"]! as! String)
                    }
                    
                    return AWSGraphQLSubscriptionResponse(errors: errors, newTopics: newTopics, subscriptionInfo: allSubscriptionsInfo)
                }
            }
        }
        
        if (errors == nil) {
            throw GraphQLError.init("Invalid response")
        }
        
        return AWSGraphQLSubscriptionResponse(errors: errors, newTopics: nil, subscriptionInfo: nil)
    }
}
