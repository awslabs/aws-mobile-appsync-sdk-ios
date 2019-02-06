//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

@testable import AWSAppSync

typealias BasicClosure = () -> Void

/// A mock that invokes a handler when `cancel` is invoked on it
class MockCancellable: Cancellable {
    private var handler: BasicClosure?

    /// Makes a MockCancellable with the supplied optional handler
    ///
    /// - Parameter handler: handler to call when `cancel` is invoked
    init(handler: BasicClosure? = nil) {
        self.handler = handler
    }

    /// Immediately invokes handler
    func cancel() {
        handler?()
    }
}

