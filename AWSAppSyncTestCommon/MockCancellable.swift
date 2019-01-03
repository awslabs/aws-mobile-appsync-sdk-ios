//
// Copyright 2010-2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

