import SwiftUI
import WidgetKit

@available(iOS 17, *)
#Preview("Small - Idle", as: .systemSmall) {
    StreakWidget()
} timeline: {
    StreakWidgetEntry(date: Date(), streakCount: 0, weekData: previewWeek(pattern: [.none, .none, .morning, .none, .none, .none, .none]), requiredState: [.morning, .evening])
}

@available(iOS 17, *)
#Preview("Small - Spark", as: .systemSmall) {
    StreakWidget()
} timeline: {
    StreakWidgetEntry(date: Date(), streakCount: 1, weekData: previewWeek(pattern: [.none, .none, .none, .none, .none, .none, .all]), requiredState: [.morning, .evening])
}

@available(iOS 17, *)
#Preview("Small - Steady", as: .systemSmall) {
    StreakWidget()
} timeline: {
    StreakWidgetEntry(date: Date(), streakCount: 5, weekData: previewWeek(pattern: [.none, .none, .all, .all, .all, .all, .all]), requiredState: [.morning, .evening])
}

@available(iOS 17, *)
#Preview("Small - Devoted", as: .systemSmall) {
    StreakWidget()
} timeline: {
    StreakWidgetEntry(date: Date(), streakCount: 14, weekData: previewWeek(pattern: Array(repeating: .all, count: 7)), requiredState: [.morning, .evening])
}

@available(iOS 17, *)
#Preview("Small - Radiant", as: .systemSmall) {
    StreakWidget()
} timeline: {
    StreakWidgetEntry(date: Date(), streakCount: 45, weekData: previewWeek(pattern: Array(repeating: .all, count: 7)), requiredState: [.morning, .evening])
}

@available(iOS 17, *)
#Preview("Medium - Spark", as: .systemMedium) {
    StreakWidget()
} timeline: {
    StreakWidgetEntry(date: Date(), streakCount: 2, weekData: previewWeek(pattern: [.morning, [.morning, .evening], .all, .none, .all, .all, [.morning, .evening]]), requiredState: [.morning, .evening])
}

@available(iOS 17, *)
#Preview("Medium - Devoted", as: .systemMedium) {
    StreakWidget()
} timeline: {
    StreakWidgetEntry(date: Date(), streakCount: 14, weekData: previewWeek(pattern: Array(repeating: .all, count: 7)), requiredState: .all)
}

@available(iOS 17, *)
#Preview("Medium - Radiant", as: .systemMedium) {
    StreakWidget()
} timeline: {
    StreakWidgetEntry(date: Date(), streakCount: 45, weekData: previewWeek(pattern: Array(repeating: .all, count: 7)), requiredState: [.morning, .evening])
}

@available(iOS 17, *)
#Preview("Circular - Devoted", as: .accessoryCircular) {
    StreakWidget()
} timeline: {
    StreakWidgetEntry(date: Date(), streakCount: 14, weekData: previewWeek(pattern: Array(repeating: .all, count: 7)), requiredState: [.morning, .evening])
}

@available(iOS 17, *)
#Preview("Rectangular - Radiant", as: .accessoryRectangular) {
    StreakWidget()
} timeline: {
    StreakWidgetEntry(date: Date(), streakCount: 45, weekData: previewWeek(pattern: Array(repeating: .all, count: 7)), requiredState: [.morning, .evening])
}

@available(iOS 17, *)
#Preview("Inline - Steady", as: .accessoryInline) {
    StreakWidget()
} timeline: {
    StreakWidgetEntry(date: Date(), streakCount: 5, weekData: previewWeek(pattern: [.none, .none, .all, .all, .all, .all, .all]), requiredState: [.morning, .evening])
}

private func previewWeek(pattern: [CompletionState]) -> [StreakWidgetDayCompletion] {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let requiredState: CompletionState = [.morning, .evening]
    return pattern.enumerated().map { index, state in
        let offset = pattern.count - 1 - index
        let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
        return StreakWidgetDayCompletion(date: date, state: state, requiredState: requiredState)
    }
}
