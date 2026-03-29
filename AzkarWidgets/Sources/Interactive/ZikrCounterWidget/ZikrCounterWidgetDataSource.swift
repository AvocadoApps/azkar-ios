import Foundation
import AzkarServices
import DatabaseInteractors
import Entities
import Extensions

@available(iOS 17, *)
struct ZikrCounterWidgetDataSource {
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

    func resolveEntry(textMode: ZikrCounterTextMode, isPlaceholder: Bool = false) async -> ZikrCounterWidgetEntry {
        if isPlaceholder {
            return ZikrCounterWidgetEntry(
                date: Date(),
                item: ZikrCounterWidgetItem.placeholder(textMode: textMode),
                isCompletedForToday: false,
                isPlaceholder: true
            )
        }

        guard let morningItem = await resolvePendingItem(for: .morning, textMode: textMode) else {
            if let eveningItem = await resolvePendingItem(for: .evening, textMode: textMode) {
                return ZikrCounterWidgetEntry(date: Date(), item: eveningItem, isCompletedForToday: false, isPlaceholder: false)
            }

            return ZikrCounterWidgetEntry(date: Date(), item: nil, isCompletedForToday: true, isPlaceholder: false)
        }

        return ZikrCounterWidgetEntry(date: Date(), item: morningItem, isCompletedForToday: false, isPlaceholder: false)
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
        textMode: ZikrCounterTextMode
    ) async -> ZikrCounterWidgetItem? {
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
                return ZikrCounterWidgetItem(
                    zikrID: displayZikr.id,
                    category: category,
                    title: displayZikr.title,
                    textSnippet: displayText(for: displayZikr, textMode: textMode),
                    isRightToLeftText: textMode == .original,
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

    private func categoryContext(for category: ZikrCategory) -> ZikrCounterCategoryContext {
        let collection = currentCollectionSource
        switch category {
        case .morning, .evening:
            return makeContext(language: currentContentLanguage, collection: collection)
        default:
            return makeContext(language: .arabic, collection: .azkarRU)
        }
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
