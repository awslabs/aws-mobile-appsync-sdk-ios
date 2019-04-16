//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

final class AWSMutationRetryAdviceHelper {
    
    static func isRetriableNetworkError(error: Error) -> Bool {
        if let appsyncError = error as? AWSAppSyncClientError {
            switch appsyncError {
            case .authenticationError(let authError):
                // We are currently checking for this error due to IAM auth.
                // If Cognito Identity SDK does not have an identity id available,
                // It tries to get one before giving the callback to appsync SDK.
                // If Cognito Identity SDK cannot reach the service to fetch identityd id,
                // it will propogate the error it encoutered to AppSync. We specifically
                // check if the error is of type internet not available and then retry.
                return isErrorURLDomainError(error: authError)
            case .requestFailed(_, _, let urlError):
                if let urlError = urlError {
                    return isErrorURLDomainError(error: urlError)
                }
            default:
                break
            }
        } else {
            return isErrorURLDomainError(error: error)
        }
        return false
    }
    
    /// We evaluate the error against known error codes which could result due to unavailable internet or spotty network connection.
    private static func isErrorURLDomainError(error: Error) -> Bool {
        let nsError = error as NSError
        guard nsError.domain == NSURLErrorDomain else {
            return false
        }
        switch nsError.code {
        case NSURLErrorNotConnectedToInternet,
             NSURLErrorDNSLookupFailed,
             NSURLErrorCannotConnectToHost,
             NSURLErrorCannotFindHost,
             NSURLErrorTimedOut:
            return true
        default:
            break
        }
        return false
    }
}
