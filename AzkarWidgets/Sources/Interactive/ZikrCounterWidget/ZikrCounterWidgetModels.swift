import Foundation
import WidgetKit
import Entities

@available(iOS 17, *)
struct ZikrCounterWidgetEntry: TimelineEntry {
    let date: Date
    let item: ZikrCounterWidgetItem?
    let completionState: CompletionState
    let showsCategorySuggestions: Bool
    let isCompletedForToday: Bool
    let isPlaceholder: Bool
}

@available(iOS 17, *)
struct ZikrCounterWidgetItem {
    let zikrID: Int
    let category: ZikrCategory
    let title: String?
    let textSnippet: String
    let isRightToLeftText: Bool
    let remainingCount: Int
    let totalRepeats: Int
    let positionInCategory: Int
    let totalInCategory: Int

    static func placeholder(textMode: ZikrCounterTextMode) -> ZikrCounterWidgetItem {
        ZikrCounterWidgetItem(
            zikrID: 1,
            category: .morning,
            title: nil,
            textSnippet: textMode == .original ? "الحمد لله" : String(localized: "widget.next.placeholder.translation", bundle: .main),
            isRightToLeftText: textMode == .original,
            remainingCount: 0,
            totalRepeats: 1,
            positionInCategory: 1,
            totalInCategory: 10
        )
    }

    var progressText: String {
        "\(positionInCategory)/\(totalInCategory)"
    }

    var deepLinkURL: URL {
        WidgetCategoryMetadata.deepLinkURL(for: category, zikrID: zikrID)
    }
}

@available(iOS 17, *)
struct ZikrCounterWidgetSelectionState: Codable {
    let dayKey: Int
    let activeCategoryRawValue: String?
    let showsCategorySuggestions: Bool

    var activeCategory: ZikrCategory? {
        activeCategoryRawValue.flatMap(ZikrCategory.init(rawValue:))
    }

    static func automatic(dayKey: Int) -> ZikrCounterWidgetSelectionState {
        ZikrCounterWidgetSelectionState(
            dayKey: dayKey,
            activeCategoryRawValue: nil,
            showsCategorySuggestions: false
        )
    }

    static func active(category: ZikrCategory, dayKey: Int) -> ZikrCounterWidgetSelectionState {
        ZikrCounterWidgetSelectionState(
            dayKey: dayKey,
            activeCategoryRawValue: category.rawValue,
            showsCategorySuggestions: false
        )
    }

    static func suggestions(dayKey: Int) -> ZikrCounterWidgetSelectionState {
        ZikrCounterWidgetSelectionState(
            dayKey: dayKey,
            activeCategoryRawValue: nil,
            showsCategorySuggestions: true
        )
    }
}
