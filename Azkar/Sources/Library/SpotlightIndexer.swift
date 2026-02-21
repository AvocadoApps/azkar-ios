import Foundation
import CoreSpotlight
import UniformTypeIdentifiers
import Entities

final class SpotlightIndexer {

    static let shared = SpotlightIndexer()

    private let defaults = UserDefaults.standard
    private let domainIdentifier = "io.jawziyya.azkar-app.spotlight"
    private let versionSalt = "spotlight-v1"

    private init() {}

    func indexIfNeeded() {
        guard CSSearchableIndex.isIndexingAvailable() else {
            return
        }

        let preferences = Preferences.shared
        let selectedLanguage = preferences.contentLanguage
        let selectedLanguageDatabase = AzkarDatabase(language: selectedLanguage)
        let language: Language = selectedLanguageDatabase.translationExists(for: selectedLanguage)
            ? selectedLanguage
            : selectedLanguage.fallbackLanguage
        let zikrCollectionSource = preferences.zikrCollectionSource
        let expectedVersion = makeIndexVersion(
            language: language,
            zikrCollectionSource: zikrCollectionSource
        )

        guard defaults.string(forKey: Keys.spotlightIndexVersion) != expectedVersion else {
            return
        }

        Task(priority: .utility) {
            do {
                let items = try buildSearchableItems(
                    language: language,
                    zikrCollectionSource: zikrCollectionSource
                )
                try await resetAndIndex(items)
                defaults.set(expectedVersion, forKey: Keys.spotlightIndexVersion)
            } catch {
                print("Spotlight indexing failed: \(error.localizedDescription)")
            }
        }
    }

}

private extension SpotlightIndexer {

    var appKeywords: [String] {
        [
            "azkar",
            "adhkar",
            "dhikr",
            "zikr",
            "dua",
            "prayer",
            "supplication",
            "muslim",
            "islam",
            "quran",
            "sunnah",
            "morning adhkar",
            "evening adhkar",
            "اذكار",
            "أذكار",
            "ذكر",
            "دعاء",
            "азкары",
            "зикр",
            "дуа"
        ]
    }

    func buildSearchableItems(
        language: Language,
        zikrCollectionSource: ZikrCollectionSource
    ) throws -> [CSSearchableItem] {
        let database = AzkarDatabase(language: language)
        let adhkar = try database.getAllAdhkar()
        let categoryLookup = try makeCategoryLookup(
            database: database,
            zikrCollectionSource: zikrCollectionSource
        )

        var items = [makeAppItem()]
        items += ZikrCategory
            .allCases
            .map(makeCategoryItem)
        items += adhkar
            .map { makeZikrItem($0, categories: categoryLookup[$0.id] ?? []) }
        return items
    }

    func makeCategoryLookup(
        database: AzkarDatabase,
        zikrCollectionSource: ZikrCollectionSource
    ) throws -> [Int: [ZikrCategory]] {
        var map: [Int: [ZikrCategory]] = [:]

        for category in ZikrCategory.allCases {
            let adhkar: [Zikr]

            switch category {
            case .morning, .evening:
                adhkar = try database.getAdhkar(category, collection: zikrCollectionSource)
            case .night, .afterSalah, .other:
                adhkar = try database.getAdhkar(category, collection: .azkarRU)
            case .hundredDua:
                adhkar = try database.getAdhkar(in: category)
            }

            for zikr in adhkar {
                map[zikr.id, default: []].append(category)
            }
        }

        return map
    }

    func makeAppItem() -> CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: UTType.text.identifier)
        attributeSet.title = L10n.appName
        attributeSet.contentDescription = "Daily adhkar and duas from Quran and Sunnah"
        attributeSet.keywords = appKeywords
        attributeSet.contentURL = AppDeepLink.home.url

        return CSSearchableItem(
            uniqueIdentifier: AppDeepLink.home.searchableIdentifier,
            domainIdentifier: domainIdentifier,
            attributeSet: attributeSet
        )
    }

    func makeCategoryItem(_ category: ZikrCategory) -> CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: UTType.text.identifier)
        attributeSet.title = category.title
        attributeSet.contentDescription = L10n.appName
        attributeSet.keywords = uniqueKeywords(
            appKeywords +
            [
                category.rawValue,
                category.title
            ]
        )
        attributeSet.contentURL = AppDeepLink.category(category).url

        return CSSearchableItem(
            uniqueIdentifier: AppDeepLink.category(category).searchableIdentifier,
            domainIdentifier: domainIdentifier,
            attributeSet: attributeSet
        )
    }

    func makeZikrItem(_ zikr: Zikr, categories: [ZikrCategory]) -> CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: UTType.text.identifier)
        attributeSet.title = title(for: zikr)
        attributeSet.contentDescription = description(for: zikr)
        attributeSet.keywords = uniqueKeywords(
            appKeywords +
            categories.map(\.rawValue) +
            categories.map(\.title) +
            [
                normalizedText(zikr.source),
                normalizedText(zikr.title)
            ]
            .compactMap { $0 }
        )
        attributeSet.contentURL = AppDeepLink.zikr(zikr.id).url

        return CSSearchableItem(
            uniqueIdentifier: AppDeepLink.zikr(zikr.id).searchableIdentifier,
            domainIdentifier: domainIdentifier,
            attributeSet: attributeSet
        )
    }

    func title(for zikr: Zikr) -> String {
        if let title = normalizedText(zikr.title) {
            return title
        }

        if let translationSnippet = shortText(zikr.translation, maxLength: 90) {
            return translationSnippet
        }

        return L10n.Common.dhikr(zikr.id)
    }

    func description(for zikr: Zikr) -> String {
        var parts: [String] = []

        if let translation = shortText(zikr.translation, maxLength: 180) {
            parts.append(translation)
        }

        if let source = normalizedText(zikr.source) {
            parts.append(source)
        }

        if parts.isEmpty, let text = shortText(zikr.text, maxLength: 180) {
            parts.append(text)
        }

        return parts.joined(separator: " - ")
    }

    func normalizedText(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let text = value
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.isEmpty == false }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return text.isEmpty ? nil : text
    }

    func shortText(_ value: String?, maxLength: Int) -> String? {
        guard let normalized = normalizedText(value) else {
            return nil
        }

        guard normalized.count > maxLength else {
            return normalized
        }

        let index = normalized.index(normalized.startIndex, offsetBy: maxLength)
        return String(normalized[..<index]) + "..."
    }

    func uniqueKeywords(_ keywords: [String]) -> [String] {
        var seen = Set<String>()
        var unique: [String] = []

        for keyword in keywords {
            let normalized = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
            guard normalized.isEmpty == false else {
                continue
            }
            guard seen.insert(normalized.lowercased()).inserted else {
                continue
            }
            unique.append(normalized)
        }

        return unique
    }

    func makeIndexVersion(
        language: Language,
        zikrCollectionSource: ZikrCollectionSource
    ) -> String {
        let shortVersion = Bundle.main
            .object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        let build = Bundle.main
            .object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        return [versionSalt, shortVersion, build, language.id, zikrCollectionSource.rawValue]
            .joined(separator: "-")
    }

    func resetAndIndex(_ items: [CSSearchableItem]) async throws {
        try await deleteItemsInDomain()
        try await index(items)
    }

    func deleteItemsInDomain() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            CSSearchableIndex.default().deleteSearchableItems(
                withDomainIdentifiers: [domainIdentifier],
                completionHandler: { error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            )
        }
    }

    func index(_ items: [CSSearchableItem]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            CSSearchableIndex.default().indexSearchableItems(items) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

}
