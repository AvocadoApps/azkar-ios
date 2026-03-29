import SwiftUI
import WidgetKit
import Entities

@available(iOS 17, *)
struct ZikrCounterWidgetView: View {
    let entry: ZikrCounterWidgetEntry

    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            smallView
        default:
            mediumView
        }
    }

    private var smallView: some View {
        Group {
            if entry.isCompletedForToday {
                completedState
            } else if entry.showsCategorySuggestions {
                smallCategorySuggestions
            } else if let item = entry.item {
                VStack(alignment: contentAlignment(for: item), spacing: 8) {
                    snippetText(for: item)
                        .font(.caption2)

                    Spacer(minLength: 0)

                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            categoryHeader(for: item)

                            Text(item.progressText)
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .contentTransition(.numericText())
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }

                        Spacer(minLength: 0)

                        incrementButton(for: item)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: containerAlignment(for: item))
                .widgetURL(item.deepLinkURL)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(itemAccessibilityLabel(for: item))
                .redacted(reason: entry.isPlaceholder ? .placeholder : [])
            }
        }
    }

    private var mediumView: some View {
        Group {
            if entry.isCompletedForToday {
                completedState
            } else if entry.showsCategorySuggestions {
                mediumCategorySuggestions
            } else if let item = entry.item {
                VStack(alignment: contentAlignment(for: item), spacing: 10) {
                    snippetText(for: item)
                        .font(.body)

                    Spacer(minLength: 0)

                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            categoryHeader(for: item)

                            Text(item.progressText)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .contentTransition(.numericText())
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }

                        Spacer(minLength: 0)

                        incrementButton(for: item)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: containerAlignment(for: item))
                .padding(.horizontal, 11)
                .widgetURL(item.deepLinkURL)
                .accessibilityLabel(itemAccessibilityLabel(for: item))
                .accessibilityHint(Text("widget.next.open"))
                .redacted(reason: entry.isPlaceholder ? .placeholder : [])
            }
        }
    }

    private var smallCategorySuggestions: some View {
        let currentCategory = contextualCategory(for: entry.date)

        return VStack(spacing: 6) {
            HStack(spacing: 6) {
                categorySuggestionCell(for: .morning, isContextual: currentCategory == .morning, compact: true)
                categorySuggestionCell(for: .evening, isContextual: currentCategory == .evening, compact: true)
            }

            categorySuggestionCell(for: .night, isContextual: currentCategory == .night, compact: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var mediumCategorySuggestions: some View {
        let currentCategory = contextualCategory(for: entry.date)

        return HStack(spacing: 8) {
            categorySuggestionCell(for: .morning, isContextual: currentCategory == .morning, compact: false)
            categorySuggestionCell(for: .evening, isContextual: currentCategory == .evening, compact: false)
            categorySuggestionCell(for: .night, isContextual: currentCategory == .night, compact: false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var completedState: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 30, weight: .semibold))
                .widgetAccentable()
                .accessibilityHidden(true)

            Text("widget.next.completed")
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .allowsTightening(true)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("widget.next.completed"))
    }

    private func incrementButton(for item: ZikrCounterWidgetItem) -> some View {
        Button(intent: IncrementZikrCounterIntent(zikrID: item.zikrID, categoryRawValue: item.category.rawValue)) {
            counterButtonContent(for: item)
                .background(Color.accentColor, in: Circle())
                .foregroundStyle(.white)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("widget.next.increment"))
        .accessibilityValue(remainingAccessibilityValue(for: item))
    }

    private func counterButtonContent(for item: ZikrCounterWidgetItem) -> some View {
        Group {
            if item.remainingCount == 1, item.totalRepeats == 1 {
                Image(systemName: "checkmark")
                    .font(.system(size: 20, weight: .semibold))
            } else {
                Text("\(item.remainingCount)")
                    .font(.system(size: 55 / 3, weight: .regular, design: .monospaced).monospacedDigit())
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.25)
            }
        }
        .padding()
        .frame(width: 55, height: 55)
    }

    @ViewBuilder
    private func categorySuggestionCell(for category: ZikrCategory, isContextual: Bool, compact: Bool) -> some View {
        let isCompleted = isCategoryCompleted(category)

        if isCompleted {
            categorySuggestionContent(for: category, isContextual: isContextual, isCompleted: true, compact: compact)
        } else {
            Button(intent: SelectZikrCounterCategoryIntent(categoryRawValue: category.rawValue)) {
                categorySuggestionContent(for: category, isContextual: isContextual, isCompleted: false, compact: compact)
            }
            .buttonStyle(.plain)
        }
    }

    private func categorySuggestionContent(
        for category: ZikrCategory,
        isContextual: Bool,
        isCompleted: Bool,
        compact: Bool
    ) -> some View {
        let palette = CategoryQuickAccessWidgetPalette.palette(for: category)
        let iconSize: CGFloat = compact ? 22 : 26
        let labelFont: Font = compact ? .caption2.weight(.semibold) : .caption.weight(.medium)

        return VStack(spacing: compact ? 4 : 6) {
            Spacer(minLength: 0)

            Image(systemName: categorySymbol(for: category))
                .font(.system(size: iconSize, weight: .medium))
                .foregroundStyle(isCompleted ? .secondary : palette.tint)

            HStack(spacing: 3) {
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: compact ? 8 : 9, weight: .bold))
                        .foregroundStyle(palette.tint)
                }

                Text(categoryName(for: category))
                    .font(labelFont)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(isCompleted ? .secondary : .primary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, compact ? 6 : 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: compact ? 14 : 16, style: .continuous)
                .fill(categorySuggestionFill(for: category, isContextual: isContextual, isCompleted: isCompleted))
        )
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(categorySuggestionAccessibilityLabel(for: category, isCompleted: isCompleted))
    }

    private func categoryHeader(for item: ZikrCounterWidgetItem) -> some View {
        HStack(spacing: 5) {
            Image(systemName: categorySymbol(for: item.category))
                .foregroundStyle(categoryColor(for: item.category).opacity(0.5))
                .accessibilityHidden(true)

            Text(categoryName(for: item.category))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .font(.system(size: 9, weight: .medium))
    }

    private func snippetText(for item: ZikrCounterWidgetItem) -> some View {
        Text(snippetString(for: item))
            .lineLimit(3)
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(item.isRightToLeftText ? .trailing : .leading)
            .frame(maxWidth: .infinity, alignment: item.isRightToLeftText ? .trailing : .leading)
    }

    private func snippetString(for item: ZikrCounterWidgetItem) -> String {
        guard item.isRightToLeftText else {
            return item.textSnippet
        }

        return "\u{200F}\(item.textSnippet)\u{200F}"
    }

    private func contentAlignment(for item: ZikrCounterWidgetItem) -> HorizontalAlignment {
        item.isRightToLeftText ? .trailing : .leading
    }

    private func containerAlignment(for item: ZikrCounterWidgetItem) -> Alignment {
        item.isRightToLeftText ? .topTrailing : .topLeading
    }

    private func progressAccessibilityValue(for item: ZikrCounterWidgetItem) -> String {
        String(
            format: String(localized: "widget.next.progress", bundle: .main),
            locale: Locale.current,
            item.positionInCategory,
            item.totalInCategory
        )
    }

    private func remainingAccessibilityValue(for item: ZikrCounterWidgetItem) -> String {
        String(
            format: String(localized: "widget.next.remaining", bundle: .main),
            locale: Locale.current,
            item.remainingCount
        )
    }

    private func itemAccessibilityLabel(for item: ZikrCounterWidgetItem) -> String {
        let snippet = item.textSnippet.replacingOccurrences(of: "\n", with: " ")
        return [
            categoryName(for: item.category),
            item.title,
            snippet,
            remainingAccessibilityValue(for: item),
            progressAccessibilityValue(for: item)
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: ", ")
    }

    private func categorySuggestionAccessibilityLabel(for category: ZikrCategory, isCompleted: Bool) -> String {
        if isCompleted {
            let completedText = String(localized: "widget.next.completed", bundle: .main)
            return "\(categoryName(for: category)), \(completedText)"
        }

        return categoryName(for: category)
    }

    private func isCategoryCompleted(_ category: ZikrCategory) -> Bool {
        switch category {
        case .morning:
            return entry.completionState.contains(.morning)
        case .evening:
            return entry.completionState.contains(.evening)
        case .night:
            return entry.completionState.contains(.night)
        default:
            return false
        }
    }

    private func categorySuggestionFill(for category: ZikrCategory, isContextual: Bool, isCompleted: Bool) -> Color {
        let palette = CategoryQuickAccessWidgetPalette.palette(for: category)

        if isContextual && !isCompleted {
            return palette.tint.opacity(palette.contextualFillOpacity)
        }

        if isCompleted {
            return Color(.systemGray5).opacity(0.5)
        }

        return Color(.secondarySystemBackground).opacity(0.5)
    }

    private func categoryName(for category: ZikrCategory) -> String {
        switch category {
        case .morning:
            return String(localized: "widget.category.morning", bundle: .main)
        case .evening:
            return String(localized: "widget.category.evening", bundle: .main)
        case .night:
            return String(localized: "widget.category.night", bundle: .main)
        case .afterSalah:
            return String(localized: "widget.category.afterSalah", bundle: .main)
        case .other:
            return String(localized: "widget.category.other", bundle: .main)
        case .hundredDua:
            return String(localized: "widget.category.hundredDua", bundle: .main)
        }
    }

    private func categorySymbol(for category: ZikrCategory) -> String {
        switch category {
        case .morning:
            return "sun.max.fill"
        case .evening:
            return "moon.fill"
        case .night:
            return "bed.double.fill"
        case .afterSalah:
            return "sparkles"
        case .other:
            return "circle.grid.2x2.fill"
        case .hundredDua:
            return "hands.sparkles.fill"
        }
    }

    private func categoryColor(for category: ZikrCategory) -> Color {
        switch category {
        case .morning:
            return .yellow
        case .evening, .night:
            return .blue
        case .afterSalah:
            return .green
        case .other:
            return .secondary
        case .hundredDua:
            return .orange
        }
    }
}

@available(iOS 17, *)
#Preview("Small - Pending", as: .systemSmall) {
    ZikrCounterWidget()
} timeline: {
    ZikrCounterWidgetEntry(
        date: Date(),
        item: ZikrCounterWidgetItem(
            zikrID: 4,
            category: .morning,
            title: "Protection",
            textSnippet: "Subhan Allahi wa bihamdihi",
            isRightToLeftText: false,
            remainingCount: 7,
            totalRepeats: 33,
            positionInCategory: 3,
            totalInCategory: 12
        ),
        completionState: .none,
        showsCategorySuggestions: false,
        isCompletedForToday: false,
        isPlaceholder: false
    )
}

@available(iOS 17, *)
#Preview("Small - Suggestions", as: .systemSmall) {
    ZikrCounterWidget()
} timeline: {
    ZikrCounterWidgetEntry(
        date: morningDate(),
        item: nil,
        completionState: .morning,
        showsCategorySuggestions: true,
        isCompletedForToday: false,
        isPlaceholder: false
    )
}

@available(iOS 17, *)
#Preview("Medium - Night", as: .systemMedium) {
    ZikrCounterWidget()
} timeline: {
    ZikrCounterWidgetEntry(
        date: Date(),
        item: ZikrCounterWidgetItem(
            zikrID: 4,
            category: .night,
            title: "Before Sleep",
            textSnippet: "In Your name, my Lord, I lie down and in Your name I rise.",
            isRightToLeftText: false,
            remainingCount: 3,
            totalRepeats: 3,
            positionInCategory: 2,
            totalInCategory: 8
        ),
        completionState: .morning,
        showsCategorySuggestions: false,
        isCompletedForToday: false,
        isPlaceholder: false
    )
}

@available(iOS 17, *)
#Preview("Medium - Suggestions", as: .systemMedium) {
    ZikrCounterWidget()
} timeline: {
    ZikrCounterWidgetEntry(
        date: eveningDate(),
        item: nil,
        completionState: .morning,
        showsCategorySuggestions: true,
        isCompletedForToday: false,
        isPlaceholder: false
    )
}

@available(iOS 17, *)
#Preview("Completed", as: .systemSmall) {
    ZikrCounterWidget()
} timeline: {
    ZikrCounterWidgetEntry(
        date: Date(),
        item: nil,
        completionState: .all,
        showsCategorySuggestions: false,
        isCompletedForToday: true,
        isPlaceholder: false
    )
}

private func morningDate() -> Date {
    Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
}

private func eveningDate() -> Date {
    Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date()
}
