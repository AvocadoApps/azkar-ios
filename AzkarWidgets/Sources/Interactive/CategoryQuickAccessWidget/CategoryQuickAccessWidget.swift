import SwiftUI
import WidgetKit

@available(iOS 16, *)
struct CategoryQuickAccessWidget: Widget {
    let kind = "AzkarCategoryQuickAccess"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: CategoryQuickAccessWidgetProvider()
        ) { entry in
            if #available(iOS 17, *) {
                CategoryQuickAccessWidgetView(entry: entry)
                    .containerBackground(for: .widget) {
                        Color(.systemBackground)
                    }
            } else {
                CategoryQuickAccessWidgetView(entry: entry)
                    .padding()
                    .background(Color(.systemBackground))
            }
        }
        .supportedFamilies([.systemSmall, .systemMedium])
        .configurationDisplayName("widget.categories.title")
        .description("widget.categories.description")
    }
}
