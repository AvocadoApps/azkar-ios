import WidgetKit

@available(iOS 17, *)
enum ZikrCounterWidgetReloader {
    static func reloadAll() {
        WidgetCenter.shared.reloadTimelines(ofKind: ZikrCounterWidgetKind.value)
        WidgetCenter.shared.reloadTimelines(ofKind: "AzkarCompletionWidgets")
        WidgetCenter.shared.reloadTimelines(ofKind: "AzkarCategoryQuickAccess")
        WidgetCenter.shared.reloadTimelines(ofKind: "AzkarStreak")
    }
}
