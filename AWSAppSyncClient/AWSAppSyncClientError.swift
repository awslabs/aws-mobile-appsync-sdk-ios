//
// Copyright 2010-2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
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
