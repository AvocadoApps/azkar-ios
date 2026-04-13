//
//  AppIcon.swift
//  Azkar
//
//  Created by Abdurahim Jauzee on 13.05.2020.
//  Copyright © 2020 Al Jawziyya. All rights reserved.
//

import SwiftUI

enum AppIconPack: String, CaseIterable, Identifiable, Codable {
    case standard
    case pro

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .standard: return String(localized: "icon_pack.standard.title")
        case .pro: return "PRO"
        }
    }

    var link: URL? {
        switch self {
        case .standard, .pro:
            return nil
        }
    }

    var icons: [AppIcon] {
        switch self {
        case .standard:
            return AppIcon.standardIcons
        case .pro:
            return AppIcon.proIcons
        }
    }

}

enum AppIcon: String, Codable, CaseIterable, Identifiable, Hashable {

    case gold, ink
    case midjourney001
    case azure, cookie
    
    case light, crescent, spring, vibrantMoon, serpentine, adhkar

    static var standardIcons: [AppIcon] {
        [gold, ink, midjourney001, azure, cookie]
    }
    
    static var proIcons: [AppIcon] {
        [light, crescent, spring, vibrantMoon, serpentine, adhkar]
    }

    var id: String { rawValue }

    var title: String {
        switch self {
        case .midjourney001:
            return "MidJourney x Azkar 0.0.1"
        case .crescent, .spring, .vibrantMoon, .light, .serpentine:
            return NSLocalizedString("settings.icon.pro.\(rawValue)", comment: "")
        case .adhkar:
            return "أذكار"
        default:
            return NSLocalizedString("settings.icon.list.\(rawValue)", comment: "")
        }
    }

    var referenceName: String {
        rawValue
    }

    var iconImageName: String {
        return "IconPreviews/\(rawValue)"
    }

}
