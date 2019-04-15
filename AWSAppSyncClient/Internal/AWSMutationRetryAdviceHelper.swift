//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

final class AWSMutationRetryAdviceHelper {
    
    static func isErrorRetriable(error: Error) -> Bool {
        if let appsyncError = error as? AWSAppSyncClientError {
            switch appsyncError {
            case .authenticationError(let authError):
                return isErrorURLDomainError(error: authError)
            case .requestFailed(_, _, let urlError):
                if urlError != nil {
                    return isErrorURLDomainError(error: urlError!)
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
        if let nserror = error as NSError?, nserror.domain == NSURLErrorDomain {
            switch nserror.code {
            case NSURLErrorNotConnectedToInternet,
                 NSURLErrorDNSLookupFailed,
                 NSURLErrorCannotConnectToHost,
                 NSURLErrorCannotFindHost,
                 NSURLErrorTimedOut:
                return true
            default:
                break
            }
        }
        return false
    }
}
