import WidgetKit

extension WidgetCenter {
    static func reloadAzkarWidgets() {
        WidgetCenter.shared.reloadTimelines(ofKind: "AzkarCompletionWidgets")
        WidgetCenter.shared.reloadTimelines(ofKind: "AzkarCategoryQuickAccess")
        WidgetCenter.shared.reloadTimelines(ofKind: "AzkarNextDhikrCounter")
        WidgetCenter.shared.reloadTimelines(ofKind: "AzkarStreak")
    }
}
