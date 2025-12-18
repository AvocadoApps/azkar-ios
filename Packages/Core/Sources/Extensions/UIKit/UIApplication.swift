//
//
//  Azkar
//  
//  Created on 06.05.2021
//  Copyright © 2021 Al Jawziyya. All rights reserved.
//  

import UIKit

public extension UIApplication {

    var inSandboxMode: Bool {
        return Bundle.main.appStoreReceiptURL?.path.contains("sandboxReceipt") == true
    }

    var isRanInSimulator: Bool {
        return Bundle.main.appStoreReceiptURL?.path.contains("CoreSimulator") == true
    }

    var inDebugMode: Bool {
        #if DEBUG
        return true
        #else
        if CommandLine.arguments.contains("--debug") {
            return true
        }

        return isRanInSimulator
        #endif
    }

    var shouldSendAnalytics: Bool {
        #if DEBUG
        return CommandLine.arguments.contains("SEND_ANALYTICS")
        #else
        return true
        #endif
    }

    var inTestMode: Bool {
        inSandboxMode || isRanInSimulator || inDebugMode
    }

}
