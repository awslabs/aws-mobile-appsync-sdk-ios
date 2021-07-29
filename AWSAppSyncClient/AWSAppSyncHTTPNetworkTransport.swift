//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
import AWSCore

public class AWSAppSyncHTTPNetworkTransport: AWSNetworkTransport {
    public enum AppSyncAuthProvider {
        case awsIAM(provider: AWSCredentialsProvider, endpoint: AWSEndpoint)
        case apiKey(AWSAPIKeyAuthProvider)
        case oidcToken(AWSOIDCAuthProvider)
        case amazonCognitoUserPools(AWSCognitoUserPoolsAuthProvider)
        case awsLambda(AWSLambdaAuthProvider)

        public var appSyncAuthType: AWSAppSyncAuthType {
            switch self {
            case .awsIAM:
                return .awsIAM
            case .apiKey:
                return .apiKey
            case .amazonCognitoUserPools:
                return .amazonCognitoUserPools
            case .oidcToken:
                return .oidcToken
            case .awsLambda:
                return .awsLambda
            }
        }
    }

    private let url: URL
    private let session: URLSession
    private let serializationFormat = JSONSerializationFormat.self
    private let authProvider: AppSyncAuthProvider
    private let sendOperationIdentifiers: Bool
    private var retryStrategy: AWSAppSyncRetryStrategy

    private var activeTimers: [String: DispatchSourceTimer] = [:]

    /// Designated initializer. Creates a network transport with the specified server
    /// URL, URLSession (which must be created with an appropriate delegate and queue
    /// if one is required), and auth provider.
    ///
    /// - Parameters:
    ///   - url: The URL of a GraphQL server to connect to.
    ///   - urlSession: The URLSession to be used to connect to the GraphQL server specified in `url`
    ///   - authProvider: The AppSyncAuthProvider to be used to authorize requests
    ///   - sendOperationIdentifiers: Whether to send operation identifiers rather than full operation text, for use with servers that support query persistence
    ///   - retryStrategy: The retry strategy to be followed by HTTP client
    public init(
        url: URL,
        urlSession: URLSession,
        authProvider: AppSyncAuthProvider,
        sendOperationIdentifiers: Bool,
        retryStrategy: AWSAppSyncRetryStrategy
    ) {
        self.url = url
        self.session = urlSession
        self.sendOperationIdentifiers = sendOperationIdentifiers
        self.retryStrategy = retryStrategy
        self.authProvider = authProvider
    }

    /// Creates a network transport with the specified server URL and session configuration.
    ///
    /// - Parameters:
    ///   - url: The URL of a GraphQL server to connect to.
    ///   - configuration: A session configuration used to configure the session. Defaults to `URLSessionConfiguration.default`.
    ///   - region: The AWS region in which the API is configured.
    ///   - credentialsProvider: The AWSCredentialsProvider to use to authenticate requests via IAM.
    ///   - sendOperationIdentifiers: Whether to send operation identifiers rather than full operation text, for use with servers that support query persistence. Defaults to false.
    ///   - retryStrategy: The retry strategy to be followed by HTTP client
    public convenience init(url: URL,
                            configuration: URLSessionConfiguration = URLSessionConfiguration.default,
                            region: AWSRegionType,
                            credentialsProvider: AWSCredentialsProvider,
                            sendOperationIdentifiers: Bool = false,
                            retryStrategy: AWSAppSyncRetryStrategy = .exponential) {
        guard let endpoint = AWSEndpoint(region: region, serviceName: "appsync", url: url) else {
            fatalError("Unable to create endpoint for \(region) and \(url)")
        }

        self.init(
            url: url,
            urlSession: URLSession(configuration: configuration),
            authProvider: .awsIAM(provider: credentialsProvider, endpoint: endpoint),
            sendOperationIdentifiers: sendOperationIdentifiers,
            retryStrategy: retryStrategy
        )
    }

    /// Creates a network transport with the specified server URL and session configuration.
    ///
    /// - Parameters:
    ///   - url: The URL of a GraphQL server to connect to.
    ///   - apiKeyAuthProvider: An object of `AWSAPIKeyAuthProvider` protocol for API Key based authorization.
    ///   - configuration: A session configuration used to configure the session. Defaults to `URLSessionConfiguration.default`.
    ///   - sendOperationIdentifiers: Whether to send operation identifiers rather than full operation text, for use with servers that support query persistence. Defaults to false.
    ///   - retryStrategy: The retry strategy to be followed by HTTP client
    public convenience init(url: URL,
                            apiKeyAuthProvider: AWSAPIKeyAuthProvider,
                            configuration: URLSessionConfiguration = URLSessionConfiguration.default,
                            sendOperationIdentifiers: Bool = false,
                            retryStrategy: AWSAppSyncRetryStrategy = .exponential) {
        self.init(
            url: url,
            urlSession: URLSession(configuration: configuration),
            authProvider: .apiKey(apiKeyAuthProvider),
            sendOperationIdentifiers: sendOperationIdentifiers,
            retryStrategy: retryStrategy
        )
    }

    /// Creates a network transport with the specified server URL and session configuration.
    ///
    /// - Parameters:
    ///   - url: The URL of a GraphQL server to connect to.
    ///   - userPoolsAuthProvider: An implementation of `AWSCognitoUserPoolsAuthProvider` protocol.
    ///   - configuration: A session configuration used to configure the session. Defaults to `URLSessionConfiguration.default`.
    ///   - sendOperationIdentifiers: Whether to send operation identifiers rather than full operation text, for use with servers that support query persistence. Defaults to false.
    ///   - retryStrategy: The retry strategy to be followed by HTTP client
    public convenience init(url: URL,
                            userPoolsAuthProvider: AWSCognitoUserPoolsAuthProvider,
                            configuration: URLSessionConfiguration = URLSessionConfiguration.default,
                            sendOperationIdentifiers: Bool = false,
                            retryStrategy: AWSAppSyncRetryStrategy = .exponential) {
        self.init(
            url: url,
            urlSession: URLSession(configuration: configuration),
            authProvider: .amazonCognitoUserPools(userPoolsAuthProvider),
            sendOperationIdentifiers: sendOperationIdentifiers,
            retryStrategy: retryStrategy
        )
    }
    
    /// Creates a network transport with the specified server URL and session configuration.
    ///
    /// - Parameters:
    ///   - url: The URL of a GraphQL server to connect to.
    ///   - awsLambdaAuthProvider: An implementation of `AWSLambdaAuthProvider` protocol.
    ///   - configuration: A session configuration used to configure the session. Defaults to `URLSessionConfiguration.default`.
    ///   - sendOperationIdentifiers: Whether to send operation identifiers rather than full operation text, for use with servers that support query persistence. Defaults to false.
    ///   - retryStrategy: The retry strategy to be followed by HTTP client
    public convenience init(url: URL,
                            awsLambdaAuthProvider: AWSLambdaAuthProvider,
                            configuration: URLSessionConfiguration = URLSessionConfiguration.default,
                            sendOperationIdentifiers: Bool = false,
                            retryStrategy: AWSAppSyncRetryStrategy = .exponential) {
        self.init(
            url: url,
            urlSession: URLSession(configuration: configuration),
            authProvider: .awsLambda(awsLambdaAuthProvider),
            sendOperationIdentifiers: sendOperationIdentifiers,
            retryStrategy: retryStrategy
        )
    }

    /// Creates a network transport with the specified server URL and session configuration.
    ///
    /// - Parameters:
    ///   - url: The URL of a GraphQL server to connect to.
    ///   - oidcAuthProvider: An implementation of `AWSOIDCAuthProvider` protocol.
    ///   - configuration: A session configuration used to configure the session. Defaults to `URLSessionConfiguration.default`.
    ///   - sendOperationIdentifiers: Whether to send operation identifiers rather than full operation text, for use with servers that support query persistence. Defaults to false.
    ///   - retryStrategy: The retry strategy to be followed by HTTP client
    public convenience init(url: URL,
                            oidcAuthProvider: AWSOIDCAuthProvider,
                            configuration: URLSessionConfiguration = URLSessionConfiguration.default,
                            sendOperationIdentifiers: Bool = false,
                            retryStrategy: AWSAppSyncRetryStrategy = .exponential) {
        self.init(
            url: url,
            urlSession: URLSession(configuration: configuration),
            authProvider: .oidcToken(oidcAuthProvider),
            sendOperationIdentifiers: sendOperationIdentifiers,
            retryStrategy: retryStrategy
        )
    }

    func initRequest(request: inout URLRequest) {
        request.httpMethod = "POST"
        request.setValue(NSDate().aws_stringValue(AWSDateISO8601DateFormat2), forHTTPHeaderField: "X-Amz-Date")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("aws-sdk-ios/3.3.0 AppSyncClient", forHTTPHeaderField: "User-Agent")
        addDeviceId(request: &request)
    }

    func addDeviceId(request: inout URLRequest) {
        switch authProvider {
        case .apiKey(let provider):
            let data = provider.getAPIKey().data(using: .utf8)
            request.setValue(fetchDeviceId(for: sha256(data: data!)), forHTTPHeaderField: "x-amz-subscriber-id")
        default:
            break
        }
    }

    func sha256(data: Data) -> String {
        let hash = AWSSignatureSignerUtility.hash(data)
        return hash.base64EncodedString()
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
    internal func sendNetworkRequest(request: URLRequest, completionHandler: @escaping (Swift.Result<JSONObject, AWSAppSyncClientError>) -> Void) -> URLSessionDataTask {

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
                                                  completionHandler: @escaping (Swift.Result<Void, Error>) -> Void) {

        switch authProvider {

        case .awsIAM(let credentialsProvider, let endpoint):
            let signer: AWSSignatureV4Signer = AWSSignatureV4Signer(
                credentialsProvider: credentialsProvider,
                endpoint: endpoint)

            signer.interceptRequest(mutableRequest).continueWith { task in
                if let error = task.error {
                    completionHandler(.failure(error))
                } else {
                    completionHandler(.success(()))
                }
                return nil
            }

        case .apiKey(let provider):
            mutableRequest.setValue(provider.getAPIKey(), forHTTPHeaderField: "x-api-key")
            completionHandler(.success(()))

        case .oidcToken(let provider):
            if let provider = provider as? AWSOIDCAuthProviderAsync {
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
            } else {
                mutableRequest.setValue(provider.getLatestAuthToken(), forHTTPHeaderField: "authorization")
                completionHandler(.success(()))
            }

        case .amazonCognitoUserPools(let provider):
            if let provider = provider as? AWSCognitoUserPoolsAuthProviderAsync {
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
            } else {
                mutableRequest.setValue(provider.getLatestAuthToken(), forHTTPHeaderField: "authorization")
                completionHandler(.success(()))
            }
        
        case .awsLambda(let provider):
            guard let asyncProvider = provider as? AWSLambdaAuthProviderAsync else {
                mutableRequest.setValue(provider.getLatestAuthToken(), forHTTPHeaderField: "authorization")
                completionHandler(.success(()))
                break
            }
            asyncProvider.getLatestAuthToken { (token, error) in
                if let error = error {
                    completionHandler(.failure(error))
                } else if let token = token {
                    mutableRequest.setValue(token, forHTTPHeaderField: "authorization")
                    completionHandler(.success(()))
                } else {
                    fatalError("Invalid data returned in token callback")
                }
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
        let retryHandler = AWSAppSyncRetryHandler(retryStrategy: retryStrategy)
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
        let retryHandler = AWSAppSyncRetryHandler(retryStrategy: retryStrategy)

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
        let retryHandler = AWSAppSyncRetryHandler(retryStrategy: retryStrategy)
        let completionHandlerInternal: (JSONObject?, Error?) -> Void = {(jsonObject, error) in
            completionHandler?(jsonObject, error)
        }
        sendGraphQLRequest(mutableRequest: mutableRequest,
                           retryHandler: retryHandler,
                           networkTransportOperation: AWSAppSyncHTTPNetworkTransportOperation(),
                           completionHandler: completionHandlerInternal)
    }

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

}
