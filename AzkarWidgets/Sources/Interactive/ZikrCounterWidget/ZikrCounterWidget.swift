import SwiftUI
import WidgetKit

@available(iOS 17, *)
enum ZikrCounterWidgetKind {
    static let value = "AzkarZikrCounter"
}

@available(iOS 17, *)
struct ZikrCounterWidget: Widget {
    let kind = ZikrCounterWidgetKind.value

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ZikrCounterWidgetIntent.self,
            provider: ZikrCounterWidgetProvider()
        ) { entry in
            ZikrCounterWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(.systemBackground)
                }
        }
        .configurationDisplayName("widget.next.title")
        .description("widget.next.galleryDescription")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
