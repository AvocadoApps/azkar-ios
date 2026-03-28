// Copyright © 2023 Al Jawziyya.
// All Rights Reserved.

import WidgetKit
import SwiftUI

@main
struct AzkarWidgetsLauncher {
    static func main() {
        if #available(iOSApplicationExtension 17, *) {
            AzkarWidgetsBundleWithStreak.main()
        } else if #available(iOSApplicationExtension 16.2, *) {
            AzkarWidgetsBundleModern.main()
        } else {
            AzkarWidgetsBundleLegacy.main()
        }
    }
}

struct AzkarWidgetsBundleLegacy: WidgetBundle {
    var body: some Widget {
        VirtuesWidgets()
    }
}

@available(iOSApplicationExtension 17, *)
struct AzkarWidgetsBundleWithStreak: WidgetBundle {
    var body: some Widget {
        VirtuesWidgets()
        CompletionWidgets()
        CategoryQuickAccessWidget()
        StreakWidget()
        AzkarReadingLiveActivity()
    }
}

@available(iOSApplicationExtension 16.2, *)
struct AzkarWidgetsBundleModern: WidgetBundle {
    var body: some Widget {
        VirtuesWidgets()
        CompletionWidgets()
        CategoryQuickAccessWidget()
        AzkarReadingLiveActivity()
    }
}
