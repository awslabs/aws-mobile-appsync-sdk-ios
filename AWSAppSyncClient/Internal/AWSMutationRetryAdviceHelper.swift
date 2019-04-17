//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

final class AWSMutationRetryAdviceHelper {

    /// This method is a special retry evaluator currently only used for mutations.It is responsible to identify if the error is caused due to internet
    /// not being available or appsync hosts not reachable from the client. It evaluates it by checking for error codes in NSURLErrorDomain.
    /// We have an additional HTTP layer retry handleer which is responsible to parse and retry errors which occur at HTTP layer(5XX, 429 status codes.)
    /// We would ideally want to have a single retry layer which can account for these multiple use-cases and suggest retry advice.
    /// See [PR #223](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/pull/233) for more details on the discussion.
    ///
    /// - Parameter error: error being evaluated
    /// - Returns: true if the error is retriable.
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
