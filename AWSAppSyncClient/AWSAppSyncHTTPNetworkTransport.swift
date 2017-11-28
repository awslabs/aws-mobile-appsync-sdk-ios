//
//  AWSSigV4HTTPNetworkTransport.swift
//  AWSAppSyncClient
//

import Foundation
import AWSCore

enum AuthType {
    case awsIAM
    case apiKey
    case oidcToken
}

public class AWSAppSyncHTTPNetworkTransport: NetworkTransport {
    let url: URL
    let session: URLSession
    let region: AWSRegionType?
    let serializationFormat = JSONSerializationFormat.self
    let credentialsProvider:AWSCredentialsProvider?
    let apiKeyAuthProvider: AWSAPIKeyAuthProvider?
    let userPoolsAuthProvider: AWSCognitoUserPoolsAuthProvider?
    let endpoint:AWSEndpoint?
    let authType: AuthType
    
    /// Creates a network transport with the specified server URL and session configuration.
    ///
    /// - Parameters:
    ///   - url: The URL of a GraphQL server to connect to.
    ///   - configuration: A session configuration used to configure the session. Defaults to `URLSessionConfiguration.default`.
    ///   - sendOperationIdentifiers: Whether to send operation identifiers rather than full operation text, for use with servers that support query persistence. Defaults to false.
    public init(url: URL,
                configuration: URLSessionConfiguration = URLSessionConfiguration.default,
                region: AWSRegionType,
                credentialsProvider: AWSCredentialsProvider,
                sendOperationIdentifiers: Bool = false) {
        self.url = url
        self.session = URLSession(configuration: configuration)
        self.sendOperationIdentifiers = sendOperationIdentifiers
        self.credentialsProvider = credentialsProvider;
        self.region = region
        self.endpoint = AWSEndpoint(region: region, serviceName: "appsync", url: url)
        self.authType = .awsIAM
        self.apiKeyAuthProvider = nil
        self.userPoolsAuthProvider = nil
    }
    
    /// Creates a network transport with the specified server URL and session configuration.
    ///
    /// - Parameters:
    ///   - url: The URL of a GraphQL server to connect to.
    ///   - apiKeyAuthProvider: An object of `AWSAPIKeyAuthProvider` protocol for API Key based authorization.
    ///   - configuration: A session configuration used to configure the session. Defaults to `URLSessionConfiguration.default`.
    ///   - sendOperationIdentifiers: Whether to send operation identifiers rather than full operation text, for use with servers that support query persistence. Defaults to false.
    public init(url: URL,
                apiKeyAuthProvider: AWSAPIKeyAuthProvider,
                configuration: URLSessionConfiguration = URLSessionConfiguration.default,
                sendOperationIdentifiers: Bool = false) {
        self.url = url
        self.session = URLSession(configuration: configuration)
        self.sendOperationIdentifiers = sendOperationIdentifiers
        self.apiKeyAuthProvider = apiKeyAuthProvider
        self.authType = .apiKey
        self.userPoolsAuthProvider = nil
        self.credentialsProvider = nil
        self.endpoint = nil
        self.region = nil
    }
    
    /// Creates a network transport with the specified server URL and session configuration.
    ///
    /// - Parameters:
    ///   - url: The URL of a GraphQL server to connect to.
    ///   - userPoolsAuthProvider: An implementation of `AWSCognitoUserPoolsAuthProvider` protocol.
    ///   - configuration: A session configuration used to configure the session. Defaults to `URLSessionConfiguration.default`.
    ///   - sendOperationIdentifiers: Whether to send operation identifiers rather than full operation text, for use with servers that support query persistence. Defaults to false.
    public init(url: URL,
                userPoolsAuthProvider: AWSCognitoUserPoolsAuthProvider,
                configuration: URLSessionConfiguration = URLSessionConfiguration.default,
                sendOperationIdentifiers: Bool = false) {
        self.url = url
        self.session = URLSession(configuration: configuration)
        self.sendOperationIdentifiers = sendOperationIdentifiers
        self.userPoolsAuthProvider = userPoolsAuthProvider
        self.authType = .oidcToken
        self.apiKeyAuthProvider = nil
        self.credentialsProvider = nil
        self.endpoint = nil
        self.region = nil
    }
    
    func initRequest(request: inout URLRequest) {
        request.httpMethod = "POST"
        request.setValue(NSDate().aws_stringValue(AWSDateISO8601DateFormat2), forHTTPHeaderField: "X-Amz-Date")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("aws-sdk-ios/2.6.7 AppSyncClient", forHTTPHeaderField: "User-Agent")
        if self.authType == .apiKey {
            request.setValue(self.apiKeyAuthProvider!.getAPIKey(), forHTTPHeaderField: "x-api-key")
        } else if self.authType == .oidcToken {
            request.setValue(self.userPoolsAuthProvider!.getLatestAuthToken(), forHTTPHeaderField: "authorization")
        }
    }
    
    /// Send a data payload to a server and return a response.
    ///
    /// - Parameters:
    ///   - data: The data to send.
    ///   - completionHandler: A closure to call when a request completes.
    public func send(data: Data, completionHandler: ((JSONObject?, Error?) -> Void)? = nil) {
        
        var request = URLRequest(url: url)
        initRequest(request: &request)
        
        let body = data
        request.httpBody = body
        
        let mutableRequest = ((request as NSURLRequest).mutableCopy() as? NSMutableURLRequest)!
        
        if self.authType == .awsIAM {
            let signer:AWSSignatureV4Signer = AWSSignatureV4Signer(credentialsProvider: self.credentialsProvider, endpoint: self.endpoint)
            signer.interceptRequest(mutableRequest).continueWith { (task: AWSTask<AnyObject>) -> Any? in
                
                return nil
                }.waitUntilFinished()
        }
        
        let task = self.session.dataTask(with: mutableRequest  as URLRequest, completionHandler: { (data: Data?, response: URLResponse?, error:Error?) in
            
            if error != nil {
                completionHandler?(nil, error)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                fatalError("Response should be an HTTPURLResponse")
            }
            
            if (!httpResponse.isSuccessful) {
                let err = AWSAppSyncClientError(body: data, response: httpResponse, isInternalError: false, additionalInfo: "Did not receive a successful HTTP code.")
                completionHandler?(nil, err)
                return
            }
            
            guard let data = data else {
                let err = AWSAppSyncClientError(body: nil, response: httpResponse, isInternalError: false, additionalInfo: "No Data received in response.")
                completionHandler?(nil, err)
                return
            }
            
            do {
                guard let body =  try self.serializationFormat.deserialize(data: data) as? JSONObject else {
                    throw AWSAppSyncClientError(body: data, response: httpResponse, isInternalError: false, additionalInfo: "Could not parse response data.")
                }
                completionHandler?(body, error)
            } catch {
                completionHandler?(nil, error)
            }
            
        })
        
        task.resume()
    }
    
    
    /// Send a GraphQL operation to a server and return a response for a subscription.
    ///
    /// - Parameters:
    ///   - operation: The operation to send.
    ///   - completionHandler: A closure to call when a request completes.
    ///   - response: The response received from the server, or `nil` if an error occurred.
    ///   - error: An error that indicates why a request failed, or `nil` if the request was succesful.
    /// - Returns: An object that can be used to cancel an in progress request.
    public func sendSubscriptionRequest<Operation: GraphQLOperation>(operation: Operation, completionHandler: @escaping (JSONObject?, Error?) -> Void) throws -> Cancellable {
        
        var request = URLRequest(url: url)
        initRequest(request: &request)
        
        let body = requestBody(for: operation)
        request.httpBody = try! serializationFormat.serialize(value: body)
        
        let mutableRequest = ((request as NSURLRequest).mutableCopy() as? NSMutableURLRequest)!
        
        if self.authType == .awsIAM {
            let signer:AWSSignatureV4Signer = AWSSignatureV4Signer(credentialsProvider: self.credentialsProvider, endpoint: self.endpoint)
            signer.interceptRequest(mutableRequest).continueWith { (task: AWSTask<AnyObject>) -> Any? in
                
                return nil
                }.waitUntilFinished()
        }
        
        let task = self.session.dataTask(with: mutableRequest  as URLRequest, completionHandler: { (data: Data?, response: URLResponse?, error:Error?) in
            
            if error != nil {
                completionHandler(nil, error)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                fatalError("Response should be an HTTPURLResponse")
            }
            
            if (!httpResponse.isSuccessful) {
                let err = AWSAppSyncClientError(body: data, response: httpResponse, isInternalError: false, additionalInfo: "Did not receive a successful HTTP code.")
                completionHandler(nil, err)
                return
            }
            
            guard let data = data else {
                let err = AWSAppSyncClientError(body: nil, response: httpResponse, isInternalError: false, additionalInfo: "No Data received in response.")
                completionHandler(nil, err)
                return
            }
            
            do {
                guard let body =  try self.serializationFormat.deserialize(data: data) as? JSONObject else {
                    throw AWSAppSyncClientError(body: data, response: httpResponse, isInternalError: false, additionalInfo: "Could not parse response data.")
                }
                
                completionHandler(body, nil)
            } catch {
                completionHandler(nil, error)
            }
            
        })
        
        task.resume()
        
        return task
    }

    
    /// Send a GraphQL operation to a server and return a response.
    ///
    /// - Parameters:
    ///   - operation: The operation to send.
    ///   - completionHandler: A closure to call when a request completes.
    ///   - response: The response received from the server, or `nil` if an error occurred.
    ///   - error: An error that indicates why a request failed, or `nil` if the request was succesful.
    /// - Returns: An object that can be used to cancel an in progress request.
    public func send<Operation>(operation: Operation, completionHandler: @escaping (GraphQLResponse<Operation>?, Error?) -> Void) -> Cancellable {
        
        var request = URLRequest(url: url)
        initRequest(request: &request)
        
        let body = requestBody(for: operation)
        request.httpBody = try! serializationFormat.serialize(value: body)
        
        let mutableRequest = ((request as NSURLRequest).mutableCopy() as? NSMutableURLRequest)!
        
        if self.authType == .awsIAM {
            let signer:AWSSignatureV4Signer = AWSSignatureV4Signer(credentialsProvider: self.credentialsProvider, endpoint: self.endpoint)
            signer.interceptRequest(mutableRequest).continueWith { (task: AWSTask<AnyObject>) -> Any? in
                
                return nil
                }.waitUntilFinished()
        }
        
        let task = self.session.dataTask(with: mutableRequest  as URLRequest, completionHandler: { (data: Data?, response: URLResponse?, error:Error?) in
            
            if error != nil {
                completionHandler(nil, error)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                fatalError("Response should be an HTTPURLResponse")
            }
            
            if (!httpResponse.isSuccessful) {
                let err = AWSAppSyncClientError(body: data, response: httpResponse, isInternalError: false, additionalInfo: "Did not receive a successful HTTP code.")
                completionHandler(nil, err)
                return
            }
            
            guard let data = data else {
                let err = AWSAppSyncClientError(body: nil, response: httpResponse, isInternalError: false, additionalInfo: "No Data received in response.")
                completionHandler(nil, err)
                return
            }
            
            do {
                guard let body =  try self.serializationFormat.deserialize(data: data) as? JSONObject else {
                    throw AWSAppSyncClientError(body: data, response: httpResponse, isInternalError: false, additionalInfo: "Could not parse response data.")
                }
                let response = GraphQLResponse(operation: operation, body: body)
                completionHandler(response, nil)
            } catch {
                completionHandler(nil, error)
            }

        })
        
        task.resume()
        
        return task
    }

    private let sendOperationIdentifiers: Bool
    
    private func requestBody<Operation: GraphQLOperation>(for operation: Operation) -> GraphQLMap {
        if sendOperationIdentifiers {
            guard let operationIdentifier = type(of: operation).operationIdentifier else {
                preconditionFailure("To send operation identifiers, Apollo types must be generated with operationIdentifiers")
            }
            return ["id": operationIdentifier, "variables": operation.variables]
        }
        return ["query": type(of: operation).requestString, "variables": operation.variables]
    }
}
