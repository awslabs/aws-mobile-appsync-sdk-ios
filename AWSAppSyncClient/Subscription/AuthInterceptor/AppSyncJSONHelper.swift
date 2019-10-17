//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

struct AppSyncJSONHelper {

    static func base64AuthenticationBlob(_ header: AuthenticationHeader ) -> String {
        let jsonEncoder = JSONEncoder()
        do {
            let jsonHeader = try jsonEncoder.encode(header)
            AppSyncLog.verbose("Header - \(String(describing: String(data: jsonHeader, encoding: .utf8)))")
            return jsonHeader.base64EncodedString()
        } catch {
            AppSyncLog.error(error)
        }
        return ""
    }
}
