//
// Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
import AppSyncRealTimeClient

class AppSyncRealTimeClientOIDCAuthProvider: OIDCAuthProvider {
    let authProvider: AWSOIDCAuthProvider
    init(authProvider: AWSOIDCAuthProvider) {
        self.authProvider = authProvider
    }

    public func getLatestAuthToken(_ callback: @escaping (String?, Error?) -> Void) {
        getToken(callback)
    }

    private func getToken(_ callback: (String?, Error?) -> Void) {
        var jwtToken: String?
        var authError: Error?

        if let asyncAuthProvider = authProvider as? AWSCognitoUserPoolsAuthProviderAsync {
            let semaphore = DispatchSemaphore(value: 0)
            asyncAuthProvider.getLatestAuthToken { (token, error) in
                jwtToken = token
                authError = error
                semaphore.signal()
            }
            semaphore.wait()
            callback(jwtToken, authError)
            return
        }

        if let asyncAuthProvider = authProvider as? AWSOIDCAuthProviderAsync {
            let semaphore = DispatchSemaphore(value: 0)
            asyncAuthProvider.getLatestAuthToken { (token, error) in
                jwtToken = token
                authError = error
                semaphore.signal()
            }
            semaphore.wait()
            callback(jwtToken, authError)
            return
        }

        jwtToken = authProvider.getLatestAuthToken()
        callback(jwtToken, authError)
    }
}
