//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A resettable timer that executes `onCountdownComplete` closure after
/// `interval`.
///
/// The timer will execute the closure on a background queue. If the closure
/// includes work that must be performed on a specific queue, make sure to dispatch
/// it inside the closure.
class CountdownTimer {
    private static let defaultInterval: TimeInterval = 5 * 60

    /// The interval in seconds of the timer
    private var _interval: TimeInterval?
    private let lock: NSLock
    private var workItem: DispatchWorkItem?
    private var onCountdownComplete: (() -> Void)?

    init() {
        self.lock = NSLock()
    }

    var interval: TimeInterval {
        _interval ?? CountdownTimer.defaultInterval
    }

    /// Starts the countdown of the timer with `interval` and perform
    ///
    /// - Parameters:
    ///   - interval: The interval after which the timer will fire, and be reset on.
    ///   - onCountdownComplete: The closure to perform when the timer fires.
    func start(interval: TimeInterval, onCountdownComplete: @escaping () -> Void) {
        lock.lock()
        defer {
            lock.unlock()
        }
        _interval = interval
        self.onCountdownComplete = onCountdownComplete
        cancelAndClearWorkItem()
        createAndScheduleTimer(interval: interval)
    }

    /// Resets the timer to begin counting down from the `interval` again.
    ///
    /// - Parameter interval: Optionally pass in a new interval for the timer.
    func reset(interval: TimeInterval? = nil) {
        lock.lock()
        defer {
            lock.unlock()
        }
        if let interval = interval {
            _interval = interval
        }
        cancelAndClearWorkItem()
        createAndScheduleTimer(interval: self.interval)
    }

    /// Invalidates/stops the timer
    func invalidate() {
        lock.lock()
        defer {
            lock.unlock()
        }
        cancelAndClearWorkItem()
    }

    // MARK: - Private helpers

    /// Invoked  by all puclic methods (`start`, `reset`, `invalidate`) to clear the previous timer
    private func cancelAndClearWorkItem() {
        guard let workItem = workItem else {
            return
        }

        workItem.cancel()
        self.workItem = nil
    }

    /// Invoked by the timer. Do not execute this method directly.
    private func timerFired() {
        lock.lock()
        defer {
            workItem = nil
            lock.unlock()
        }

        guard let workItem = workItem, !workItem.isCancelled else {
            return
        }

        onCountdownComplete?()
    }

    /// Invoked by `start` and `reset` when creating a new timer.
    private func createAndScheduleTimer(interval: TimeInterval) {
        let workItem = DispatchWorkItem { self.timerFired() }
        self.workItem = workItem
        DispatchQueue.global().asyncAfter(deadline: .now() + interval, execute: workItem)
    }
}
