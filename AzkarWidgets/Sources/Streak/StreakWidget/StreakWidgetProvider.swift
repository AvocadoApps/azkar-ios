import WidgetKit
import DatabaseInteractors

@available(iOS 17, *)
struct StreakWidgetProvider: AppIntentTimelineProvider {
    typealias Entry = StreakWidgetEntry
    typealias Intent = StreakWidgetIntent

    private let zikrCounter = WidgetCounterDataSource.makeCounterService()

    func placeholder(in context: Context) -> Entry {
        let requiredState: CompletionState = [.morning, .evening]
        return Entry(
            date: Date(),
            streakCount: 5,
            weekData: sampleWeek(completedDays: [0, 1, 2, 3, 4], requiredState: requiredState),
            requiredState: requiredState
        )
    }

    func snapshot(for configuration: Intent, in context: Context) async -> Entry {
        if context.isPreview {
            return sampleEntry(today: Calendar.current.startOfDay(for: Date()), requiredState: configuration.requiredCompletionState)
        }

        return await buildEntry(configuration: configuration)
    }

    func timeline(for configuration: Intent, in context: Context) async -> Timeline<Entry> {
        let entry = await buildEntry(configuration: configuration)
        let tomorrow = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        return Timeline(entries: [entry], policy: .after(tomorrow))
    }

    private func buildEntry(configuration: Intent) async -> Entry {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let requiredCategories = configuration.requiredCategories
        let requiredState = configuration.requiredCompletionState

        guard let counter = zikrCounter else {
            return emptyEntry(today: today, requiredState: requiredState)
        }

        let history = await counter.getCompletionHistory(days: 7)
        let weekData: [StreakWidgetDayCompletion] = (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let key = Int(date.timeIntervalSince1970)
            let categories = history[key] ?? []

            var state: CompletionState = []
            if categories.contains("morning") { state.insert(.morning) }
            if categories.contains("evening") { state.insert(.evening) }
            if categories.contains("night") { state.insert(.night) }

            return StreakWidgetDayCompletion(date: date, state: state, requiredState: requiredState)
        }

        let streakCount = await calculateStreak(counter: counter, today: today, requiredCategories: requiredCategories)
        return Entry(date: Date(), streakCount: streakCount, weekData: weekData, requiredState: requiredState)
    }

    private func calculateStreak(counter: DatabaseZikrCounter, today: Date, requiredCategories: Set<String>) async -> Int {
        let history = await counter.getCompletionHistory(days: 365)
        let calendar = Calendar.current
        var streak = 0

        for offset in 0... {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { break }
            let key = Int(date.timeIntervalSince1970)
            let categories = history[key] ?? []
            let isComplete = requiredCategories.isSubset(of: categories)

            if isComplete {
                streak += 1
            } else if offset != 0 {
                break
            }
        }

        return streak
    }

    private func sampleWeek(completedDays: Set<Int>, requiredState: CompletionState) -> [StreakWidgetDayCompletion] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let state: CompletionState = completedDays.contains(offset) ? .all : .none
            return StreakWidgetDayCompletion(date: date, state: state, requiredState: requiredState)
        }
    }

    private func sampleEntry(today: Date, requiredState: CompletionState) -> Entry {
        Entry(date: Date(), streakCount: 5, weekData: sampleWeekPattern(requiredState: requiredState, today: today), requiredState: requiredState)
    }

    private func emptyEntry(today: Date, requiredState: CompletionState) -> Entry {
        let calendar = Calendar.current
        return Entry(
            date: Date(),
            streakCount: 0,
            weekData: (0..<7).reversed().map { offset in
                StreakWidgetDayCompletion(
                    date: calendar.date(byAdding: .day, value: -offset, to: today) ?? today,
                    state: .none,
                    requiredState: requiredState
                )
            },
            requiredState: requiredState
        )
    }

    private func sampleWeekPattern(requiredState: CompletionState, today: Date) -> [StreakWidgetDayCompletion] {
        let calendar = Calendar.current
        let states: [CompletionState]

        if requiredState.contains(.night) {
            states = [
                [.morning],
                [.evening],
                [.morning, .evening, .night],
                [.morning, .evening, .night],
                [.morning, .evening, .night],
                [.morning, .evening, .night],
                [.morning, .evening, .night],
            ]
        } else {
            states = [
                [.morning],
                [.evening],
                [.morning, .evening],
                [.morning, .evening],
                [.morning, .evening],
                [.morning, .evening],
                [.morning, .evening],
            ]
        }

        return states.enumerated().map { index, state in
            let offset = states.count - 1 - index
            let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            return StreakWidgetDayCompletion(date: date, state: state, requiredState: requiredState)
        }
    }
}
