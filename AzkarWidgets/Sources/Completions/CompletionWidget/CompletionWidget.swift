import SwiftUI
import WidgetKit

@available(iOS 16, *)
struct CompletionWidget: Widget {
    let kind = "AzkarCompletionWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: CompletionWidgetProvider()
        ) { entry in
            CompletionWidgetView(completionState: entry.completionState)
        }
        .supportedFamilies([.accessoryCircular])
        .containerBackgroundRemovable()
        .configurationDisplayName("widget.completion.title")
        .description("widget.completion.description")
    }
}
