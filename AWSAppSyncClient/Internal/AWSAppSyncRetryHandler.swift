//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

/// Encapsulates advice about whether a request should be retried, and if so, after how much time
struct AWSAppSyncRetryAdvice {
    let shouldRetry: Bool
    let retryInterval: DispatchTimeInterval?
}

final class AWSAppSyncRetryHandler {
    static let maxWaitMilliseconds = 300 * 1000 // 5 minutes of max retry duration.

    private static let jitterMilliseconds: Float = 100.0

    private var currentAttemptNumber = 0

    /// Returns if a request should be retried
    ///
    /// - Parameter error: The error returned by the service.
    /// - Returns: If the request should be retried and if yes, after how much time.

    func shouldRetryRequest(for error: AWSAppSyncClientError) -> AWSAppSyncRetryAdvice {
        currentAttemptNumber += 1

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
            return AWSAppSyncRetryAdvice(shouldRetry: false, retryInterval: nil)
        }
        
        if let retryAfterValueInSeconds = AWSAppSyncRetryHandler.getRetryAfterHeaderValue(from: unwrappedResponse) {
            return AWSAppSyncRetryAdvice(shouldRetry: true, retryInterval: .seconds(retryAfterValueInSeconds))
        }
        
        let waitMillis = AWSAppSyncRetryHandler.retryDelayInMillseconds(for: currentAttemptNumber)

        switch unwrappedResponse.statusCode {
        case 500 ... 599, 429:
            if waitMillis > AWSAppSyncRetryHandler.maxWaitMilliseconds {
                break
            } else {
                return AWSAppSyncRetryAdvice(shouldRetry: true, retryInterval: .milliseconds(waitMillis))
            }
        default:
            break
        }
        return AWSAppSyncRetryAdvice(shouldRetry: false, retryInterval: nil)
    }
    
    static func getRandomBetween0And1() -> Float {
        return Float.random(in: 0...1)
    }

    /// Returns a delay in milliseconds for the current attempt number. The delay includes random jitter as
    /// described in https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
    static func retryDelayInMillseconds(for attemptNumber: Int) -> Int {
        let delay = Int(Double(truncating: pow(2.0, attemptNumber) as NSNumber) * 100.0 + Double(AWSAppSyncRetryHandler.getRandomBetween0And1() * AWSAppSyncRetryHandler.jitterMilliseconds))
        return delay
    }

    /// Returns the value of the "Retry-After" header as an Int, or nil if the value isn't present or cannot be converted to
    /// an Int
    ///
    /// - Parameter response: The response to get the header from
    /// - Returns: The value of the "Retry-After" header, or nil if not present or not convertable to Int
    private static func getRetryAfterHeaderValue(from response: HTTPURLResponse) -> Int? {
        let waitTime: Int?
        switch response.allHeaderFields["Retry-After"] {
        case let retryTime as String:
            waitTime = Int(retryTime)
        case let retryTime as Int:
            waitTime = retryTime
        default:
            waitTime = nil
        }

        return waitTime
    }

}
