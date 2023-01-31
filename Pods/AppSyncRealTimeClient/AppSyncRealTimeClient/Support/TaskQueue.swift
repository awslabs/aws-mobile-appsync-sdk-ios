//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if swift(>=5.5.2)

import Foundation

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
actor TaskQueue<Success> {
    private var previousTask: Task<Success, Error>?

    func sync(block: @Sendable @escaping () async throws -> Success) async throws {
        previousTask = Task { [previousTask] in
            _ = await previousTask?.result
            return try await block()
        }
        _ = try await previousTask?.value
    }

    nonisolated func async(block: @Sendable @escaping () async throws -> Success) rethrows {
        Task {
            try await sync(block: block)
        }
    }
}

#endif
