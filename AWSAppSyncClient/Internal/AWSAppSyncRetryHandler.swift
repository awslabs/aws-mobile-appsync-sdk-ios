//
//  AWSAppSyncRetryHandler.swift
//  AWSAppSync
//

import Foundation

internal class AWSAppSyncRetryHandler {
    
    var currentAttemptNumber = 0
    static let MAX_RETRY_WAIT_MILLIS = 300 * 1000 // 5 minutes of max retry duration.
    static let JITTER: Float = 100.0
    
    init() { }
    
    /// Returns if a request should be retried
    ///
    /// - Parameter error: The error returned by the service.
    /// - Returns: If the request should be retried and if yes, after how much time.

    func shouldRetryRequest(for error: AWSAppSyncClientError) -> (Bool, Int?) {
        currentAttemptNumber += 1
        var waitMillis = AWSAppSyncRetryHandler.retryDelayInMillseconds(for: currentAttemptNumber)
        
        var httpResponse: HTTPURLResponse?

        switch error {
        case .requestFailed(_, let reponse, _):
            httpResponse = reponse
        case .noData(let response):
            httpResponse = response
        case .parseError(_, let response, _):
            httpResponse = response
        case .authenticationError:
            httpResponse = nil
        }
        
        /// If no known error and we did not receive an HTTP response, we return false.
        guard let unwrappedResponse = httpResponse  else {
            return (false, nil)
        }
        
        let waitTime = unwrappedResponse.allHeaderFields["Retry-After"] as? Int
        if let waitTime = waitTime {
            waitMillis = waitTime * 1000
            return (true, waitMillis)
        }
        
        switch unwrappedResponse.statusCode {
        case 500 ... 599, 429:
            if waitMillis > AWSAppSyncRetryHandler.MAX_RETRY_WAIT_MILLIS {
                break
            } else {
                return(true, waitMillis)
            }
        default:
            break
        }
        return(false, nil)
    }
    
    static func getRandomBetween0And1() -> Float {
        return Float.random(in: 0...1)
    }

    /// Returns a delay in milliseconds for the current attempt number. The delay includes random jitter as
    /// described in https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
    static func retryDelayInMillseconds(for attemptNumber: Int) -> Int {
        let delay = Int(Double(truncating: pow(2.0, attemptNumber) as NSNumber) * 100.0 + Double(AWSAppSyncRetryHandler.getRandomBetween0And1() * AWSAppSyncRetryHandler.JITTER))
        return delay
    }
}
