// Copyright © 2021 Al Jawziyya. All rights reserved. 

import Foundation
import FactoryKit

struct SubscriptionManagerFactory {

    static func create() -> SubscriptionManagerType {
        Container.shared.subscriptionManager()
    }

}
