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
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(context.attributes.categoryName)
                    } icon: {
                        Image(systemName: context.attributes.categoryIcon)
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 6)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.progressText)
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .contentTransition(.numericText())
                        .foregroundStyle(.primary)
                        .padding(.trailing, 6)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 4) {
                        ProgressView(value: context.state.progress)
                            .tint(Color.accentColor)

                        if context.state.isCompleted {
                            Label {
                                Text("widget.liveActivity.completed")
                            } icon: {
                                Image(systemName: "checkmark.circle.fill")
                            }
                            .font(.caption2)
                            .foregroundStyle(.green)
                        } else {
                            HStack {
                                Text(context.state.currentZikrTitle)
                                    .font(.caption2)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .foregroundStyle(.secondary)

                                Spacer(minLength: 4)

                                if context.state.currentZikrRemainingRepeats > 0 {
                                    Text(remainingRepeatsText(for: context.state))
                                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                                        .contentTransition(.numericText())
                                        .foregroundStyle(.secondary)
                                        .layoutPriority(1)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 6)
                }
            } compactLeading: {
                Image(systemName: context.attributes.categoryIcon)
                    .font(.caption2)
                    .foregroundStyle(.primary)
            } compactTrailing: {
                Text(context.state.progressText)
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .contentTransition(.numericText())
                    .foregroundStyle(.primary)
            } minimal: {
                Image(systemName: context.attributes.categoryIcon)
                    .font(.caption2)
                    .foregroundStyle(.primary)
            }
            .widgetURL(URL(string: "azkar://category/\(context.attributes.categoryRawValue)")!)
        }
    }

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<AzkarReadingActivityAttributes>) -> some View {
        let deepLink = URL(string: "azkar://category/\(context.attributes.categoryRawValue)")!

        Link(destination: deepLink) {
            VStack(spacing: 10) {
                HStack {
                    Label {
                        Text(context.attributes.categoryName)
                    } icon: {
                        Image(systemName: context.attributes.categoryIcon)
                    }
                    .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(context.state.progressText)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .contentTransition(.numericText())
                }

                ProgressView(value: context.state.progress)
                    .tint(Color.accentColor)

                HStack {
                    if context.state.isCompleted {
                        Label {
                            Text("widget.liveActivity.completed")
                        } icon: {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        .font(.caption)
                        .foregroundStyle(.green)
                    } else {
                        Text(context.state.currentZikrTitle)
                            .font(.caption)
                            .lineLimit(1)
                            .foregroundStyle(.secondary)

                        Spacer()

                        if context.state.currentZikrRemainingRepeats > 0 {
                            Text(remainingRepeatsText(for: context.state))
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                                .contentTransition(.numericText())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.horizontal, 26)
            .padding(.vertical, 16)
        }
        .activityBackgroundTint(.clear)
    }

    // MARK: - Helpers

    /// Formats remaining repeats using widget bundle localizations.
    private func remainingRepeatsText(for state: AzkarReadingActivityAttributes.ContentState) -> String {
        if state.currentZikrRemainingRepeats == state.currentZikrTotalRepeats {
            return String(format: String(localized: "widget.liveActivity.remaining-repeats"), locale: Locale.current, state.currentZikrTotalRepeats)
        } else if state.currentZikrRemainingRepeats == 0 {
            return String(localized: "widget.liveActivity.remaining-repeats.completed")
        } else {
            return String(format: String(localized: "widget.liveActivity.remaining-repeats"), locale: Locale.current, state.currentZikrRemainingRepeats)
        }
    }
}

@available(iOS 17, *)
#Preview("Live Activity", as: .content, using: AzkarReadingActivityAttributes(
    categoryName: "Morning Adhkar",
    categoryRawValue: "morning",
    categoryIcon: "sun.max.fill",
    categoryImageName: "categories/morning"
)) {
    AzkarReadingLiveActivity()
} contentStates: {
    AzkarReadingActivityAttributes.ContentState(
        currentPage: 3,
        totalPages: 12,
        completedRepeats: 25,
        totalRepeats: 150,
        currentZikrTitle: "سبحان الله وبحمده",
        currentZikrRemainingRepeats: 3,
        currentZikrTotalRepeats: 10,
        isCompleted: false
    )
    AzkarReadingActivityAttributes.ContentState(
        currentPage: 12,
        totalPages: 12,
        completedRepeats: 150,
        totalRepeats: 150,
        currentZikrTitle: "",
        currentZikrRemainingRepeats: 0,
        currentZikrTotalRepeats: 0,
        isCompleted: true
    )
}
#endif
