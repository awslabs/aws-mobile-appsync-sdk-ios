//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

/// Allows use of `isEmpty` on optional `Collection`s:
///     let optionalString: String? = getSomeOptionalString()
///     guard optionalString.isEmpty else { return }
///
/// `Collection` provides the `isEmpty` property to declare whether an instance has any members. But it’s also pretty common to
/// expand the definition of “empty” to include nil. Unfortunately, the standard library doesn't include an extension mapping
/// the Collection.isEmpty property, so testing Optional collections means you have to unwrap:
///
///     var optionalString: String?
///     // Do some work
///     if let s = optionalString where s != "" {
///         // s is not empty or nil
///     }
///
/// Or slightly more succinctly, use the nil coalescing operator “??”:
///
///     if !(optionalString ?? "").isEmpty {
///         // optionalString is not empty or nil
///     }
///
/// This extension simply unwraps the `Optional` and returns the value of `isEmpty` for non-nil collections, and returns `true`
/// if the collection is nil.
extension Optional where Wrapped: Collection {
    /// Returns `true` for nil values, or `value.isEmpty` for non-nil values.
    var isEmpty: Bool {
        switch self {
        case .some(let val):
            return val.isEmpty
        case .none:
            return true
        }
    }
}

extension DispatchSource {
    /// Convenience function to encapsulate creation of a one-off DispatchSourceTimer for different versions of Swift
    ///
    /// - Parameters:
    ///   - interval: The future DispatchInterval at which to fire the timer
    ///   - queue: The queue on which the timer should perform its block
    ///   - block: The block to invoke when the timer is fired
    /// - Returns: The unstarted timer
    static func makeOneOffDispatchSourceTimer(interval: DispatchTimeInterval, queue: DispatchQueue, block: @escaping () -> Void ) -> DispatchSourceTimer {
        let deadline = DispatchTime.now() + interval
        return makeOneOffDispatchSourceTimer(deadline: deadline, queue: queue, block: block)
    }

    /// Convenience function to encapsulate creation of a one-off DispatchSourceTimer for different versions of Swift
    /// - Parameters:
    ///   - deadline: The time to fire the timer
    ///   - queue: The queue on which the timer should perform its block
    ///   - block: The block to invoke when the timer is fired
    static func makeOneOffDispatchSourceTimer(deadline: DispatchTime, queue: DispatchQueue, block: @escaping () -> Void ) -> DispatchSourceTimer {
        let timer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: 0), queue: queue)
        #if swift(>=4)
        timer.schedule(deadline: deadline)
        #else
        timer.scheduleOneshot(deadline: deadline)
        #endif
        timer.setEventHandler(handler: block)
        return timer
    }

}
