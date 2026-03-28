import AppIntents
import WidgetKit
import SwiftUI
import AzkarServices
import DatabaseInteractors
import Entities
import Extensions

@available(iOS 17, *)
private enum NextDhikrWidgetKind {
    static let value = "AzkarNextDhikrCounter"
}

@available(iOS 17, *)
private enum NextDhikrWidgetPreferenceKey {
    static let contentLanguage = "kContentLanguage"
    static let zikrCollectionSource = "kZikrCollectionSource"
}

@available(iOS 17, *)
enum NextDhikrTextMode: String, AppEnum {
    case original
    case translation

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "widget.next.config.displayedText")
    static var caseDisplayRepresentations: [NextDhikrTextMode: DisplayRepresentation] = [
        .original: "widget.next.config.original",
        .translation: "widget.next.config.translation",
    ]
}

@available(iOS 17, *)
struct NextDhikrWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "widget.next.title"
    static var description = IntentDescription("widget.next.description")

    @Parameter(title: "widget.next.config.displayedText", default: .original)
    var textMode: NextDhikrTextMode
}

@available(iOS 17, *)
struct IncrementNextDhikrIntent: AppIntent {
    static var title: LocalizedStringResource = "widget.next.increment"
    static var description = IntentDescription("widget.next.increment.description")
    static var openAppWhenRun = false
    static var isDiscoverable = false

    @Parameter(title: "widget.next.intent.zikrID")
    var zikrID: Int

    @Parameter(title: "widget.next.intent.category")
    var categoryRawValue: String

    init() {}

    init(zikrID: Int, categoryRawValue: String) {
        self.zikrID = zikrID
        self.categoryRawValue = categoryRawValue
    }

    func perform() async throws -> some IntentResult {
        let dataSource = NextDhikrWidgetDataSource()

        guard
            let category = ZikrCategory(rawValue: categoryRawValue),
            let counter = dataSource.counterService,
            let zikr = await dataSource.resolveZikr(id: zikrID, category: category)
        else {
            return .result()
        }

        try await counter.incrementCounter(for: zikr)

        if await dataSource.firstUncompletedZikr(in: category) == nil {
            try? await counter.markCategoryAsCompleted(category)
        }

        NextDhikrWidgetReloader.reloadAll()
        return .result()
    }
}

@available(iOS 17, *)
struct NextDhikrCounterWidget: Widget {
    let kind = NextDhikrWidgetKind.value

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: NextDhikrWidgetIntent.self,
            provider: NextDhikrCounterWidgetProvider()
        ) { entry in
            NextDhikrCounterWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(.systemBackground)
                }
        }
        .configurationDisplayName("widget.next.title")
        .description("widget.next.galleryDescription")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@available(iOS 17, *)
private enum NextDhikrWidgetReloader {
    static func reloadAll() {
        WidgetCenter.shared.reloadTimelines(ofKind: NextDhikrWidgetKind.value)
        WidgetCenter.shared.reloadTimelines(ofKind: "AzkarCompletionWidgets")
        WidgetCenter.shared.reloadTimelines(ofKind: "AzkarCategoryQuickAccess")
        WidgetCenter.shared.reloadTimelines(ofKind: "AzkarStreak")
    }
}

@available(iOS 17, *)
private struct NextDhikrWidgetDataSource {
    private let appGroupDefaults = UserDefaults.appGroup

    var counterService: DatabaseZikrCounter? {
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

    func resolveEntry(textMode: NextDhikrTextMode, isPlaceholder: Bool = false) async -> NextDhikrWidgetEntry {
        if isPlaceholder {
            return NextDhikrWidgetEntry(
                date: Date(),
                item: NextDhikrWidgetItem.placeholder(textMode: textMode),
                isCompletedForToday: false,
                isPlaceholder: true
            )
        }

        guard let morningItem = await resolvePendingItem(for: .morning, textMode: textMode) else {
            if let eveningItem = await resolvePendingItem(for: .evening, textMode: textMode) {
                return NextDhikrWidgetEntry(date: Date(), item: eveningItem, isCompletedForToday: false, isPlaceholder: false)
            }

            return NextDhikrWidgetEntry(date: Date(), item: nil, isCompletedForToday: true, isPlaceholder: false)
        }

        return NextDhikrWidgetEntry(date: Date(), item: morningItem, isCompletedForToday: false, isPlaceholder: false)
    }

    func firstUncompletedZikr(in category: ZikrCategory) async -> Zikr? {
        let context = categoryContext(for: category)
        let adhkar = adhkar(for: category, context: context.primaryService, collection: context.collection)
        guard let counterService else {
            return nil
        }

        for zikr in adhkar {
            let remaining = await counterService.getRemainingRepeats(for: zikr) ?? zikr.repeats
            if remaining > 0 {
                return zikr
            }
        }

        return nil
    }

    func resolveZikr(id: Int, category: ZikrCategory) async -> Zikr? {
        let context = categoryContext(for: category)
        if let categoryZikr = adhkar(for: category, context: context.primaryService, collection: context.collection)
            .first(where: { $0.id == id }) {
            return categoryZikr
        }

        if let fallbackZikr = adhkar(for: category, context: context.fallbackService, collection: context.collection)
            .first(where: { $0.id == id }) {
            return fallbackZikr
        }

        return nil
    }

    private func resolvePendingItem(
        for category: ZikrCategory,
        textMode: NextDhikrTextMode
    ) async -> NextDhikrWidgetItem? {
        let context = categoryContext(for: category)
        let categoryAdhkar = adhkar(for: category, context: context.primaryService, collection: context.collection)
        let fallbackByID = Dictionary(uniqueKeysWithValues: adhkar(for: category, context: context.fallbackService, collection: context.collection).map { ($0.id, $0) })

        guard let counterService else {
            return nil
        }

        for (index, zikr) in categoryAdhkar.enumerated() {
            let remaining = await counterService.getRemainingRepeats(for: zikr) ?? zikr.repeats
            if remaining > 0 {
                let displayZikr = displayZikr(for: zikr, fallback: fallbackByID[zikr.id], textMode: textMode)
                return NextDhikrWidgetItem(
                    zikrID: displayZikr.id,
                    category: category,
                    title: displayZikr.title,
                    textSnippet: displayText(for: displayZikr, textMode: textMode),
                    remainingCount: remaining,
                    positionInCategory: index + 1,
                    totalInCategory: categoryAdhkar.count
                )
            }
        }

        if await counterService.isCategoryCompleted(category) {
            return nil
        }

        return nil
    }

    private func categoryContext(for category: ZikrCategory) -> NextDhikrCategoryContext {
        let collection = currentCollectionSource
        switch category {
        case .morning, .evening:
            return makeContext(language: currentContentLanguage, collection: collection)
        default:
            return makeContext(language: .arabic, collection: .azkarRU)
        }
    }

    private func makeContext(language: Language, collection: ZikrCollectionSource) -> NextDhikrCategoryContext {
        let preferredLanguage = resolvedDisplayLanguage(from: language)
        let primaryService = AdhkarSQLiteDatabaseService(language: preferredLanguage)
        let fallbackLanguage = preferredLanguage.fallbackLanguage
        let fallbackService = fallbackLanguage == preferredLanguage ? nil : AdhkarSQLiteDatabaseService(language: fallbackLanguage)
        return NextDhikrCategoryContext(
            primaryService: primaryService,
            fallbackService: fallbackService,
            collection: collection
        )
    }

    private func resolvedDisplayLanguage(from language: Language) -> Language {
        let service = AdhkarSQLiteDatabaseService(language: language)
        if service.translationExists(for: language) {
            return language
        }
        return language.fallbackLanguage
    }

    private func displayZikr(for zikr: Zikr, fallback: Zikr?, textMode: NextDhikrTextMode) -> Zikr {
        switch textMode {
        case .original:
            return zikr
        case .translation:
            if let translation = zikr.translation, translation.isEmpty == false {
                return zikr
            }
            return fallback ?? zikr
        }
    }

    private func displayText(for zikr: Zikr, textMode: NextDhikrTextMode) -> String {
        switch textMode {
        case .original:
            return zikr.text
        case .translation:
            return zikr.translation ?? zikr.text
        }
    }

    private var currentContentLanguage: Language {
        decodePreference(Language.self, key: NextDhikrWidgetPreferenceKey.contentLanguage) ?? Language.getSystemLanguage()
    }

    private var currentCollectionSource: ZikrCollectionSource {
        decodePreference(ZikrCollectionSource.self, key: NextDhikrWidgetPreferenceKey.zikrCollectionSource) ?? .azkarRU
    }

    private func decodePreference<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = appGroupDefaults.object(forKey: key) as? Data else {
            return nil
        }

        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func adhkar(
        for category: ZikrCategory,
        context: AdhkarSQLiteDatabaseService?,
        collection: ZikrCollectionSource
    ) -> [Zikr] {
        guard let context else {
            return []
        }

        return (try? context.getAdhkar(category, collection: collection, language: nil)) ?? []
    }
}

@available(iOS 17, *)
private struct NextDhikrCategoryContext {
    let primaryService: AdhkarSQLiteDatabaseService
    let fallbackService: AdhkarSQLiteDatabaseService?
    let collection: ZikrCollectionSource
}

@available(iOS 17, *)
struct NextDhikrWidgetEntry: TimelineEntry {
    let date: Date
    let item: NextDhikrWidgetItem?
    let isCompletedForToday: Bool
    let isPlaceholder: Bool
}

@available(iOS 17, *)
struct NextDhikrWidgetItem {
    let zikrID: Int
    let category: ZikrCategory
    let title: String?
    let textSnippet: String
    let remainingCount: Int
    let positionInCategory: Int
    let totalInCategory: Int

    static func placeholder(textMode: NextDhikrTextMode) -> NextDhikrWidgetItem {
        NextDhikrWidgetItem(
            zikrID: 1,
            category: .morning,
            title: nil,
            textSnippet: textMode == .original ? "الحمد لله" : String(localized: "widget.next.placeholder.translation", bundle: .main),
            remainingCount: 0,
            positionInCategory: 1,
            totalInCategory: 10
        )
    }

    var progressText: String {
        "\(positionInCategory)/\(totalInCategory)"
    }

    var deepLinkURL: URL {
        URL(string: "azkar://category/\(category.rawValue)?zikr=\(zikrID)")!
    }
}

@available(iOS 17, *)
struct NextDhikrCounterWidgetProvider: AppIntentTimelineProvider {
    typealias Entry = NextDhikrWidgetEntry
    typealias Intent = NextDhikrWidgetIntent

    private let dataSource = NextDhikrWidgetDataSource()

    func placeholder(in context: Context) -> Entry {
        NextDhikrWidgetEntry(
            date: Date(),
            item: NextDhikrWidgetItem.placeholder(textMode: .original),
            isCompletedForToday: false,
            isPlaceholder: false
        )
    }

    func snapshot(for configuration: Intent, in context: Context) async -> Entry {
        await dataSource.resolveEntry(textMode: configuration.textMode)
    }

    func timeline(for configuration: Intent, in context: Context) async -> Timeline<Entry> {
        let entry = await dataSource.resolveEntry(textMode: configuration.textMode)
        let tomorrow = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        return Timeline(entries: [entry], policy: .after(tomorrow))
    }
}

@available(iOS 17, *)
private struct NextDhikrCounterWidgetView: View {
    let entry: NextDhikrWidgetEntry

    @Environment(\.widgetFamily) private var widgetFamily

    private func progressAccessibilityValue(for item: NextDhikrWidgetItem) -> String {
        String(
            format: String(localized: "widget.next.progress", bundle: .main),
            locale: Locale.current,
            item.positionInCategory,
            item.totalInCategory
        )
    }

    private func remainingAccessibilityValue(for item: NextDhikrWidgetItem) -> String {
        String(
            format: String(localized: "widget.next.remaining", bundle: .main),
            locale: Locale.current,
            item.remainingCount
        )
    }

    private func itemAccessibilityLabel(for item: NextDhikrWidgetItem) -> String {
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
            } else if let item = entry.item {
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        categoryHeader(for: item)

                        Text(item.textSnippet.replacingOccurrences(of: "\n", with: " "))
                            .font(.caption2)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)

                    HStack(alignment: .bottom, spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            counterText(item.remainingCount, size: 38)

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
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(itemAccessibilityLabel(for: item))
                .padding(.vertical, 16)
                .padding(.horizontal, 12)
                .redacted(reason: entry.isPlaceholder ? .placeholder : [])
            }
        }
    }

    private var mediumView: some View {
        Group {
            if entry.isCompletedForToday {
                completedState
            } else if let item = entry.item {
                VStack(alignment: .leading, spacing: 10) {
                    Link(destination: item.deepLinkURL) {
                        VStack(alignment: .leading, spacing: 4) {
                            categoryHeader(for: item)

                            Text(item.textSnippet.replacingOccurrences(of: "\n", with: " "))
                                .font(.body)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(itemAccessibilityLabel(for: item))
                    .accessibilityHint(Text("widget.next.open"))

                    Spacer(minLength: 0)

                    HStack(alignment: .bottom, spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            counterText(item.remainingCount, size: 40)

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
                .padding(16)
                .redacted(reason: entry.isPlaceholder ? .placeholder : [])
            }
        }
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

    private func incrementButton(for item: NextDhikrWidgetItem) -> some View {
        Button(intent: IncrementNextDhikrIntent(zikrID: item.zikrID, categoryRawValue: item.category.rawValue)) {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .bold))
                .frame(width: 44, height: 44)
                .background(.quaternary, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("widget.next.increment"))
        .accessibilityValue(remainingAccessibilityValue(for: item))
    }

    private func categoryHeader(for item: NextDhikrWidgetItem) -> some View {
        HStack(spacing: 5) {
            Image(systemName: categorySymbol(for: item.category))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(categoryColor(for: item.category).opacity(0.8))
                .accessibilityHidden(true)

            Text(categoryName(for: item.category))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private func counterText(_ count: Int, size: CGFloat) -> some View {
        Text("\(count)")
            .font(.system(size: size, weight: .bold, design: .rounded))
            .monospacedDigit()
            .contentTransition(.numericText())
            .lineLimit(1)
            .minimumScaleFactor(0.35)
            .allowsTightening(true)
            .widgetAccentable()
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
    NextDhikrCounterWidget()
} timeline: {
    NextDhikrWidgetEntry(
        date: Date(),
        item: NextDhikrWidgetItem(
            zikrID: 4,
            category: .morning,
            title: "Protection",
            textSnippet: "Subhan Allahi wa bihamdihi",
            remainingCount: 7,
            positionInCategory: 3,
            totalInCategory: 12
        ),
        isCompletedForToday: false,
        isPlaceholder: false
    )
}

@available(iOS 17, *)
#Preview("Medium - Pending", as: .systemMedium) {
    NextDhikrCounterWidget()
} timeline: {
    NextDhikrWidgetEntry(
        date: Date(),
        item: NextDhikrWidgetItem(
            zikrID: 4,
            category: .evening,
            title: "Tasbeeh",
            textSnippet: "Glory be to Allah and praise be to Him. Glory be to Allah the Magnificent.",
            remainingCount: 12,
            positionInCategory: 7,
            totalInCategory: 18
        ),
        isCompletedForToday: false,
        isPlaceholder: false
    )
}

@available(iOS 17, *)
#Preview("Completed", as: .systemSmall) {
    NextDhikrCounterWidget()
} timeline: {
    NextDhikrWidgetEntry(
        date: Date(),
        item: nil,
        isCompletedForToday: true,
        isPlaceholder: false
    )
}
