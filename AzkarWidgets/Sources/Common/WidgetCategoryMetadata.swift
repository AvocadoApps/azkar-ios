import Foundation
import SwiftUI
import Entities

struct WidgetCategoryMetadata {
    let titleKey: String
    let imageName: String
    let sfSymbolName: String?
    let tintColor: Color

    static func metadata(for category: ZikrCategory) -> WidgetCategoryMetadata {
        switch category {
        case .morning:
            return WidgetCategoryMetadata(
                titleKey: "widget.category.morning",
                imageName: "categories/morning",
                sfSymbolName: "sun.max.fill",
                tintColor: .yellow
            )
        case .evening:
            return WidgetCategoryMetadata(
                titleKey: "widget.category.evening",
                imageName: "categories/full-moon",
                sfSymbolName: "moon.fill",
                tintColor: .blue
            )
        case .night:
            return WidgetCategoryMetadata(
                titleKey: "widget.category.night",
                imageName: "categories/night",
                sfSymbolName: "bed.double.fill",
                tintColor: .blue
            )
        case .afterSalah:
            return WidgetCategoryMetadata(
                titleKey: "widget.category.afterSalah",
                imageName: "categories/after-salah",
                sfSymbolName: nil,
                tintColor: .green
            )
        case .other:
            return WidgetCategoryMetadata(
                titleKey: "widget.category.other",
                imageName: "categories/important-adhkar",
                sfSymbolName: "book.fill",
                tintColor: .secondary
            )
        case .hundredDua:
            return WidgetCategoryMetadata(
                titleKey: "widget.category.hundredDua",
                imageName: "categories/hundred-dua",
                sfSymbolName: "text.book.closed.fill",
                tintColor: .orange
            )
        }
    }

    static func controlCenterImageName(for category: ZikrCategory) -> String {
        switch category {
        case .morning: return "control-center-morning"
        case .evening: return "control-center-evening"
        default: return "control-center-night"
        }
    }

    static func localizedTitle(for category: ZikrCategory) -> String {
        NSLocalizedString(metadata(for: category).titleKey, bundle: .main, comment: "")
    }

    static func localizedTitle(for rawValue: String) -> String {
        guard let category = ZikrCategory(rawValue: rawValue) else {
            return String(localized: "widget.category.other", bundle: .main)
        }

        return localizedTitle(for: category)
    }

    static func deepLinkURL(for category: ZikrCategory, zikrID: Int? = nil) -> URL {
        if let zikrID {
            return URL(string: "azkar://category/\(category.rawValue)?zikr=\(zikrID)")!
        }

        return URL(string: "azkar://category/\(category.rawValue)")!
    }
}
