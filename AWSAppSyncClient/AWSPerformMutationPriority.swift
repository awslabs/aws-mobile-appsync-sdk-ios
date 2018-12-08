//
//  AWSPerformMutationPriority.swift
//  AWSAppSync
//
//  Created by Ilya Laryionau on 08/12/2018.
//  Copyright © 2018 Dubal, Rohan. All rights reserved.
//

import Foundation

public enum AWSPerformMutationPriority: Int {
    case veryLow = -10
    case low = -20
    case normal = 0
    case high = 10
    case veryHigh = 20
}

// MARK: - CustomStringConvertible

extension AWSPerformMutationPriority: CustomStringConvertible {
    public var description: String {
        switch self {
        case .veryLow: return "veryLow"
        case .low: return "low"
        case .normal: return "normal"
        case .high: return "high"
        case .veryHigh: return "veryHigh"
        }
    }
}

// MARK: - Operation.QueuePriority

extension AWSPerformMutationPriority {

    var operationQueuePriority: Operation.QueuePriority {
        switch self {
        case .veryLow: return .veryLow
        case .low: return .low
        case .normal: return .normal
        case .high: return .high
        case .veryHigh: return .veryHigh
        }
    }
}
