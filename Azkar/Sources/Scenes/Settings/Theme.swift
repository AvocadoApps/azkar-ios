//
//  Theme.swift
//  Azkar
//
//  Created by Abdurahim Jauzee on 13.05.2020.
//  Copyright © 2020 Al Jawziyya. All rights reserved.
//

import SwiftUI

enum Theme: Int, Codable, CaseIterable, Identifiable, PickableItem, Hashable {
    case automatic, light, dark

    var id: Int {
        return rawValue
    }

    var title: String {
        switch self {
        case .automatic:
            return String(localized: "settings.appearance.color-scheme.auto.title")
        case .light:
            return String(localized: "settings.appearance.color-scheme.light.title")
        case .dark:
            return String(localized: "settings.appearance.color-scheme.dark.title")
        }
    }
    
    var description: String {
        switch self {
        case .automatic:
            return String(localized: "settings.appearance.color-scheme.auto.description")
        case .light:
            return String(localized: "settings.appearance.color-scheme.light.description")
        case .dark:
            return String(localized: "settings.appearance.color-scheme.dark.description")
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        default:
            return nil
        }
    }

    var statusBarStyle: UIStatusBarStyle? {
        switch self {
        case .automatic:
            return nil
        case .light:
            return .darkContent
        case .dark:
            return .lightContent
        }
    }

    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .automatic:
            return .unspecified
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

}
