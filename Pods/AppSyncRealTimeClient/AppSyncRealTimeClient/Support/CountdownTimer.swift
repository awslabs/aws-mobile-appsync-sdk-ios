//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
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
    /// The interval after which the timer will fire
    let interval: TimeInterval

    private var workItem: DispatchWorkItem?
    private let onCountdownComplete: () -> Void

    init(interval: TimeInterval, onCountdownComplete: @escaping () -> Void) {
        self.interval = interval
        self.onCountdownComplete = onCountdownComplete
        createAndScheduleTimer()
    }

    /// Resets the countdown of the timer to `interval`
    func resetCountdown() {
        invalidate()
        createAndScheduleTimer()
    }

    /// Invalidates the timer
    func invalidate() {
        workItem?.cancel()
        workItem = nil
    }

    /// Invoked by the timer. Do not execute this method directly.
    private func timerFired() {
        defer {
            workItem = nil
        }

        guard let workItem = workItem, !workItem.isCancelled else {
            return
        }

        onCountdownComplete()
    }

    private func createAndScheduleTimer() {
        let workItem = DispatchWorkItem { self.timerFired() }
        self.workItem = workItem
        DispatchQueue.global().asyncAfter(deadline: .now() + interval, execute: workItem)
    }

}
