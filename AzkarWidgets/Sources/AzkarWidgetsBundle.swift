// Copyright © 2023 Al Jawziyya.
// All Rights Reserved.

import WidgetKit
import SwiftUI

@main
struct AzkarWidgetsLauncher {
    static func main() {
        if #available(iOSApplicationExtension 18, *) {
            AzkarWidgetsBundleWithControl.main()
        } else if #available(iOSApplicationExtension 17, *) {
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
        VirtuesWidget()
        ArticlesWidget()
    }
}

@available(iOSApplicationExtension 18, *)
struct AzkarWidgetsBundleWithControl: WidgetBundle {
    var body: some Widget {
        CategoryQuickAccessWidget()
        ZikrCounterWidget()
        StreakWidget()
        VirtuesWidget()
        ArticlesWidget()
        CompletionWidget()
        #if !targetEnvironment(macCatalyst)
        AzkarReadingLiveActivity()
        #endif
        AzkarControlCenterWidget()
    }
}

@available(iOSApplicationExtension 17, *)
struct AzkarWidgetsBundleWithStreak: WidgetBundle {
    var body: some Widget {
        CategoryQuickAccessWidget()
        ZikrCounterWidget()
        StreakWidget()
        VirtuesWidget()
        ArticlesWidget()
        CompletionWidget()
        #if !targetEnvironment(macCatalyst)
        AzkarReadingLiveActivity()
        #endif
    }
}

@available(iOSApplicationExtension 16.2, *)
struct AzkarWidgetsBundleModern: WidgetBundle {
    var body: some Widget {
        CategoryQuickAccessWidget()
        VirtuesWidget()
        ArticlesWidget()
        CompletionWidget()
        #if !targetEnvironment(macCatalyst)
        AzkarReadingLiveActivity()
        #endif
    }
}
