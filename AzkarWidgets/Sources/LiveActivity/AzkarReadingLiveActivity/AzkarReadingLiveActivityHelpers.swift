#if canImport(ActivityKit)
import ActivityKit
import SwiftUI
import WidgetKit
import Entities

@available(iOS 16.2, *)
extension AzkarReadingLiveActivity {
    func remainingRepeatsText(for state: AzkarReadingActivityAttributes.ContentState) -> String {
        if state.currentZikrRemainingRepeats == state.currentZikrTotalRepeats {
            return String(format: String(localized: "widget.liveActivity.remaining-repeats"), locale: Locale.current, state.currentZikrTotalRepeats)
        } else if state.currentZikrRemainingRepeats == 0 {
            return String(localized: "widget.liveActivity.remaining-repeats.completed")
        } else {
            return String(format: String(localized: "widget.liveActivity.remaining-repeats"), locale: Locale.current, state.currentZikrRemainingRepeats)
        }
    }

    func activityAccessibilitySummary(for state: AzkarReadingActivityAttributes.ContentState) -> String {
        if state.isCompleted {
            return String(localized: "widget.liveActivity.completed")
        }

        return [state.currentZikrTitle, remainingRepeatsText(for: state), state.progressText]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    func lockScreenAccessibilityLabel(for context: ActivityViewContext<AzkarReadingActivityAttributes>) -> String {
        [
            WidgetCategoryMetadata.localizedTitle(for: context.attributes.categoryRawValue),
            activityAccessibilitySummary(for: context.state)
        ]
        .filter { !$0.isEmpty }
        .joined(separator: ", ")
    }
}
#endif
