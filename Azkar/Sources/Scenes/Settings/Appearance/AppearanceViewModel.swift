// Copyright © 2023 Azkar
// All Rights Reserved.

import UIKit
import AzkarServices

final class AppearanceViewModel: SettingsSectionViewModel {
    
    var canChangeIcon: Bool {
        return !UIDevice.current.isMac
    }
    
    var themeTitle: String {
        var title = ""
        if preferences.appTheme != .default {
            title += preferences.appTheme.title
        }
        if preferences.colorTheme != .default {
            title += title.isEmpty ? preferences.colorTheme.title : ", \(preferences.colorTheme.title)"
        }
        return title
    }
    
    var appIconPackListViewModel: AppIconPackListViewModel {
        AppIconPackListViewModel(
            subscribeScreenTrigger: { [unowned navigator] in
                navigator.presentSubscription(sourceScreen: AppIconPackListView.viewName)
            }
        )
    }
    
    var colorSchemeViewModel: ColorSchemesViewModel {
        ColorSchemesViewModel { [unowned navigator] in
            navigator.presentSubscription(sourceScreen: ColorSchemesView.viewName)
        }
    }
    
}
