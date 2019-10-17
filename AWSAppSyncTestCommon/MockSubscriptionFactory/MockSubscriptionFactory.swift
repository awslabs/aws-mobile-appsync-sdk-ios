//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
@testable import AWSAppSync

class MockSubscriptionFactory: SubscriptionConnectionFactory {

    func connection(connectionType: SubscriptionConnectionType) -> SubscriptionConnection? {
        let connection = MockSubscriptionConnection()
        return connection
    }

}
