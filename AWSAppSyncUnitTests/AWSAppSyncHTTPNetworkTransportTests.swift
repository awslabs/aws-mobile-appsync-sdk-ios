//
// Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import XCTest
@testable import AWSAppSyncTestCommon
@testable import AWSAppSync

class MockURLProtocol: URLProtocol {
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?
    
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("Handler is unavailable.")
        }
        
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if let data = data {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {
    }
}

class AWSAppSyncHTTPNetworkTransportTests: XCTestCase {
    
    let url = URL(string: "http://www.amazon.com/for_unit_testing")!
    let authProvider = AWSAppSyncHTTPNetworkTransport.AppSyncAuthProvider
        .apiKey(BasicAWSAPIKeyAuthProvider(key: "key"))
    let data = "{\"data\": \"data\"}".data(using: .utf8)
    
    func testSendNetworkRequestSuccess() throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: self.url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, self.data)
        }
        
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]
        let urlSession = URLSession.init(configuration: configuration)
        let transport = AWSAppSyncHTTPNetworkTransport(url: url,
                                                       urlSession: urlSession,
                                                       authProvider: authProvider,
                                                       sendOperationIdentifiers: false,
                                                       retryStrategy: .exponential)
        
        let urlRequest = URLRequest(url: url)
        
        let sendRequestSuccess = expectation(description: "send request successful")
        _ = transport.sendNetworkRequest(request: urlRequest) { result in
            switch result {
            case .success(let response):
                print(response)
                sendRequestSuccess.fulfill()
            case .failure(let error):
                XCTFail("\(error.localizedDescription)")
            }
        }
        wait(for: [sendRequestSuccess], timeout: 1)
    }
    
    func testSendNetworkRequestSuccessFailure() {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: self.url, statusCode: 400, httpVersion: nil, headerFields: nil)!
            return (response, self.data)
        }
        
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]
        let urlSession = URLSession.init(configuration: configuration)
        let transport = AWSAppSyncHTTPNetworkTransport(url: url,
                                                       urlSession: urlSession,
                                                       authProvider: authProvider,
                                                       sendOperationIdentifiers: false,
                                                       retryStrategy: .exponential)
        
        let urlRequest = URLRequest(url: url)
        
        let sendRequestFailed = expectation(description: "send request failed")
        _ = transport.sendNetworkRequest(request: urlRequest) { result in
            switch result {
            case .success(let response):
                XCTFail("Should have failed, instead got: \(response)")
            case .failure(let error):
                print("\(error.localizedDescription)")
                sendRequestFailed.fulfill()
                
            }
        }
        wait(for: [sendRequestFailed], timeout: 1)
    }
    
    func testSendGraphQLRequestSuccess() {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: self.url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, self.data)
        }
        
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]
        let urlSession = URLSession.init(configuration: configuration)
        let transport = AWSAppSyncHTTPNetworkTransport(url: url,
                                                       urlSession: urlSession,
                                                       authProvider: authProvider,
                                                       sendOperationIdentifiers: false,
                                                       retryStrategy: .exponential)
        let sendGraphQLRequestSuccess = expectation(description: "send graphql request successful")
        let request = NSMutableURLRequest(url: url)
        let retryHandler = AWSAppSyncRetryHandler(retryStrategy: .exponential)
        let transportOperation = AWSAppSyncHTTPNetworkTransport.AWSAppSyncHTTPNetworkTransportOperation()
        transport.sendGraphQLRequest(mutableRequest: request,
                                     retryHandler: retryHandler,
                                     networkTransportOperation: transportOperation) { result, error in
            if let error = error {
                XCTFail("Should not get error: \(error)")
            } else if let result = result {
                print(result)
                sendGraphQLRequestSuccess.fulfill()
            } else {
                XCTFail("Missing completion result")
            }
        }
        wait(for: [sendGraphQLRequestSuccess], timeout: 1)
    }
    
    func testSendGraphQLRequestFailure() {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: self.url, statusCode: 400, httpVersion: nil, headerFields: nil)!
            return (response, self.data)
        }
        
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]
        let urlSession = URLSession.init(configuration: configuration)
        
        let transport = AWSAppSyncHTTPNetworkTransport(url: url,
                                                       urlSession: urlSession,
                                                       authProvider: authProvider,
                                                       sendOperationIdentifiers: false,
                                                       retryStrategy: .exponential)
        let sendGraphQLRequestFailure = expectation(description: "send graphql request failure")
        let request = NSMutableURLRequest(url: url)
        let retryHandler = AWSAppSyncRetryHandler(retryStrategy: .exponential)
        let transportOperation = AWSAppSyncHTTPNetworkTransport.AWSAppSyncHTTPNetworkTransportOperation()
        transport.sendGraphQLRequest(mutableRequest: request,
                                     retryHandler: retryHandler,
                                     networkTransportOperation: transportOperation) { result, error in
            if error != nil {
                sendGraphQLRequestFailure.fulfill()
            } else if let result = result {
                XCTFail("Should have error, instead got: \(result)")
            } else {
                XCTFail("Missing completion result")
            }
        }
        wait(for: [sendGraphQLRequestFailure], timeout: 1)
    }
    
    
    func testSendGraphQLRequestFailureWithRetry() {
        var currentAttempt = 0
        MockURLProtocol.requestHandler = { request in
            currentAttempt += 1
            if currentAttempt < 10000 {
                // Mock a response with "Retry-After" header to perform a retry with 0 interval (immediately retry)
                let headers = ["Retry-After": "0"]
                let response = HTTPURLResponse(url: self.url, statusCode: 200, httpVersion: nil, headerFields: headers)!
                return (response, Data())
            } else {
                let response = HTTPURLResponse(url: self.url, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, Data())
            }
        }
        
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]
        let urlSession = URLSession.init(configuration: configuration)
    
        let transport = AWSAppSyncHTTPNetworkTransport(url: url,
                                                       urlSession: urlSession,
                                                       authProvider: authProvider,
                                                       sendOperationIdentifiers: false,
                                                       retryStrategy: .exponential)
        
        let sendGraphQLRequestFailure = expectation(description: "send graphql request failure")
        let request = NSMutableURLRequest(url: url)
        let retryHandler = AWSAppSyncRetryHandler(retryStrategy: .exponential)
        let transportOperation = AWSAppSyncHTTPNetworkTransport.AWSAppSyncHTTPNetworkTransportOperation()
        transport.sendGraphQLRequest(mutableRequest: request,
                                     retryHandler: retryHandler,
                                     networkTransportOperation: transportOperation) { result, error in
            if error != nil {
                sendGraphQLRequestFailure.fulfill()
            } else if let result = result {
                XCTFail("Should have error, instead got: \(result)")
            } else {
                XCTFail("Missing completion result")
            }
        }
        wait(for: [sendGraphQLRequestFailure], timeout: 10)
    }
}
