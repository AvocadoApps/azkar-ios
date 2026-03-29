import SwiftUI
import WidgetKit

@available(iOS 17, *)
struct StreakWidget: Widget {
    let kind = "AzkarStreak"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: StreakWidgetIntent.self,
            provider: StreakWidgetProvider()
        ) { entry in
            let tier = StreakWidgetTier(streakCount: entry.streakCount)
            StreakWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    ZStack {
                        Color(.systemBackground)
                        if let tint = tier.backgroundTint {
                            RadialGradient(
                                colors: [tint.opacity(tier.backgroundOpacity), .clear],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 200
                            )
                        }
                    }
                }
        }
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
        .containerBackgroundRemovable()
        .configurationDisplayName("widget.streak.title")
        .description("widget.streak.description")
    }
}
