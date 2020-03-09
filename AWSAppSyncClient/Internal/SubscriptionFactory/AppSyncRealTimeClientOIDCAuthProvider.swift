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

    func getLatestAuthToken() -> Swift.Result<String, Error> {
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

            if let error = authError {
                return .failure(error)
            }

            if let token = jwtToken {
                return .success(token)
            }
        }

        if let asyncAuthProvider = authProvider as? AWSOIDCAuthProviderAsync {
            let semaphore = DispatchSemaphore(value: 0)
            asyncAuthProvider.getLatestAuthToken { (token, error) in
                jwtToken = token
                authError = error
                semaphore.signal()
            }
            semaphore.wait()
            if let error = authError {
                return .failure(error)
            }

            if let token = jwtToken {
                return .success(token)
            }
        }

        return .success(authProvider.getLatestAuthToken())
    }
}
