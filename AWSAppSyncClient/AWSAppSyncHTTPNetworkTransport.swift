//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
import AWSCore

public class AWSAppSyncHTTPNetworkTransport: AWSNetworkTransport {
    let url: URL
    let session: URLSession
    var region: AWSRegionType? = nil
    let serializationFormat = JSONSerializationFormat.self
    var credentialsProvider: AWSCredentialsProvider? = nil
    var apiKeyAuthProvider: AWSAPIKeyAuthProvider? = nil
    var userPoolsAuthProvider: AWSCognitoUserPoolsAuthProvider? = nil
    var oidcAuthProvider: AWSOIDCAuthProvider? = nil
    var endpoint: AWSEndpoint? = nil
    let authType: AWSAppSyncAuthType
    var activeTimers: [String: DispatchSourceTimer] = [:]
    
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
        self.credentialsProvider = credentialsProvider
        self.region = region
        self.endpoint = AWSEndpoint(region: region, serviceName: "appsync", url: url)
        self.authType = .awsIAM
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
        self.authType = .amazonCognitoUserPools
    }
    
    /// Creates a network transport with the specified server URL and session configuration.
    ///
    /// - Parameters:
    ///   - url: The URL of a GraphQL server to connect to.
    ///   - oidcAuthProvider: An implementation of `AWSOIDCAuthProvider` protocol.
    ///   - configuration: A session configuration used to configure the session. Defaults to `URLSessionConfiguration.default`.
    ///   - sendOperationIdentifiers: Whether to send operation identifiers rather than full operation text, for use with servers that support query persistence. Defaults to false.
    public init(url: URL,
                oidcAuthProvider: AWSOIDCAuthProvider,
                configuration: URLSessionConfiguration = URLSessionConfiguration.default,
                sendOperationIdentifiers: Bool = false) {
        self.url = url
        self.session = URLSession(configuration: configuration)
        self.sendOperationIdentifiers = sendOperationIdentifiers
        self.oidcAuthProvider = oidcAuthProvider
        self.authType = .oidcToken
    }
    
    func initRequest(request: inout URLRequest) {
        request.httpMethod = "POST"
        request.setValue(NSDate().aws_stringValue(AWSDateISO8601DateFormat2), forHTTPHeaderField: "X-Amz-Date")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("aws-sdk-ios/2.10.3 AppSyncClient", forHTTPHeaderField: "User-Agent")
        addDeviceId(request: &request)
    }
    
    func addDeviceId(request: inout URLRequest) {
        switch authType {
        case .apiKey:
            let data = self.apiKeyAuthProvider!.getAPIKey().data(using: .utf8)
            request.setValue(fetchDeviceId(for: sha256(data: data!)), forHTTPHeaderField: "x-amz-subscriber-id")
        default:
            break
        }
    }
    
    func sha256(data: Data) -> String {
        let hash = AWSSignatureSignerUtility.hash(data)
        return hash!.base64EncodedString()
    }
    
    /// Returns `deviceId` for the specified key from the keychain.
    /// If the key does not exist in keychain, a `deviceId` is generated, stored and returned.
    ///
    /// - Parameter for key: The identifier to fetch deviceId
    /// - Returns: deviceId for the device
    func fetchDeviceId(for key: String) -> String {
        let keychain = AWSUICKeyChainStore()
        if let deviceId = keychain.string(forKey: key) {
            return deviceId
        } else {
            let uuid = UUID().uuidString
            keychain.setString(uuid, forKey: key)
            return uuid
        }
    }
    
    func executeAfter(interval: DispatchTimeInterval, queue: DispatchQueue, block: @escaping () -> Void ) -> DispatchSourceTimer {
        let timer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: 0), queue: queue)
        timer.schedule(deadline: .now() + interval)
        timer.setEventHandler(handler: block)
        timer.resume()
        return timer
    }
    
    internal func sendGraphQLRequest(mutableRequest: NSMutableURLRequest,
                                     retryHandler: AWSAppSyncRetryHandler,
                                     networkTransportOperation: AWSAppSyncHTTPNetworkTransportOperation,
                                     completionHandler: @escaping (JSONObject?, AWSAppSyncClientError?) -> Void) {
        updateRequestWithAuthInformation(mutableRequest: mutableRequest, completionHandler: { result in
            switch result {
            case .success:
                let dataTask = self.sendNetworkRequest(request: mutableRequest as URLRequest, completionHandler: {[weak self] (result) in
                    switch result {
                    case .success(let jsonBody):
                        completionHandler(jsonBody, nil)
                    case .failure(let error):
                        let taskUUID = UUID().uuidString
                        let retryAdvice = retryHandler.shouldRetryRequest(for: error)
                        if retryAdvice.shouldRetry,
                            let retryInterval = retryAdvice.retryInterval {
                            let timer = self?.executeAfter(interval: retryInterval,
                                                           queue: DispatchQueue.global(qos: .userInitiated)) {
                                self?.sendGraphQLRequest(mutableRequest: mutableRequest,
                                                         retryHandler: retryHandler,
                                                         networkTransportOperation: networkTransportOperation,
                                                         completionHandler: completionHandler)
                                self?.activeTimers.removeValue(forKey: taskUUID)
                            }
                            self?.activeTimers[taskUUID] = timer
                        } else {
                            completionHandler(nil, error)
                        }
                    }
                })
                networkTransportOperation.dataTask = dataTask
            case .failure(let error):
                completionHandler(nil, AWSAppSyncClientError.authenticationError(error))
            }
            
        })
    }
    
    /// Invoke HTTP network request for all GraphQL operations
    ///
    /// - Parameters:
    ///   - request: The URL request to be sent
    ///   - completionHandler: The completion handler which will be called once the request is completed
    /// - Returns: URLSessionDataTask cancellable object
    internal func sendNetworkRequest(request: URLRequest, completionHandler: @escaping (Result<JSONObject, AWSAppSyncClientError>) -> Void) -> URLSessionDataTask {
        
        let dataTask = self.session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
            
            if let error = error {
                completionHandler(.failure(AWSAppSyncClientError.requestFailed(data, nil, error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                fatalError("Response should be an HTTPURLResponse")
            }
            
            if !httpResponse.isSuccessful {
                completionHandler(.failure(AWSAppSyncClientError.requestFailed(data, httpResponse, error)))

                return
            }
            
            guard let data = data else {
                completionHandler(.failure(AWSAppSyncClientError.noData(httpResponse)))

                return
            }
            do {
                guard let body =  try self.serializationFormat.deserialize(data: data) as? JSONObject else {
                    completionHandler(.failure(AWSAppSyncClientError.parseError(data, httpResponse, nil)))

                    return
                }
                completionHandler(.success(body))
            } catch {
                completionHandler(.failure(AWSAppSyncClientError.parseError(data, httpResponse, error)))
            }
            
        })
        
        dataTask.resume()
        return dataTask
    }
    
    /// Updates the sendRequest with the appropriate authentication parameters
    /// In the case of a token retrieval error, the errorCallback is invoked
    private func updateRequestWithAuthInformation(mutableRequest: NSMutableURLRequest,
                                                  completionHandler: @escaping (Result<Void, Error>) -> Void) {

        switch self.authType {
            
        case .awsIAM:
            let signer: AWSSignatureV4Signer = AWSSignatureV4Signer(
                credentialsProvider: self.credentialsProvider,
                endpoint: self.endpoint)
            
            signer.interceptRequest(mutableRequest).continueWith { task in
                if let error = task.error {
                    completionHandler(.failure(error))
                } else {
                    completionHandler(.success(()))
                }
                return nil
            }
        case .apiKey:
            mutableRequest.setValue(self.apiKeyAuthProvider!.getAPIKey(), forHTTPHeaderField: "x-api-key")
            completionHandler(.success(()))
        case .oidcToken:
            if let provider = self.oidcAuthProvider as? AWSOIDCAuthProviderAsync {

                provider.getLatestAuthToken { (token, error) in
                    if let error = error {
                        completionHandler(.failure(error))
                    } else if let token = token {
                        mutableRequest.setValue(token, forHTTPHeaderField: "authorization")
                        completionHandler(.success(()))
                    } else {
                        fatalError("Invalid data returned in token callback")
                    }
                }
            } else if let provider = self.oidcAuthProvider {
                mutableRequest.setValue(provider.getLatestAuthToken(), forHTTPHeaderField: "authorization")
                completionHandler(.success(()))
            } else {
                fatalError("Authentication provider not set")
            }
        case .amazonCognitoUserPools:
            if let provider = self.userPoolsAuthProvider as? AWSCognitoUserPoolsAuthProviderAsync {
                
                provider.getLatestAuthToken { (token, error) in
                    if let error = error {
                        completionHandler(.failure(error))
                    } else if let token = token {
                        mutableRequest.setValue(token, forHTTPHeaderField: "authorization")
                        completionHandler(.success(()))
                    } else {
                        fatalError("Invalid data returned in token callback")
                    }
                }
            } else if let provider = self.userPoolsAuthProvider {
                mutableRequest.setValue(provider.getLatestAuthToken(), forHTTPHeaderField: "authorization")
                completionHandler(.success(()))
            } else {
                fatalError("Authentication provider not set")
            }
        }
        
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
        
        let networkTransportOperation = AWSAppSyncHTTPNetworkTransportOperation()
        var request = URLRequest(url: url)
        initRequest(request: &request)
        
        let body = requestBody(for: operation)
        request.httpBody = try! serializationFormat.serialize(value: body)
        
        let mutableRequest = ((request as NSURLRequest).mutableCopy() as? NSMutableURLRequest)!
        let retryHandler = AWSAppSyncRetryHandler()
        sendGraphQLRequest(mutableRequest: mutableRequest,
                           retryHandler: retryHandler,
                           networkTransportOperation: networkTransportOperation,
                           completionHandler: completionHandler)

        return networkTransportOperation
    }
    
    /// Send a GraphQL operation to a server and return a response.
    ///
    /// - Parameters:
    ///   - operation: The operation to send.
    ///   - overrideMap: The override map which will replace the specified key with corresponding value.
    ///   - completionHandler: A closure to call when a request completes.
    ///   - response: The response received from the server, or `nil` if an error occurred.
    ///   - error: An error that indicates why a request failed, or `nil` if the request was succesful.
    /// - Returns: An object that can be used to cancel an in progress request.
    internal func send<Operation>(operation: Operation, overrideMap: GraphQLMap? = [:], completionHandler: @escaping (GraphQLResponse<Operation>?, Error?) -> Void) -> Cancellable {
        
        // We will have to invoke this directly from DeltaSubs.
        let networkTransportOperation = AWSAppSyncHTTPNetworkTransportOperation()
        
        var request = URLRequest(url: url)
        initRequest(request: &request)
        
        let string = String(data: try! serializationFormat.serialize(value: requestBody(for: operation, overrideMap: overrideMap)), encoding: String.Encoding.utf8)
        
        request.httpBody = string!.data(using: String.Encoding.utf8)
        
        let mutableRequest = ((request as NSURLRequest).mutableCopy() as? NSMutableURLRequest)!
        let retryHandler = AWSAppSyncRetryHandler()
        
        let completionHandlerInternal: (JSONObject?, Error?) -> Void = {(jsonObject, error) in
            guard error == nil else {
                completionHandler(nil, error)
                return
            }
            let response = GraphQLResponse(operation: operation, body: jsonObject!)
            completionHandler(response, nil)
        }
        sendGraphQLRequest(mutableRequest: mutableRequest,
                           retryHandler: retryHandler,
                           networkTransportOperation: networkTransportOperation,
                           completionHandler: completionHandlerInternal)
        
        return networkTransportOperation
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
        return send(operation: operation, overrideMap: [:], completionHandler: completionHandler)
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
        let retryHandler = AWSAppSyncRetryHandler()
        let completionHandlerInternal: (JSONObject?, Error?) -> Void = {(jsonObject, error) in
            completionHandler?(jsonObject, error)
        }
        sendGraphQLRequest(mutableRequest: mutableRequest,
                           retryHandler: retryHandler,
                           networkTransportOperation: AWSAppSyncHTTPNetworkTransportOperation(),
                           completionHandler: completionHandlerInternal)
    }
    
    private let sendOperationIdentifiers: Bool
    
    private func requestBody<Operation: GraphQLOperation>(for operation: Operation, overrideMap: GraphQLMap? = nil) -> GraphQLMap {
        var operationVariables = operation.variables
        if overrideMap != nil && overrideMap!.count > 0 {
            for (key, value) in overrideMap! {
                operationVariables?[key] = value
            }
        }
        
        if sendOperationIdentifiers {
            guard let operationIdentifier = type(of: operation).operationIdentifier else {
                preconditionFailure("To send operation identifiers, Apollo types must be generated with operationIdentifiers")
            }
            return ["id": operationIdentifier, "variables": operationVariables]
        }
        return ["query": type(of: operation).requestString, "variables": operationVariables]
    }
    
    internal class AWSAppSyncHTTPNetworkTransportOperation: Cancellable {
        
        private var cancelled: Bool = false
        
        var dataTask: URLSessionDataTask? = nil {
            didSet {
                if self.cancelled {
                    dataTask?.cancel()
                }
            }
        }
        
        func cancel() {
            self.cancelled = true
            self.dataTask?.cancel()
        }
    }
    
    internal enum Result<V, E> {
        case success(V)
        case failure(E)
    }

}
