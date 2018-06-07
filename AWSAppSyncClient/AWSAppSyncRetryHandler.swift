//
//  AWSAppSyncRetryHandler.swift
//  AWSAppSync
//

import Foundation

internal class AWSAppSyncRetryHandler {
    
    var currentAttemptNumber = 0
    static let MAX_RETRY_WAIT_MILLIS = 300 * 1000 // 5 minutes of max retry duration.
    static let JITTER: Float = 100.0
    
    internal  init() { }
    
    /// Returns if a request should be retried
    ///
    /// - Parameter error: The error returned by the service.
    /// - Returns: If the request should be retried and if yes, after how much time.
    func shouldRetryRequest(for error: AWSAppSyncClientError) -> (Bool, Int?) {
        let httpResponse: HTTPURLResponse?
        switch error {
        case .requestFailed(_, let reponse, _):
            httpResponse = reponse
        case .noData(let response):
            httpResponse = response
        case .parseError(_, let response, _):
            httpResponse = response
        case .authenticationError(_):
            httpResponse = nil
        }
        
        guard let unwrappedResponse = httpResponse  else {
            return (false, nil)
        }
        
        currentAttemptNumber += 1
        let waitTime = unwrappedResponse.allHeaderFields["Retry-After"] as? Int
        if let waitTime = waitTime {
            let waitMillis = waitTime * 1000
            return (true, waitMillis)
        }
        
        switch unwrappedResponse.statusCode {
        case 500 ... 599, 429:
            let waitMillis = Int(Double(pow(2.0, currentAttemptNumber) as NSNumber) * 100.0 + Double(getRandomBetween0And1() * AWSAppSyncRetryHandler.JITTER))
            if (waitMillis > AWSAppSyncRetryHandler.MAX_RETRY_WAIT_MILLIS) {
                break
            } else {
                return(true, waitMillis)
            }
        default:
            break
        }
        return(false, nil)
    }
    
    private func getRandomBetween0And1() -> Float {
        return Float(arc4random()) / Float(UINT32_MAX)
    }
}
