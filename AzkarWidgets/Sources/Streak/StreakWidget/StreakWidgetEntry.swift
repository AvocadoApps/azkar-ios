import Foundation
import WidgetKit

struct StreakWidgetDayCompletion {
    let date: Date
    let state: CompletionState
    let requiredState: CompletionState

    var isFullyCompleted: Bool {
        state.intersection(requiredState) == requiredState
    }
}

struct StreakWidgetEntry: TimelineEntry {
    let date: Date
    let streakCount: Int
    let weekData: [StreakWidgetDayCompletion]
    let requiredState: CompletionState
}
