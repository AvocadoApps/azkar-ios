import Foundation
import WidgetKit
import Entities

@available(iOS 17, *)
struct ZikrCounterWidgetEntry: TimelineEntry {
    let date: Date
    let item: ZikrCounterWidgetItem?
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
            positionInCategory: 1,
            totalInCategory: 10
        )
    }

    var progressText: String {
        "\(positionInCategory)/\(totalInCategory)"
    }

    var deepLinkURL: URL {
        URL(string: "azkar://zikr/\(zikrID)")!
    }
}
