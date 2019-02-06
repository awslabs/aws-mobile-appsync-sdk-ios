//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

public enum AWSAppSyncClientError: Error {
    case requestFailed(Data?, HTTPURLResponse?, Error?)
    case noData(HTTPURLResponse)
    case parseError(Data, HTTPURLResponse, Error?)
    case authenticationError(Error)
}

// MARK: - LocalizedError

extension AWSAppSyncClientError: LocalizedError {

    public var errorDescription: String? {
        let underlyingError: Error?
        var message: String
        let errorResponse: HTTPURLResponse?

        switch self {
        case .requestFailed(_, let response, let error):
            errorResponse = response
            underlyingError = error
            message = "Did not receive a successful HTTP code."
        case .noData(let response):
            errorResponse = response
            underlyingError = nil
            message = "No Data received in response."
        case .parseError(_, let response, let error):
            underlyingError = error
            errorResponse = response
            message = "Could not parse response data."
        case .authenticationError(let error):
            underlyingError = error
            errorResponse = nil
            message = "Failed to authenticate request."
        }

        if let error = underlyingError {
            message += " Error: \(error)"
        }

        if let unwrappedResponse = errorResponse {
            return "(\(unwrappedResponse.statusCode) \(unwrappedResponse.statusCodeDescription)) \(message)"
        } else {
            return "\(message)"
        }
    }
}
