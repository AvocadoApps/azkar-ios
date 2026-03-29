import SwiftUI
import WidgetKit

@available(iOS 17, *)
struct StreakWidgetView: View {
    let entry: StreakWidgetEntry

    @Environment(\.widgetFamily) private var widgetFamily

    private var tier: StreakWidgetTier { StreakWidgetTier(streakCount: entry.streakCount) }

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

    private var streakCountAccessibilityText: String {
        String(format: String(localized: "widget.streak.count", bundle: .main), locale: Locale.current, entry.streakCount)
    }

    private var enabledCategoryNames: [String] {
        var result: [String] = []
        if entry.requiredState.contains(.morning) { result.append(WidgetCategoryMetadata.localizedTitle(for: .morning)) }
        if entry.requiredState.contains(.evening) { result.append(WidgetCategoryMetadata.localizedTitle(for: .evening)) }
        if entry.requiredState.contains(.night) { result.append(WidgetCategoryMetadata.localizedTitle(for: .night)) }
        return result
    }

    private var widgetAccessibilitySummary: String {
        [
            streakCountAccessibilityText,
            enabledCategoryNames.isEmpty ? nil : String(format: String(localized: "widget.streak.tracked", bundle: .main), locale: Locale.current, enabledCategoryNames.joined(separator: ", ")),
            entry.weekData.enumerated().map { index, day in
                let stateText = day.isFullyCompleted ? String(localized: "widget.streak.day.complete", bundle: .main) : String(localized: "widget.streak.day.incomplete", bundle: .main)
                let todaySuffix = index == entry.weekData.count - 1 ? String(localized: "widget.streak.day.today", bundle: .main) : nil
                return [shortWeekday(for: day.date), stateText, todaySuffix].compactMap { $0 }.joined(separator: ", ")
            }.joined(separator: "; ")
        ]
        .compactMap { $0 }
        .joined(separator: ". ")
    }

    private var enabledCategories: [(symbol: String, flag: CompletionState, color: Color)] {
        var result: [(symbol: String, flag: CompletionState, color: Color)] = []
        if entry.requiredState.contains(.morning) { result.append(("sun.max.fill", .morning, .yellow)) }
        if entry.requiredState.contains(.evening) { result.append(("moon.fill", .evening, .blue)) }
        if entry.requiredState.contains(.night) { result.append(("bed.double.fill", .night, .blue)) }
        return result
    }

    private var smallWidget: some View {
        VStack(spacing: 8) {
            Spacer(minLength: 0)
            HStack(spacing: 4) {
                Image(systemName: tier.iconName)
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .foregroundStyle(tier.iconGradient)
                    .shadow(color: tier.shadowColor, radius: tier.shadowRadius, y: 2)
                    .accessibilityHidden(true)

                Text("\(entry.streakCount)")
                    .foregroundStyle(tier.numberColor)
                    .font(.system(size: 30, weight: tier.numberWeight, design: .rounded))
            }

            Text("widget.streak.title")
                .font(.caption)
                .foregroundStyle(.secondary)

            weekDotsRow
                .padding(.top, 2)

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(widgetAccessibilitySummary)
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

    private var inlineWidget: some View {
        Label {
            Text("widget.streak.title") + Text(" \(entry.streakCount)")
        } icon: {
            Image(systemName: tier.iconName)
        }
        .accessibilityLabel(streakCountAccessibilityText)
    }

    private var circularWidget: some View {
        VStack(spacing: 1) {
            Image(systemName: tier.iconName)
                .font(.system(size: 12))
                .accessibilityHidden(true)
            Text("\(entry.streakCount)")
                .font(.system(size: 20, weight: tier.numberWeight, design: .rounded))
        }
        .widgetAccentable()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(streakCountAccessibilityText)
    }

    private var rectangularWidget: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: tier.iconName)
                    .font(.system(size: 11))
                Text("\(entry.streakCount)")
                    .font(.system(size: 16, weight: tier.numberWeight, design: .rounded))
                Text("widget.streak.title")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

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

            ForEach(Array(enabledCategories.enumerated()), id: \.offset) { _, category in
                HStack(spacing: 4) {
                    Image(systemName: category.symbol)
                        .font(.system(size: 7))
                        .frame(width: 10)
                        .accessibilityHidden(true)
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(widgetAccessibilitySummary)
    }

    private var mediumWidget: some View {
        HStack(spacing: 12) {
            VStack(spacing: 4) {
                Spacer(minLength: 0)
                HStack {
                    Image(systemName: tier.iconName)
                        .font(.system(size: 20))
                        .foregroundStyle(tier.iconGradient)
                        .shadow(color: tier.shadowColor, radius: tier.shadowRadius, y: 2)
                        .accessibilityHidden(true)

                    Text("\(entry.streakCount)")
                        .font(.system(size: 36, weight: tier.numberWeight, design: .rounded))
                        .foregroundStyle(tier.numberColor)
                }

                Text("widget.streak.title")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)

            Spacer(minLength: 0)
            weekGrid
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(widgetAccessibilitySummary)
    }

    private var weekGrid: some View {
        VStack(spacing: 5) {
            Spacer()
            HStack(spacing: 6) {
                Color.clear.frame(width: 14, height: 0)
                ForEach(Array(entry.weekData.enumerated()), id: \.offset) { index, day in
                    Text(shortWeekday(for: day.date))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(index == entry.weekData.count - 1 ? .primary : .secondary)
                        .frame(width: 14, height: 14)
                }
            }

            ForEach(Array(enabledCategories.enumerated()), id: \.offset) { _, category in
                HStack(spacing: 6) {
                    Image(systemName: category.symbol)
                        .font(.system(size: 9))
                        .foregroundStyle(category.color.opacity(0.7))
                        .frame(width: 14)
                        .accessibilityHidden(true)

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
        return String(formatter.string(from: date).prefix(2))
    }
}
