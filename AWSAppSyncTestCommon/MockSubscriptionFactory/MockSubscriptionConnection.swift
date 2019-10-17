//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
@testable import AWSAppSync

class MockSubscriptionConnection: SubscriptionConnection {

    /// Current item that is subscriped
    var subscriptionItem: SubscriptionItem!

    func subscribe(requestString: String,
                   variables: [String : Any]?,
                   eventHandler: @escaping SubscriptionEventHandler) -> SubscriptionItem {
        subscriptionItem = SubscriptionItem(requestString: requestString,
                                            variables: variables,
                                            eventHandler: eventHandler)
        
        return subscriptionItem
    }

    func unsubscribe(item: SubscriptionItem) {

    }


}
