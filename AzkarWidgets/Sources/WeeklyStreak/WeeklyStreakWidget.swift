import WidgetKit
import SwiftUI
import AzkarServices
import DatabaseInteractors
import Entities

// MARK: - Widget Definition

@available(iOS 16, *)
struct WeeklyStreakWidget: Widget {
    let kind = "AzkarWeeklyStreak"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: WeeklyStreakProvider()
        ) { entry in
            if #available(iOS 17, *) {
                WeeklyStreakView(entry: entry)
                    .containerBackground(for: .widget) {
                        Color(.systemBackground)
                    }
            } else {
                WeeklyStreakView(entry: entry)
                    .padding()
                    .background(Color(.systemBackground))
            }
        }
        .supportedFamilies([.systemSmall, .systemMedium])
        .configurationDisplayName("widget.streak.title")
        .description("widget.streak.description")
    }
}

// MARK: - Entry

struct DayCompletion {
    let date: Date
    let state: CompletionState

    var isFullyCompleted: Bool {
        state.contains(.morning) && state.contains(.evening) && state.contains(.night)
    }
}

struct WeeklyStreakEntry: TimelineEntry {
    let date: Date
    let streakCount: Int
    let weekData: [DayCompletion] // 7 items, oldest first
}

// MARK: - Timeline Provider

@available(iOS 16, *)
struct WeeklyStreakProvider: TimelineProvider {
    typealias Entry = WeeklyStreakEntry

    private var zikrCounter: DatabaseZikrCounter? {
        guard let databasePath = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.io.jawziyya.azkar-app")?
            .appendingPathComponent("counter.db")
            .path
        else {
            return nil
        }

        return DatabaseZikrCounter(
            databasePath: databasePath,
            getKey: {
                let startOfDay = Calendar.current.startOfDay(for: Date())
                return Int(startOfDay.timeIntervalSince1970)
            }
        )
    }

    func placeholder(in context: Context) -> Entry {
        Entry(
            date: Date(),
            streakCount: 3,
            weekData: sampleWeek(completedDays: [0, 1, 2])
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        Task {
            let entry = await buildEntry()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        Task {
            let entry = await buildEntry()
            let tomorrow = Calendar.current.startOfDay(
                for: Date().addingTimeInterval(86400)
            )
            let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
            completion(timeline)
        }
    }

    private func buildEntry() async -> Entry {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let counter = zikrCounter else {
            return Entry(
                date: Date(),
                streakCount: 0,
                weekData: (0..<7).reversed().map { offset in
                    DayCompletion(
                        date: calendar.date(byAdding: .day, value: -offset, to: today) ?? today,
                        state: .none
                    )
                }
            )
        }

        let history = await counter.getCompletionHistory(days: 7)

        // Build week data (oldest first: 6 days ago ... today)
        let weekData: [DayCompletion] = (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let key = Int(date.timeIntervalSince1970)
            let categories = history[key] ?? []

            var state: CompletionState = []
            if categories.contains("morning") { state.insert(.morning) }
            if categories.contains("evening") { state.insert(.evening) }
            if categories.contains("night") { state.insert(.night) }

            return DayCompletion(date: date, state: state)
        }

        // Calculate streak: walk backwards from today
        let streakCount = await calculateStreak(counter: counter, today: today)

        return Entry(
            date: Date(),
            streakCount: streakCount,
            weekData: weekData
        )
    }

    private func calculateStreak(counter: DatabaseZikrCounter, today: Date) async -> Int {
        // Query more days to find the full streak (up to 365 days)
        let history = await counter.getCompletionHistory(days: 365)
        let calendar = Calendar.current
        var streak = 0

        for offset in 0... {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { break }
            let key = Int(date.timeIntervalSince1970)
            let categories = history[key] ?? []

            let isComplete = categories.contains("morning")
                && categories.contains("evening")
                && categories.contains("night")

            if isComplete {
                streak += 1
            } else if offset == 0 {
                // Today not complete yet, skip and check from yesterday
                continue
            } else {
                break
            }
        }

        return streak
    }

    private func sampleWeek(completedDays: Set<Int>) -> [DayCompletion] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let state: CompletionState = completedDays.contains(offset) ? .all : .none
            return DayCompletion(date: date, state: state)
        }
    }
}

// MARK: - View

@available(iOS 16, *)
struct WeeklyStreakView: View {
    let entry: WeeklyStreakEntry

    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            smallWidget
        default:
            mediumWidget
        }
    }

    // MARK: - Small Widget

    private var smallWidget: some View {
        VStack(spacing: 6) {
            Spacer(minLength: 0)

            Image(systemName: "flame.fill")
                .font(.system(size: 22))
                .foregroundStyle(entry.streakCount > 0 ? .orange : Color(.systemGray3))

            Text("\(entry.streakCount)")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(entry.streakCount > 0 ? .primary : .secondary)

            Text("widget.streak.days")
                .font(.caption)
                .foregroundStyle(.secondary)

            weekDotsRow
                .padding(.top, 2)

            Spacer(minLength: 0)
        }
    }

    private var weekDotsRow: some View {
        HStack(spacing: 5) {
            ForEach(Array(entry.weekData.enumerated()), id: \.offset) { index, day in
                let isToday = index == entry.weekData.count - 1
                Circle()
                    .fill(day.isFullyCompleted ? Color.green : Color(.systemGray4))
                    .frame(width: 7, height: 7)
                    .overlay {
                        if isToday {
                            Circle()
                                .strokeBorder(Color.primary.opacity(0.4), lineWidth: 1)
                                .frame(width: 11, height: 11)
                        }
                    }
            }
        }
    }

    // MARK: - Medium Widget

    private var mediumWidget: some View {
        HStack(spacing: 12) {
            // Left: Streak display
            VStack(spacing: 4) {
                Spacer(minLength: 0)

                Image(systemName: "flame.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(entry.streakCount > 0 ? .orange : Color(.systemGray3))

                Text("\(entry.streakCount)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(entry.streakCount > 0 ? .primary : .secondary)

                Text("widget.streak.days")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)

            // Right: Week grid
            weekGrid
                .frame(maxWidth: .infinity)
        }
    }

    private var weekGrid: some View {
        let categories: [(symbol: String, flag: CompletionState, color: Color)] = [
            ("sun.max.fill", .morning, .orange),
            ("moon.fill", .evening, .indigo),
            ("bed.double.fill", .night, .blue),
        ]

        return VStack(spacing: 5) {
            // Day headers
            HStack(spacing: 0) {
                // Spacer for icon column
                Color.clear.frame(width: 14)

                ForEach(Array(entry.weekData.enumerated()), id: \.offset) { index, day in
                    Text(shortWeekday(for: day.date))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(
                            index == entry.weekData.count - 1 ? .primary : .secondary
                        )
                        .frame(maxWidth: .infinity)
                }
            }

            // Category rows
            ForEach(Array(categories.enumerated()), id: \.offset) { _, category in
                HStack(spacing: 0) {
                    Image(systemName: category.symbol)
                        .font(.system(size: 9))
                        .foregroundStyle(category.color.opacity(0.7))
                        .frame(width: 14)

                    ForEach(Array(entry.weekData.enumerated()), id: \.offset) { index, day in
                        let isCompleted = day.state.contains(category.flag)
                        let isToday = index == entry.weekData.count - 1

                        Circle()
                            .fill(isCompleted ? category.color : Color(.systemGray5))
                            .frame(width: 8, height: 8)
                            .overlay {
                                if isToday && !isCompleted {
                                    Circle()
                                        .strokeBorder(category.color.opacity(0.3), lineWidth: 0.5)
                                }
                            }
                            .frame(maxWidth: .infinity)
                    }
                }
            }

        }
    }

    private func shortWeekday(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EE"
        let symbol = formatter.string(from: date)
        return String(symbol.prefix(2))
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview("Small - No Streak", as: .systemSmall) {
    WeeklyStreakWidget()
} timeline: {
    WeeklyStreakEntry(
        date: Date(),
        streakCount: 0,
        weekData: previewWeek(pattern: [.none, .none, .morning, .none, .none, .none, .none])
    )
}

@available(iOS 17, *)
#Preview("Small - Active Streak", as: .systemSmall) {
    WeeklyStreakWidget()
} timeline: {
    WeeklyStreakEntry(
        date: Date(),
        streakCount: 5,
        weekData: previewWeek(pattern: [.none, .none, .all, .all, .all, .all, .all])
    )
}

@available(iOS 17, *)
#Preview("Medium - Mixed Week", as: .systemMedium) {
    WeeklyStreakWidget()
} timeline: {
    WeeklyStreakEntry(
        date: Date(),
        streakCount: 2,
        weekData: previewWeek(pattern: [
            .morning,
            [.morning, .evening],
            .all,
            .none,
            .all,
            .all,
            [.morning, .evening],
        ])
    )
}

@available(iOS 17, *)
#Preview("Medium - Perfect Week", as: .systemMedium) {
    WeeklyStreakWidget()
} timeline: {
    WeeklyStreakEntry(
        date: Date(),
        streakCount: 14,
        weekData: previewWeek(pattern: Array(repeating: .all, count: 7))
    )
}

// MARK: - Preview Helpers

private func previewWeek(pattern: [CompletionState]) -> [DayCompletion] {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    return pattern.enumerated().map { index, state in
        let offset = pattern.count - 1 - index
        let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
        return DayCompletion(date: date, state: state)
    }
}
