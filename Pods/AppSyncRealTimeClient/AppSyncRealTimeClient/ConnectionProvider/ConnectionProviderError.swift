//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public enum ConnectionProviderError: Error {

    /// Caused by connection error
    case connection

    /// Caused by JSON parse error. The first optional String will be the connection identifier if available.
    case jsonParse(String?, Error?)

    /// Caused when a limit exceeded error occurs. The optional String will have the identifier if available.
    case limitExceeded(String?)

    /// Caused when any other subscription related error occurs. The optional String
    /// will have the identifier if available. The second optional value is the error
    /// payload in dictionary format.
    case subscription(String, [String: Any]?)

    /// Caused when not authorized to establish the connection.
    case unauthorized

    /// Unknown error
    case unknown(message: String? = nil, causedBy: Error? = nil, payload: [String: Any]?)
}
