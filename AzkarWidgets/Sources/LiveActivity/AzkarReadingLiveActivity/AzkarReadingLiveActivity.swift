#if canImport(ActivityKit)
import ActivityKit
import WidgetKit
import SwiftUI
import Entities

@available(iOS 16.2, *)
struct AzkarReadingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AzkarReadingActivityAttributes.self) { context in
            lockScreenView(context: context)
        } dynamicIsland: { context in
            dynamicIsland(context: context)
                .widgetURL(URL(string: "azkar://category/\(context.attributes.categoryRawValue)")!)
        }
    }
}
#endif
