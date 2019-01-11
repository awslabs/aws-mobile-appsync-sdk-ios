//
// Copyright 2010-2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//

import Foundation

extension AWSAppSyncClientError {

    @available(*, deprecated, message: "use the enum pattern matching instead")
    public var body: Data? {
        switch self {
        case .parseError(let data, _, _):
            return data
        case .requestFailed(let data, _, _):
            return data
        case .noData, .authenticationError:
            return nil
        }
    }

    @available(*, deprecated, message: "use the enum pattern matching instead")
    public var response: HTTPURLResponse? {
        switch self {
        case .parseError(_, let response, _):
            return response
        case .requestFailed(_, let response, _):
            return response
        case .noData, .authenticationError:
            return nil
        }
    }

    @available(*, deprecated)
    var isInternalError: Bool {
        return false
    }

    @available(*, deprecated, message: "use errorDescription instead")
    var additionalInfo: String? {
        switch self {
        case .parseError:
            return "Could not parse response data."
        case .requestFailed:
            return "Did not receive a successful HTTP code."
        case .noData, .authenticationError:
            return "No Data received in response."
        }
    }
}
