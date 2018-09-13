//
//  AWSAppSyncRetryHandler.swift
//  AWSAppSync
//
//  Created by Dubal, Rohan on 9/12/18.
//  Copyright © 2018 Dubal, Rohan. All rights reserved.
//

import Foundation

protocol AWSAppSyncRetryHandler {
    func shouldRetryRequest() -> Bool
}

