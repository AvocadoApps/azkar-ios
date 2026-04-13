#if canImport(ActivityKit)
import ActivityKit
import WidgetKit
import SwiftUI
import Entities

@available(iOS 16.2, *)
extension AzkarReadingLiveActivity {
    func dynamicIsland(context: ActivityViewContext<AzkarReadingActivityAttributes>) -> DynamicIsland {
        let categoryTitle = WidgetCategoryMetadata.localizedTitle(for: context.attributes.categoryRawValue)

        return DynamicIsland {
            DynamicIslandExpandedRegion(.leading) {
                Label {
                    Text(categoryTitle)
                } icon: {
                    Image(systemName: context.attributes.categoryIcon)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.leading, 6)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(categoryTitle)
            }
            DynamicIslandExpandedRegion(.trailing) {
                Text(context.state.progressText)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .contentTransition(.numericText())
                    .foregroundStyle(.primary)
                    .padding(.trailing, 6)
                    .accessibilityLabel(Text("widget.liveActivity.progress"))
                    .accessibilityValue(context.state.progressText)
            }
            DynamicIslandExpandedRegion(.bottom) {
                VStack(spacing: 4) {
                    ProgressView(value: context.state.progress)
                        .tint(Color.accentColor)
                        .accessibilityLabel(Text("widget.liveActivity.progress"))
                        .accessibilityValue(activityAccessibilitySummary(for: context.state))

                    if context.state.isCompleted {
                        Label {
                            Text("widget.liveActivity.completed")
                        } icon: {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        .font(.caption2)
                        .foregroundStyle(.green)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text("widget.liveActivity.completed"))
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
                .accessibilityElement(children: .combine)
                .accessibilityLabel(activityAccessibilitySummary(for: context.state))
            }
        } compactLeading: {
            Image(systemName: context.attributes.categoryIcon)
                .font(.caption2)
                .foregroundStyle(.primary)
                .accessibilityLabel(categoryTitle)
        } compactTrailing: {
            Text(context.state.progressText)
                .font(.system(.caption2, design: .rounded, weight: .semibold))
                .contentTransition(.numericText())
                .foregroundStyle(.primary)
                .accessibilityLabel(Text("widget.liveActivity.progress"))
                .accessibilityValue(context.state.progressText)
        } minimal: {
            Image(systemName: context.attributes.categoryIcon)
                .font(.caption2)
                .foregroundStyle(.primary)
                .accessibilityLabel(categoryTitle)
        }
    }

    @ViewBuilder
    func lockScreenView(context: ActivityViewContext<AzkarReadingActivityAttributes>) -> some View {
        let deepLink = URL(string: "azkar://category/\(context.attributes.categoryRawValue)")!
        let categoryTitle = WidgetCategoryMetadata.localizedTitle(for: context.attributes.categoryRawValue)

        Link(destination: deepLink) {
            VStack(spacing: 10) {
                HStack {
                    Label {
                        Text(categoryTitle)
                    } icon: {
                        Image(systemName: context.attributes.categoryIcon)
                    }
                    .font(.subheadline.weight(.semibold))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(categoryTitle)

                    Spacer()

                    Text(context.state.progressText)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .contentTransition(.numericText())
                        .accessibilityLabel(Text("widget.liveActivity.progress"))
                        .accessibilityValue(context.state.progressText)
                }

                ProgressView(value: context.state.progress)
                    .tint(Color.accentColor)
                    .accessibilityLabel(Text("widget.liveActivity.progress"))
                    .accessibilityValue(activityAccessibilitySummary(for: context.state))

                HStack {
                    if context.state.isCompleted {
                        Label {
                            Text("widget.liveActivity.completed")
                        } icon: {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        .font(.caption)
                        .foregroundStyle(.green)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text("widget.liveActivity.completed"))
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
        .accessibilityLabel(lockScreenAccessibilityLabel(for: context))
        .accessibilityHint(Text("widget.liveActivity.a11y.open"))
        .activityBackgroundTint(.clear)
    }
}
#endif
