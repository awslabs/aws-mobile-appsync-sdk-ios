//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public enum AppSyncJSONHelper {

    public static func base64AuthenticationBlob(_ header: AuthenticationHeader ) -> String {
        let jsonEncoder = JSONEncoder()
        do {
            let jsonHeader = try jsonEncoder.encode(header)
            AppSyncLogger.verbose("Generated Header for request - \(String(describing: String(data: jsonHeader, encoding: .utf8)))")
            return jsonHeader.base64EncodedString()
        } catch {
            AppSyncLogger.error(error.localizedDescription)
        }
        return ""
    }
}
