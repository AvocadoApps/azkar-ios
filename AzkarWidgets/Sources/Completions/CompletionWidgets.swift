import WidgetKit
import SwiftUI
import AzkarServices
import DatabaseInteractors

@available(iOS 16, *)
struct CompletionWidgets: Widget {
    
    let kind = "AzkarCompletionWidgets"
    
    var body: some WidgetConfiguration {
        appIcon
            .supportedFamilies([.accessoryCircular])
            .containerBackgroundRemovable()
    }
    
    var appIcon: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: CompletionWidgetsTimelineProvider(
                zikrCounterService: DatabaseZikrCounter(
                    databasePath: FileManager.default
                        .appGroupContainerURL
                        .appendingPathComponent("counter.db")
                        .absoluteString,
                    getKey: {
                        let startOfDay = Calendar.current.startOfDay(for: Date())
                        return Int(startOfDay.timeIntervalSince1970)
                    }
                )
            ),
            content: { entry in
                CompletionCircleView(completionState: entry.completionState)
            }
        )
        .supportedFamilies([.accessoryCircular])
        .configurationDisplayName("widgets.completion.title")
        .description("widgets.completion.description")
    }
    
}

@available(iOS 17, *)
#Preview("None", as: .accessoryCircular) {
    CompletionWidgets()
} timeline: {
    CompletionWidgetsEntry(completionState: .none)
}

@available(iOS 17, *)
#Preview("Morning", as: .accessoryCircular) {
    CompletionWidgets()
} timeline: {
    CompletionWidgetsEntry(completionState: .morning)
}

@available(iOS 17, *)
#Preview("Evening", as: .accessoryCircular) {
    CompletionWidgets()
} timeline: {
    CompletionWidgetsEntry(completionState: .evening)
}

@available(iOS 17, *)
#Preview("Night", as: .accessoryCircular) {
    CompletionWidgets()
} timeline: {
    CompletionWidgetsEntry(completionState: .night)
}

@available(iOS 17, *)
#Preview("Morning & Evening", as: .accessoryCircular) {
    CompletionWidgets()
} timeline: {
    CompletionWidgetsEntry(completionState: .morningEvening)
}

@available(iOS 17, *)
#Preview("All", as: .accessoryCircular) {
    CompletionWidgets()
} timeline: {
    CompletionWidgetsEntry(completionState: .all)
}
