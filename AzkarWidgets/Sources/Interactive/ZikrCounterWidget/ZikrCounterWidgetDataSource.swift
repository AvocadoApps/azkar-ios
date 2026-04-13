import Foundation
import AzkarServices
import DatabaseInteractors
import Entities
import Extensions

@available(iOS 17, *)
struct ZikrCounterWidgetDataSource {
    private let supportedCategories: [ZikrCategory] = [.morning, .evening, .night]
    private let selectionStateKey = "kZikrCounterWidgetSelectionState"
    private let appGroupDefaults = UserDefaults.appGroup

    var counterService: DatabaseZikrCounter? {
        guard let databasePath = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: WidgetAppGroup.identifier)?
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

    func resolveEntry(textMode: ZikrCounterTextMode, isPlaceholder: Bool = false) async -> ZikrCounterWidgetEntry {
        if isPlaceholder {
            return ZikrCounterWidgetEntry(
                date: Date(),
                item: ZikrCounterWidgetItem.placeholder(textMode: textMode),
                completionState: .none,
                showsCategorySuggestions: false,
                isCompletedForToday: false,
                isPlaceholder: true
            )
        }

        let completionState = await resolveCompletionState()
        if completionState == .all {
            return completedEntry(completionState: completionState)
        }

        let selectionState = currentSelectionState

        if selectionState.showsCategorySuggestions {
            return suggestionEntry(completionState: completionState)
        }

        if let activeCategory = selectionState.activeCategory {
            if let item = await resolvePendingItem(for: activeCategory, textMode: textMode) {
                return itemEntry(item, completionState: completionState)
            }

            return suggestionEntry(completionState: completionState)
        }

        if let item = await firstPendingItem(in: prioritizedCategories(for: Date()), textMode: textMode) {
            return itemEntry(item, completionState: completionState)
        }

        return completedEntry(completionState: completionState)
    }

    func activateCategory(_ category: ZikrCategory) {
        persistSelectionState(.active(category: category, dayKey: currentDayKey))
    }

    func showCategorySuggestions() {
        persistSelectionState(.suggestions(dayKey: currentDayKey))
    }

    private func firstPendingItem(in categories: [ZikrCategory], textMode: ZikrCounterTextMode) async -> ZikrCounterWidgetItem? {
        for category in categories {
            if let item = await resolvePendingItem(for: category, textMode: textMode) {
                return item
            }
        }

        return nil
    }

    func firstUncompletedZikr(in category: ZikrCategory) async -> Zikr? {
        let context = categoryContext(for: category)
        let adhkar = adhkar(for: category, context: context.primaryService, collection: context.collection)
        guard let counterService else {
            return nil
        }

        if await counterService.isCategoryCompleted(category) {
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
        textMode: ZikrCounterTextMode
    ) async -> ZikrCounterWidgetItem? {
        let context = categoryContext(for: category)
        let categoryAdhkar = adhkar(for: category, context: context.primaryService, collection: context.collection)
        let fallbackByID = Dictionary(uniqueKeysWithValues: adhkar(for: category, context: context.fallbackService, collection: context.collection).map { ($0.id, $0) })

        guard let counterService else {
            return nil
        }

        if await counterService.isCategoryCompleted(category) {
            return nil
        }

        for (index, zikr) in categoryAdhkar.enumerated() {
            let remaining = await counterService.getRemainingRepeats(for: zikr) ?? zikr.repeats
            if remaining > 0 {
                let displayZikr = displayZikr(for: zikr, fallback: fallbackByID[zikr.id], textMode: textMode)
                return ZikrCounterWidgetItem(
                    zikrID: displayZikr.id,
                    category: category,
                    title: displayZikr.title,
                    textSnippet: displayText(for: displayZikr, textMode: textMode),
                    isRightToLeftText: textMode == .original,
                    remainingCount: remaining,
                    totalRepeats: zikr.repeats,
                    positionInCategory: index + 1,
                    totalInCategory: categoryAdhkar.count
                )
            }
        }

        return nil
    }

    private func categoryContext(for category: ZikrCategory) -> ZikrCounterCategoryContext {
        switch category {
        case .morning, .evening:
            return makeContext(language: currentContentLanguage, collection: currentCollectionSource)
        case .night, .afterSalah, .other:
            return makeContext(language: currentContentLanguage, collection: .azkarRU)
        default:
            return makeContext(language: .arabic, collection: .azkarRU)
        }
    }

    private func prioritizedCategories(for date: Date) -> [ZikrCategory] {
        switch contextualCategory(for: date) {
        case .morning:
            return [.morning, .evening, .night]
        case .evening:
            return [.evening, .morning, .night]
        case .night:
            return [.night, .evening, .morning]
        default:
            return supportedCategories
        }
    }

    private func resolveCompletionState() async -> CompletionState {
        guard let counterService else {
            return .none
        }

        var completionState: CompletionState = []
        if await counterService.isCategoryCompleted(.morning) {
            completionState.insert(.morning)
        }
        if await counterService.isCategoryCompleted(.evening) {
            completionState.insert(.evening)
        }
        if await counterService.isCategoryCompleted(.night) {
            completionState.insert(.night)
        }
        return completionState
    }

    private func itemEntry(_ item: ZikrCounterWidgetItem, completionState: CompletionState) -> ZikrCounterWidgetEntry {
        ZikrCounterWidgetEntry(
            date: Date(),
            item: item,
            completionState: completionState,
            showsCategorySuggestions: false,
            isCompletedForToday: false,
            isPlaceholder: false
        )
    }

    private func suggestionEntry(completionState: CompletionState) -> ZikrCounterWidgetEntry {
        ZikrCounterWidgetEntry(
            date: Date(),
            item: nil,
            completionState: completionState,
            showsCategorySuggestions: true,
            isCompletedForToday: false,
            isPlaceholder: false
        )
    }

    private func completedEntry(completionState: CompletionState) -> ZikrCounterWidgetEntry {
        ZikrCounterWidgetEntry(
            date: Date(),
            item: nil,
            completionState: completionState,
            showsCategorySuggestions: false,
            isCompletedForToday: true,
            isPlaceholder: false
        )
    }

    private func makeContext(language: Language, collection: ZikrCollectionSource) -> ZikrCounterCategoryContext {
        let preferredLanguage = resolvedDisplayLanguage(from: language)
        let primaryService = AdhkarSQLiteDatabaseService(language: preferredLanguage)
        let fallbackLanguage = preferredLanguage.fallbackLanguage
        let fallbackService = fallbackLanguage == preferredLanguage ? nil : AdhkarSQLiteDatabaseService(language: fallbackLanguage)
        return ZikrCounterCategoryContext(
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

    private func displayZikr(for zikr: Zikr, fallback: Zikr?, textMode: ZikrCounterTextMode) -> Zikr {
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

    private func displayText(for zikr: Zikr, textMode: ZikrCounterTextMode) -> String {
        switch textMode {
        case .original:
            return zikr.text
        case .translation:
            return zikr.translation ?? zikr.text
        }
    }

    private var currentContentLanguage: Language {
        decodePreference(Language.self, key: ZikrCounterWidgetPreferenceKey.contentLanguage) ?? Language.getSystemLanguage()
    }

    private var currentCollectionSource: ZikrCollectionSource {
        decodePreference(ZikrCollectionSource.self, key: ZikrCounterWidgetPreferenceKey.zikrCollectionSource) ?? .azkarRU
    }

    private var currentDayKey: Int {
        Int(Calendar.current.startOfDay(for: Date()).timeIntervalSince1970)
    }

    private var currentSelectionState: ZikrCounterWidgetSelectionState {
        guard
            let state = decodePreference(ZikrCounterWidgetSelectionState.self, key: selectionStateKey),
            state.dayKey == currentDayKey
        else {
            return .automatic(dayKey: currentDayKey)
        }

        return state
    }

    private func persistSelectionState(_ state: ZikrCounterWidgetSelectionState?) {
        guard let state else {
            appGroupDefaults.removeObject(forKey: selectionStateKey)
            return
        }

        guard let data = try? JSONEncoder().encode(state) else {
            return
        }

        appGroupDefaults.set(data, forKey: selectionStateKey)
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
struct ZikrCounterCategoryContext {
    let primaryService: AdhkarSQLiteDatabaseService
    let fallbackService: AdhkarSQLiteDatabaseService?
    let collection: ZikrCollectionSource
}
