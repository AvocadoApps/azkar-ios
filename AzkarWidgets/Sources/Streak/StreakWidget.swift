import AppIntents
import WidgetKit
import SwiftUI
import AzkarServices
import DatabaseInteractors
import Entities

// MARK: - Configuration

@available(iOS 17, *)
struct StreakWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "widget.streak.title"
    static var description: IntentDescription = "widget.streak.description"

    @Parameter(title: "widget.streak.config.includeBedtime", default: false)
    var includeBedtime: Bool

    init() {}

    var requiredCategories: Set<String> {
        includeBedtime ? ["morning", "evening", "night"] : ["morning", "evening"]
    }

    var requiredCompletionState: CompletionState {
        includeBedtime ? [.morning, .evening, .night] : [.morning, .evening]
    }
}

// MARK: - Widget Definition

@available(iOS 17, *)
struct StreakWidget: Widget {
    let kind = "AzkarStreak"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: StreakWidgetIntent.self,
            provider: StreakWidgetProvider()
        ) { entry in
            let tier = StreakTier(streakCount: entry.streakCount)
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
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
        ])
        .containerBackgroundRemovable()
        .configurationDisplayName("widget.streak.title")
        .description("widget.streak.description")
    }
}

// MARK: - Entry

struct DayCompletion {
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
    let weekData: [DayCompletion] // 7 items, oldest first
    let requiredState: CompletionState
}

// MARK: - Timeline Provider

@available(iOS 17, *)
struct StreakWidgetProvider: AppIntentTimelineProvider {
    typealias Entry = StreakWidgetEntry
    typealias Intent = StreakWidgetIntent

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
        let requiredState: CompletionState = [.morning, .evening]
        return Entry(
            date: Date(),
            streakCount: 3,
            weekData: sampleWeek(completedDays: [0, 1, 2], requiredState: requiredState),
            requiredState: requiredState
        )
    }

    func snapshot(for configuration: Intent, in context: Context) async -> Entry {
        if context.isPreview {
            return sampleEntry(
                today: Calendar.current.startOfDay(for: Date()),
                requiredState: configuration.requiredCompletionState
            )
        }
        return await buildEntry(configuration: configuration)
    }

    func timeline(for configuration: Intent, in context: Context) async -> Timeline<Entry> {
        let entry = await buildEntry(configuration: configuration)
        let tomorrow = Calendar.current.startOfDay(
            for: Date().addingTimeInterval(86400)
        )
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

        // Build week data (oldest first: 6 days ago ... today)
        let weekData: [DayCompletion] = (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let key = Int(date.timeIntervalSince1970)
            let categories = history[key] ?? []

            var state: CompletionState = []
            if categories.contains("morning") { state.insert(.morning) }
            if categories.contains("evening") { state.insert(.evening) }
            if categories.contains("night") { state.insert(.night) }

            return DayCompletion(date: date, state: state, requiredState: requiredState)
        }

        // Calculate streak
        let streakCount = await calculateStreak(
            counter: counter,
            today: today,
            requiredCategories: requiredCategories
        )

        return Entry(
            date: Date(),
            streakCount: streakCount,
            weekData: weekData,
            requiredState: requiredState
        )
    }

    private func calculateStreak(
        counter: DatabaseZikrCounter,
        today: Date,
        requiredCategories: Set<String>
    ) async -> Int {
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
            } else if offset == 0 {
                continue
            } else {
                break
            }
        }

        return streak
    }

    private func sampleWeek(completedDays: Set<Int>, requiredState: CompletionState) -> [DayCompletion] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let state: CompletionState = completedDays.contains(offset) ? .all : .none
            return DayCompletion(date: date, state: state, requiredState: requiredState)
        }
    }

    private func sampleEntry(today: Date, requiredState: CompletionState) -> Entry {
        Entry(
            date: Date(),
            streakCount: 4,
            weekData: sampleWeekPattern(requiredState: requiredState, today: today),
            requiredState: requiredState
        )
    }

    private func emptyEntry(today: Date, requiredState: CompletionState) -> Entry {
        let calendar = Calendar.current
        return Entry(
            date: Date(),
            streakCount: 0,
            weekData: (0..<7).reversed().map { offset in
                DayCompletion(
                    date: calendar.date(byAdding: .day, value: -offset, to: today) ?? today,
                    state: .none,
                    requiredState: requiredState
                )
            },
            requiredState: requiredState
        )
    }

    private func sampleWeekPattern(requiredState: CompletionState, today: Date) -> [DayCompletion] {
        let calendar = Calendar.current
        let states: [CompletionState]

        if requiredState.contains(.night) {
            states = [
                [.morning],
                [.evening],
                [.morning, .evening],
                [.morning, .evening, .night],
                [.morning, .night],
                [.morning, .evening, .night],
                [.morning, .evening, .night],
            ]
        } else {
            states = [
                [.morning],
                [.evening],
                [.morning],
                [.morning, .evening],
                [.morning, .evening],
                [.morning, .evening],
                [.morning, .evening],
            ]
        }

        return states.enumerated().map { index, state in
            let offset = states.count - 1 - index
            let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            return DayCompletion(date: date, state: state, requiredState: requiredState)
        }
    }
}

// MARK: - Streak Tier

struct StreakTier {
    let streakCount: Int

    private enum Palette {
        static let radiantTop = Color(red: 0.99, green: 0.71, blue: 0.28)
        static let radiantBottom = Color(red: 0.93, green: 0.42, blue: 0.19)
        static let radiantTint = Color(red: 0.96, green: 0.56, blue: 0.21)
    }

    enum Level: Int, Comparable {
        case idle = 0, spark, steady, devoted, radiant
        static func < (lhs: Level, rhs: Level) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    var level: Level {
        switch streakCount {
        case 0: return .idle
        case 1...2: return .spark
        case 3...6: return .steady
        case 7...29: return .devoted
        default: return .radiant
        }
    }

    var iconName: String {
        switch level {
        case .idle: return "bolt"
        case .spark, .steady: return "bolt.fill"
        case .devoted: return "flame.fill"
        case .radiant: return "flame.circle.fill"
        }
    }

    var iconColor: Color {
        switch level {
        case .idle: return Color(.systemGray3)
        case .spark, .steady: return .orange
        case .devoted: return .orange
        case .radiant: return Palette.radiantTop
        }
    }

    var iconGradient: AnyShapeStyle {
        switch level {
        case .idle:
            return AnyShapeStyle(Color(.systemGray3))
        case .spark, .steady:
            return AnyShapeStyle(Color.orange)
        case .devoted:
            return AnyShapeStyle(LinearGradient(
                colors: [.orange, .red],
                startPoint: .top,
                endPoint: .bottom
            ))
        case .radiant:
            return AnyShapeStyle(LinearGradient(
                colors: [Palette.radiantTop, Palette.radiantBottom],
                startPoint: .top,
                endPoint: .bottom
            ))
        }
    }

    var numberColor: Color {
        level == .idle ? .secondary : .primary
    }

    var numberWeight: Font.Weight {
        switch level {
        case .idle: return .medium
        case .spark, .steady: return .bold
        case .devoted, .radiant: return .heavy
        }
    }

    var shadowColor: Color {
        switch level {
        case .idle, .spark: return .clear
        case .steady: return .orange.opacity(0.15)
        case .devoted: return .orange.opacity(0.25)
        case .radiant: return Palette.radiantTint.opacity(0.28)
        }
    }

    var shadowRadius: CGFloat {
        switch level {
        case .idle, .spark: return 0
        case .steady: return 3
        case .devoted: return 5
        case .radiant: return 6
        }
    }

    var backgroundTint: Color? {
        switch level {
        case .idle, .spark: return nil
        case .steady: return .orange
        case .devoted: return .orange
        case .radiant: return Palette.radiantTint
        }
    }

    var backgroundOpacity: Double {
        switch level {
        case .idle, .spark: return 0
        case .steady: return 0.06
        case .devoted: return 0.08
        case .radiant: return 0.1
        }
    }
}

// MARK: - View

@available(iOS 17, *)
struct StreakWidgetView: View {
    let entry: StreakWidgetEntry

    @Environment(\.widgetFamily) private var widgetFamily

    private var tier: StreakTier { StreakTier(streakCount: entry.streakCount) }

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        case .accessoryCircular:
            circularWidget
        case .accessoryRectangular:
            rectangularWidget
        case .accessoryInline:
            inlineWidget
        default:
            mediumWidget
        }
    }

    private var enabledCategories: [(symbol: String, flag: CompletionState, color: Color)] {
        var result: [(symbol: String, flag: CompletionState, color: Color)] = []
        if entry.requiredState.contains(.morning) {
            result.append(("sun.max.fill", .morning, .yellow))
        }
        if entry.requiredState.contains(.evening) {
            result.append(("moon.fill", .evening, .blue))
        }
        if entry.requiredState.contains(.night) {
            result.append(("bed.double.fill", .night, .blue))
        }
        return result
    }

    // MARK: - Small Widget

    private var smallWidget: some View {
        VStack(spacing: 8) {
            Spacer(minLength: 0)

            HStack(spacing: 4) {
                Image(systemName: tier.iconName)
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .foregroundStyle(tier.iconGradient)
                    .shadow(color: tier.shadowColor, radius: tier.shadowRadius, y: 2)

                Text("\(entry.streakCount)")
                    .foregroundStyle(tier.numberColor)
                    .font(.system(size: 30, weight: tier.numberWeight, design: .rounded))
            }

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

    // MARK: - Accessory Inline

    private var inlineWidget: some View {
        Label {
            Text("\(entry.streakCount) ") + Text("widget.streak.days")
        } icon: {
            Image(systemName: tier.iconName)
        }
    }

    // MARK: - Accessory Circular

    private var circularWidget: some View {
        VStack(spacing: 1) {
            Image(systemName: tier.iconName)
                .font(.system(size: 12))
            Text("\(entry.streakCount)")
                .font(.system(size: 20, weight: tier.numberWeight, design: .rounded))
        }
        .widgetAccentable()
    }

    // MARK: - Accessory Rectangular

    private var rectangularWidget: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: tier.iconName)
                    .font(.system(size: 11))
                Text("\(entry.streakCount)")
                    .font(.system(size: 16, weight: tier.numberWeight, design: .rounded))
                Text("widget.streak.days")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            // Day headers
            HStack(spacing: 4) {
                Color.clear.frame(width: 10)
                ForEach(Array(entry.weekData.enumerated()), id: \.offset) { index, day in
                    let isToday = index == entry.weekData.count - 1
                    Text(shortWeekday(for: day.date))
                        .font(.system(size: 7))
                        .foregroundStyle(isToday ? .primary : .secondary)
                        .frame(width: 12)
                }
            }

            // Category rows
            ForEach(Array(enabledCategories.enumerated()), id: \.offset) { _, category in
                HStack(spacing: 4) {
                    Image(systemName: category.symbol)
                        .font(.system(size: 7))
                        .frame(width: 10)
                    ForEach(Array(entry.weekData.enumerated()), id: \.offset) { _, day in
                        Circle()
                            .fill(day.state.contains(category.flag) ? Color.primary : Color.secondary.opacity(0.3))
                            .frame(width: 5, height: 5)
                            .frame(width: 12)
                    }
                }
            }
        }
        .widgetAccentable()
    }

    // MARK: - Medium Widget

    private var mediumWidget: some View {
        HStack(spacing: 12) {
            // Left: Streak display
            VStack(spacing: 4) {
                Spacer(minLength: 0)

                HStack {
                    Image(systemName: tier.iconName)
                        .font(.system(size: 20))
                        .foregroundStyle(tier.iconGradient)
                        .shadow(color: tier.shadowColor, radius: tier.shadowRadius, y: 2)

                    Text("\(entry.streakCount)")
                        .font(.system(size: 36, weight: tier.numberWeight, design: .rounded))
                        .foregroundStyle(tier.numberColor)
                }

                Text("widget.streak.days")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)

            // Right: Week grid
            Spacer(minLength: 0)
            weekGrid
        }
    }

    private var weekGrid: some View {
        VStack(spacing: 5) {
            Spacer()
            
            // Day headers
            HStack(spacing: 6) {
                Color.clear.frame(width: 14, height: 0)

                ForEach(Array(entry.weekData.enumerated()), id: \.offset) { index, day in
                    Text(shortWeekday(for: day.date))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(
                            index == entry.weekData.count - 1 ? .primary : .secondary
                        )
                        .frame(width: 14, height: 14)
                }
            }

            // Category rows (only enabled ones)
            ForEach(Array(enabledCategories.enumerated()), id: \.offset) { _, category in
                HStack(spacing: 6) {
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
                            .frame(width: 14)
                    }
                }
            }
            
            Spacer()
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

// Tier: Idle (0)
@available(iOS 17, *)
#Preview("Small - Idle", as: .systemSmall) {
    StreakWidget()
} timeline: {
    StreakWidgetEntry(
        date: Date(),
        streakCount: 0,
        weekData: previewWeek(pattern: [.none, .none, .morning, .none, .none, .none, .none]),
        requiredState: [.morning, .evening]
    )
}

// Tier: Spark (1–2)
@available(iOS 17, *)
#Preview("Small - Spark", as: .systemSmall) {
    StreakWidget()
} timeline: {
    StreakWidgetEntry(
        date: Date(),
        streakCount: 1,
        weekData: previewWeek(pattern: [.none, .none, .none, .none, .none, .none, .all]),
        requiredState: [.morning, .evening]
    )
}

// Tier: Steady (3–6)
@available(iOS 17, *)
#Preview("Small - Steady", as: .systemSmall) {
    StreakWidget()
} timeline: {
    StreakWidgetEntry(
        date: Date(),
        streakCount: 5,
        weekData: previewWeek(pattern: [.none, .none, .all, .all, .all, .all, .all]),
        requiredState: [.morning, .evening]
    )
}

// Tier: Devoted (7–29)
@available(iOS 17, *)
#Preview("Small - Devoted", as: .systemSmall) {
    StreakWidget()
} timeline: {
    StreakWidgetEntry(
        date: Date(),
        streakCount: 14,
        weekData: previewWeek(pattern: Array(repeating: .all, count: 7)),
        requiredState: [.morning, .evening]
    )
}

// Tier: Radiant (30+)
@available(iOS 17, *)
#Preview("Small - Radiant", as: .systemSmall) {
    StreakWidget()
} timeline: {
    StreakWidgetEntry(
        date: Date(),
        streakCount: 45,
        weekData: previewWeek(pattern: Array(repeating: .all, count: 7)),
        requiredState: [.morning, .evening]
    )
}

@available(iOS 17, *)
#Preview("Medium - Spark", as: .systemMedium) {
    StreakWidget()
} timeline: {
    StreakWidgetEntry(
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
        ]),
        requiredState: [.morning, .evening]
    )
}

@available(iOS 17, *)
#Preview("Medium - Devoted", as: .systemMedium) {
    StreakWidget()
} timeline: {
    StreakWidgetEntry(
        date: Date(),
        streakCount: 14,
        weekData: previewWeek(pattern: Array(repeating: .all, count: 7)),
        requiredState: .all
    )
}

@available(iOS 17, *)
#Preview("Medium - Radiant", as: .systemMedium) {
    StreakWidget()
} timeline: {
    StreakWidgetEntry(
        date: Date(),
        streakCount: 45,
        weekData: previewWeek(pattern: Array(repeating: .all, count: 7)),
        requiredState: [.morning, .evening]
    )
}

@available(iOS 17, *)
#Preview("Circular - Devoted", as: .accessoryCircular) {
    StreakWidget()
} timeline: {
    StreakWidgetEntry(
        date: Date(),
        streakCount: 14,
        weekData: previewWeek(pattern: Array(repeating: .all, count: 7)),
        requiredState: [.morning, .evening]
    )
}

@available(iOS 17, *)
#Preview("Rectangular - Radiant", as: .accessoryRectangular) {
    StreakWidget()
} timeline: {
    StreakWidgetEntry(
        date: Date(),
        streakCount: 45,
        weekData: previewWeek(pattern: Array(repeating: .all, count: 7)),
        requiredState: [.morning, .evening]
    )
}

@available(iOS 17, *)
#Preview("Inline - Steady", as: .accessoryInline) {
    StreakWidget()
} timeline: {
    StreakWidgetEntry(
        date: Date(),
        streakCount: 5,
        weekData: previewWeek(pattern: [.none, .none, .all, .all, .all, .all, .all]),
        requiredState: [.morning, .evening]
    )
}

// MARK: - Preview Helpers

private func previewWeek(pattern: [CompletionState]) -> [DayCompletion] {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let requiredState: CompletionState = [.morning, .evening]
    return pattern.enumerated().map { index, state in
        let offset = pattern.count - 1 - index
        let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
        return DayCompletion(date: date, state: state, requiredState: requiredState)
    }
}
