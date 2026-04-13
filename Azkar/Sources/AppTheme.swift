// Copyright © 2021 Al Jawziyya. All rights reserved. 

import SwiftUI
import Library

extension ColorTheme: PickableItem {
    var title: String {
        switch self {
        case .sea:
            return String(localized: "settings.appearance.color-theme.sea")
        case .purpleRose:
            return String(localized: "settings.appearance.color-theme.purple-rose")
        case .ink:
            return String(localized: "settings.appearance.color-theme.ink")
        case .roseQuartz:
            return String(localized: "settings.appearance.color-theme.rose-quartz")
        case .forest:
            return String(localized: "settings.appearance.color-theme.forest")
        case .default:
            return String(localized: "common.default")
        }
    }
}

extension AppTheme: PickableItem {
    
    var title: String {
        switch self {
        case .reader:
            return String(localized: "settings.appearance.app-theme.reader")
        case .code:
            return "c0de"
        case .flat:
            return String(localized: "settings.appearance.app-theme.flat")
        case .neomorphic:
            return "Neomorphic"
        case .default:
            return String(localized: "common.default")
        }
    }

}
