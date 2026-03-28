import WidgetKit
import SwiftUI
import AzkarServices
import DatabaseInteractors
import Entities

// MARK: - Widget Definition

@available(iOS 16, *)
struct CategoryQuickAccessWidget: Widget {
    let kind = "AzkarCategoryQuickAccess"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: CategoryQuickAccessProvider()
        ) { entry in
            if #available(iOS 17, *) {
                CategoryQuickAccessView(entry: entry)
                    .containerBackground(for: .widget) {
                        Color(.systemBackground)
                    }
            } else {
                CategoryQuickAccessView(entry: entry)
                    .padding()
                    .background(Color(.systemBackground))
            }
        }
        .supportedFamilies([.systemSmall, .systemMedium])
        .configurationDisplayName("widget.categories.title")
        .description("widget.categories.description")
    }
}

// MARK: - Timeline

@available(iOS 16, *)
struct CategoryQuickAccessEntry: TimelineEntry {
    let date: Date
    let completionState: CompletionState
}

@available(iOS 16, *)
struct CategoryQuickAccessProvider: TimelineProvider {
    typealias Entry = CategoryQuickAccessEntry

    private var zikrCounterService: ZikrCounterType? {
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
        Entry(date: Date(), completionState: .none)
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        Task {
            let state = await getCompletionState()
            completion(Entry(date: Date(), completionState: state))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        Task {
            let state = await getCompletionState()
            let now = Date()
            let entry = Entry(date: now, completionState: state)

            // Calculate next relevant time boundary for refresh:
            // Refresh at key prayer times to update contextual highlight.
            // As a fallback, refresh at midnight to reset completion state.
            let tomorrow = Calendar.current.startOfDay(for: now.addingTimeInterval(86400))
            let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
            completion(timeline)
        }
    }

    private func getCompletionState() async -> CompletionState {
        guard let counter = zikrCounterService else {
            return .none
        }

        let isMorningCompleted = await counter.isCategoryCompleted(.morning)
        let isEveningCompleted = await counter.isCategoryCompleted(.evening)
        let isNightCompleted = await counter.isCategoryCompleted(.night)

        var state: CompletionState = []
        if isMorningCompleted { state.insert(.morning) }
        if isEveningCompleted { state.insert(.evening) }
        if isNightCompleted { state.insert(.night) }
        return state
    }
}

// MARK: - Contextual Category

/// Determines the most relevant category based on the current time of day.
@available(iOS 16, *)
private func contextualCategory(for date: Date) -> ZikrCategory {
    let hour = Calendar.current.component(.hour, from: date)
    switch hour {
    case 4..<15:
        return .morning
    case 15..<20:
        return .evening
    default:
        return .night
    }
}

// MARK: - Category Palette

/// Ambient color derived from each category's mood.
@available(iOS 16, *)
private struct CategoryPalette {
    let tint: Color
    let gradientTop: Color
    let gradientBottom: Color
    let contextualFillOpacity: Double

    static func palette(for category: ZikrCategory) -> CategoryPalette {
        switch category {
        case .morning:
            return CategoryPalette(
                tint: .orange,
                gradientTop: .orange,
                gradientBottom: .yellow,
                contextualFillOpacity: 0.2
            )
        case .evening:
            return CategoryPalette(
                tint: .indigo,
                gradientTop: .indigo,
                gradientBottom: .purple,
                contextualFillOpacity: 0.12
            )
        case .night:
            return CategoryPalette(
                tint: .blue,
                gradientTop: Color(red: 0.15, green: 0.25, blue: 0.45),
                gradientBottom: .blue,
                contextualFillOpacity: 0.2
            )
        case .afterSalah:
            return CategoryPalette(
                tint: .brown,
                gradientTop: .brown,
                gradientBottom: .orange,
                contextualFillOpacity: 0.2
            )
        default:
            return CategoryPalette(
                tint: .gray,
                gradientTop: .gray,
                gradientBottom: Color(uiColor: .systemGray3),
                contextualFillOpacity: 0.2
            )
        }
    }
}

// MARK: - View

@available(iOS 17, *)
private struct TintAwareCategoryView: View {
    let entry: CategoryQuickAccessEntry
    let widgetFamily: WidgetFamily

    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        CategoryQuickAccessContentView(
            entry: entry,
            widgetFamily: widgetFamily,
            useSFSymbols: renderingMode != .fullColor
        )
    }
}

@available(iOS 16, *)
struct CategoryQuickAccessView: View {
    let entry: CategoryQuickAccessEntry

    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        if #available(iOS 17, *) {
            TintAwareCategoryView(entry: entry, widgetFamily: widgetFamily)
        } else {
            CategoryQuickAccessContentView(entry: entry, widgetFamily: widgetFamily, useSFSymbols: false)
        }
    }
}

@available(iOS 16, *)
private struct CategoryQuickAccessContentView: View {
    let entry: CategoryQuickAccessEntry
    let widgetFamily: WidgetFamily
    let useSFSymbols: Bool

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            smallWidget
        default:
            mediumWidget
        }
    }

    // MARK: - Small Widget

    /// Compact dual quick access for morning and evening adhkar.
    private var smallWidget: some View {
        let currentCategory = contextualCategory(for: entry.date)

        return HStack(spacing: 6) {
            compactCategoryCell(
                category: .morning,
                completionFlag: .morning,
                isContextual: currentCategory == .morning
            )
            compactCategoryCell(
                category: .evening,
                completionFlag: .evening,
                isContextual: currentCategory == .evening
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Medium Widget (2x2 Grid)

    private var mediumWidget: some View {
        let categories: [(ZikrCategory, CompletionState?)] = [
            (.morning, .morning),
            (.evening, .evening),
            (.night, .night),
            (.afterSalah, nil),
        ]

        let currentCategory = contextualCategory(for: entry.date)

        return VStack(spacing: 6) {
            HStack(spacing: 6) {
                categoryCell(
                    category: categories[0].0,
                    completionFlag: categories[0].1,
                    isContextual: currentCategory == categories[0].0
                )
                categoryCell(
                    category: categories[1].0,
                    completionFlag: categories[1].1,
                    isContextual: currentCategory == categories[1].0
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            HStack(spacing: 6) {
                categoryCell(
                    category: categories[2].0,
                    completionFlag: categories[2].1,
                    isContextual: currentCategory == categories[2].0
                )
                categoryCell(
                    category: categories[3].0,
                    completionFlag: categories[3].1,
                    isContextual: currentCategory == categories[3].0
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// A single cell in the 2x2 grid.
    private func categoryCell(
        category: ZikrCategory,
        completionFlag: CompletionState?,
        isContextual: Bool
    ) -> some View {
        let isCompleted = completionFlag.map { entry.completionState.contains($0) } ?? false
        let palette = CategoryPalette.palette(for: category)

        return Link(destination: deepLinkURL(for: category)) {
            VStack(spacing: 3) {
                Spacer(minLength: 0)

                categoryIcon(for: category, size: 30)
                    .opacity(isCompleted ? 0.45 : 1.0)
                    .shadow(
                        color: isContextual ? palette.tint.opacity(0.25) : .clear,
                        radius: 4, y: 2
                    )

                HStack(spacing: 2) {
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(palette.tint)
                    }

                    Text(widgetTitle(for: category))
                        .font(.caption2.weight(.medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .foregroundStyle(isCompleted ? .secondary : .primary)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(cellFill(palette: palette, isContextual: isContextual, isCompleted: isCompleted))
            )
            .contentShape(Rectangle())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func compactCategoryCell(
        category: ZikrCategory,
        completionFlag: CompletionState?,
        isContextual: Bool
    ) -> some View {
        let isCompleted = completionFlag.map { entry.completionState.contains($0) } ?? false
        let palette = CategoryPalette.palette(for: category)

        return Link(destination: deepLinkURL(for: category)) {
            VStack(spacing: 4) {
                Spacer(minLength: 0)

                categoryIcon(for: category, size: 34)
                    .opacity(isCompleted ? 0.45 : 1.0)
                    .shadow(
                        color: isContextual ? palette.tint.opacity(0.25) : .clear,
                        radius: 4, y: 2
                    )

                HStack(spacing: 2) {
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(palette.tint)
                    }

                    Text(widgetTitle(for: category))
                        .font(.caption2.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }
                .foregroundStyle(isCompleted ? .secondary : .primary)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(cellFill(palette: palette, isContextual: isContextual, isCompleted: isCompleted))
            )
            .contentShape(Rectangle())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Category Icon

    @ViewBuilder
    private func categoryIcon(for category: ZikrCategory, size: CGFloat) -> some View {
        if useSFSymbols, let sfSymbol = categorySFSymbol(for: category) {
            Image(systemName: sfSymbol)
                .font(.system(size: size * 0.6, weight: .medium))
                .frame(width: size, height: size)
        } else {
            Image(categoryImageName(for: category))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        }
    }

    // MARK: - Cell Fill

    private func cellFill(palette: CategoryPalette, isContextual: Bool, isCompleted: Bool) -> Color {
        if isContextual && !isCompleted {
            return palette.tint.opacity(palette.contextualFillOpacity)
        }
        if isCompleted {
            return Color(.systemGray5).opacity(0.5)
        }
        return Color(.secondarySystemBackground).opacity(0.5)
    }

    // MARK: - Helpers

    private func deepLinkURL(for category: ZikrCategory) -> URL {
        URL(string: "azkar://category/\(category.rawValue)")!
    }

    private func widgetTitle(for category: ZikrCategory) -> LocalizedStringKey {
        switch category {
        case .morning: return "widget.category.morning"
        case .evening: return "widget.category.evening"
        case .night: return "widget.category.night"
        case .afterSalah: return "widget.category.afterSalah"
        case .other: return "widget.category.other"
        case .hundredDua: return "widget.category.other"
        }
    }

    private func categoryImageName(for category: ZikrCategory) -> String {
        switch category {
        case .morning: return "categories/morning"
        case .evening: return "categories/full-moon"
        case .night: return "categories/night"
        case .afterSalah: return "categories/after-salah"
        case .other: return "categories/important-adhkar"
        case .hundredDua: return "categories/hundred-dua"
        }
    }

    private func categorySFSymbol(for category: ZikrCategory) -> String? {
        switch category {
        case .morning: return "sun.max.fill"
        case .evening: return "moon.fill"
        case .night: return "bed.double.fill"
        case .afterSalah: return nil
        case .other: return "book.fill"
        case .hundredDua: return "text.book.closed.fill"
        }
    }

    private func completionFlag(for category: ZikrCategory) -> CompletionState? {
        switch category {
        case .morning: return .morning
        case .evening: return .evening
        case .night: return .night
        default: return nil
        }
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview("Small - Morning", as: .systemSmall) {
    CategoryQuickAccessWidget()
} timeline: {
    CategoryQuickAccessEntry(date: morningDate(), completionState: .none)
    CategoryQuickAccessEntry(date: morningDate(), completionState: .morning)
}

@available(iOS 17, *)
#Preview("Small - Evening", as: .systemSmall) {
    CategoryQuickAccessWidget()
} timeline: {
    CategoryQuickAccessEntry(date: eveningDate(), completionState: .none)
    CategoryQuickAccessEntry(date: eveningDate(), completionState: .evening)
}

@available(iOS 17, *)
#Preview("Medium - None", as: .systemMedium) {
    CategoryQuickAccessWidget()
} timeline: {
    CategoryQuickAccessEntry(date: morningDate(), completionState: .none)
}

@available(iOS 17, *)
#Preview("Medium - Morning Done", as: .systemMedium) {
    CategoryQuickAccessWidget()
} timeline: {
    CategoryQuickAccessEntry(date: morningDate(), completionState: .morning)
}

@available(iOS 17, *)
#Preview("Medium - All Done", as: .systemMedium) {
    CategoryQuickAccessWidget()
} timeline: {
    CategoryQuickAccessEntry(date: morningDate(), completionState: .all)
}

// MARK: - Preview Helpers

private func morningDate() -> Date {
    Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
}

private func eveningDate() -> Date {
    Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date()
}
