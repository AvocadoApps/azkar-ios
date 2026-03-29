import Foundation
import WidgetKit

@available(iOS 17, *)
struct ZikrCounterWidgetProvider: AppIntentTimelineProvider {
    typealias Entry = ZikrCounterWidgetEntry
    typealias Intent = ZikrCounterWidgetIntent

    private let dataSource = ZikrCounterWidgetDataSource()

    func placeholder(in context: Context) -> Entry {
        ZikrCounterWidgetEntry(
            date: Date(),
            item: ZikrCounterWidgetItem.placeholder(textMode: .original),
            completionState: .none,
            showsCategorySuggestions: false,
            isCompletedForToday: false,
            isPlaceholder: false
        )
    }

    func snapshot(for configuration: Intent, in context: Context) async -> Entry {
        await dataSource.resolveEntry(textMode: configuration.textMode)
    }

    func timeline(for configuration: Intent, in context: Context) async -> Timeline<Entry> {
        let entry = await dataSource.resolveEntry(textMode: configuration.textMode)
        let tomorrow = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        return Timeline(entries: [entry], policy: .after(tomorrow))
    }
}
