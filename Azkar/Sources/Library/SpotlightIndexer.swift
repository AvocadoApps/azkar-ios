import UIKit
import CoreSpotlight
import UniformTypeIdentifiers
import Entities
import DatabaseInteractors

final class SpotlightIndexer {

    static let shared = SpotlightIndexer()

    private let defaults = UserDefaults.standard
    private let index = CSSearchableIndex(name: "AzkarMainIndex")
    private let domainIdentifier = "io.jawziyya.azkar-app.spotlight"
    private let versionSalt = "spotlight-v1"

    private init() {}

    func indexIfNeeded() {
#if targetEnvironment(simulator)
        log("Running on Simulator; Spotlight indexing can be delayed or unavailable")
#endif

        guard CSSearchableIndex.isIndexingAvailable() else {
            log("Indexing not available on this runtime")
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
        let forceReindex = CommandLine.arguments.contains("FORCE_SPOTLIGHT_REINDEX")

        guard forceReindex || defaults.string(forKey: Keys.spotlightIndexVersion) != expectedVersion else {
            log("Index is up to date: \(expectedVersion)")
            return
        }

        if forceReindex {
            log("Force reindex enabled")
        }
        log("Starting reindex: \(expectedVersion)")

        Task(priority: .utility) {
            do {
                let items = try await buildSearchableItems(
                    language: language,
                    zikrCollectionSource: zikrCollectionSource
                )
                log("Prepared \(items.count) searchable items")
                try await resetAndIndex(items)
                defaults.set(expectedVersion, forKey: Keys.spotlightIndexVersion)
                log("Spotlight index updated")
            } catch {
                log("Spotlight indexing failed: \(error.localizedDescription)")
            }
        }
    }

}

private extension SpotlightIndexer {

    var appKeywords: [String] {
        [
            // English
            "azkar",
            "adhkar",
            "dhikr",
            "zikr",
            "dua",
            "duas",
            "prayer",
            "prayers",
            "supplication",
            "muslim",
            "islam",
            "islamic",
            "quran",
            "sunnah",
            "hadith",
            "morning adhkar",
            "evening adhkar",
            "morning dua",
            "evening dua",
            "night dua",
            "sleep dua",
            "after prayer",
            "after salah",
            "remembrance",
            "daily prayers",
            "daily adhkar",
            "tasbih",
            "istighfar",
            "forgiveness",
            "ruqyah",
            "protection",
            "fortress of muslim",
            "hisn al muslim",
            "hisn",
            "thikr",
            "dikr",
            "invocation",
            "praise",
            "praise Allah",
            "subhanallah",
            "alhamdulillah",
            "allahu akbar",
            "la ilaha illallah",
            "astaghfirullah",
            "bismillah",
            "salawat",

            // Arabic
            "اذكار",
            "أذكار",
            "ذكر",
            "دعاء",
            "أدعية",
            "اذكار الصباح",
            "اذكار المساء",
            "أذكار الصباح",
            "أذكار المساء",
            "أذكار النوم",
            "أذكار بعد الصلاة",
            "حصن المسلم",
            "تسبيح",
            "استغفار",
            "صلاة",
            "سبحان الله",
            "الحمد لله",
            "الله أكبر",
            "لا إله إلا الله",
            "أستغفر الله",
            "بسم الله",
            "رقية",
            "قرآن",
            "سنة",
            "حديث",

            // Russian
            "азкары",
            "зикр",
            "дуа",
            "молитва",
            "молитвы",
            "мусульманин",
            "ислам",
            "исламские",
            "коран",
            "сунна",
            "хадис",
            "утренние азкары",
            "вечерние азкары",
            "азкары утренние",
            "азкары вечерние",
            "ночные дуа",
            "после намаза",
            "после молитвы",
            "поминание Аллаха",
            "тасбих",
            "истигфар",
            "крепость мусульманина",
            "хисн аль муслим",
            "субханаллах",
            "альхамдулиллях",
            "аллаху акбар",
            "астагфируллах",
            "бисмиллях",
            "салават",
            "рукъя",
            "защита",
            "мольба",
        ]
    }

    var appSearchText: String {
        appKeywords.joined(separator: " ")
    }

    func buildSearchableItems(
        language: Language,
        zikrCollectionSource: ZikrCollectionSource
    ) async throws -> [CSSearchableItem] {
        let database = AzkarDatabase(language: language)
        let adhkar = try database.getAllAdhkar()
        let categoryLookup = try makeCategoryLookup(
            database: database,
            zikrCollectionSource: zikrCollectionSource
        )
        let identifierScope = makeIdentifierScope(
            language: language,
            zikrCollectionSource: zikrCollectionSource
        )

        var items = [makeAppItem(scope: identifierScope)]
        items += ZikrCategory
            .allCases
            .map { makeCategoryItem($0, scope: identifierScope) }
        items += adhkar
            .map {
                makeZikrItem(
                    $0,
                    categories: categoryLookup[$0.id] ?? [],
                    scope: identifierScope
                )
            }

        let articles = try await loadArticles(language: language)
        items += articles.map { makeArticleItem($0, scope: identifierScope) }

        let ahadith = try database.getAhadith()
        items += ahadith.map { makeHadithItem($0, scope: identifierScope) }

        logIdentifierUniqueness(of: items)
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

    func makeAppItem(scope: String) -> CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
        attributeSet.title = L10n.appName
        attributeSet.displayName = L10n.appName
        attributeSet.alternateNames = appKeywords
        attributeSet.contentDescription = appKeywords.joined(separator: " · ")
        attributeSet.keywords = appKeywords
        attributeSet.textContent = appSearchText
        attributeSet.contentURL = AppDeepLink.home.url

        let item = CSSearchableItem(
            uniqueIdentifier: makeUniqueIdentifier(for: .home, scope: scope),
            domainIdentifier: domainIdentifier,
            attributeSet: attributeSet
        )
        item.expirationDate = .distantFuture
        return item
    }

    func makeCategoryItem(_ category: ZikrCategory, scope: String) -> CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
        attributeSet.title = category.title
        attributeSet.contentDescription = L10n.appName
        attributeSet.keywords = uniqueKeywords(
            [
                category.rawValue,
                category.title,
                "azkar",
                "adhkar",
                "dhikr",
                "dua"
            ]
        )
        attributeSet.textContent = "\(category.title) \(category.rawValue)"
        attributeSet.contentURL = AppDeepLink.category(category).url

        let item = CSSearchableItem(
            uniqueIdentifier: makeUniqueIdentifier(for: .category(category), scope: scope),
            domainIdentifier: domainIdentifier,
            attributeSet: attributeSet
        )
        item.expirationDate = .distantFuture
        return item
    }

    func makeZikrItem(
        _ zikr: Zikr,
        categories: [ZikrCategory],
        scope: String
    ) -> CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
        attributeSet.title = title(for: zikr)
        attributeSet.contentDescription = description(for: zikr)
        attributeSet.keywords = uniqueKeywords(
            categories.map(\.rawValue) +
            categories.map(\.title) +
            [
                normalizedText(zikr.source),
                normalizedText(zikr.title)
            ]
            .compactMap { $0 }
        )
        attributeSet.textContent = [
            normalizedText(zikr.title),
            normalizedText(zikr.translation),
            normalizedText(zikr.text),
            normalizedText(zikr.source)
        ]
        .compactMap { $0 }
        .joined(separator: " ")
        attributeSet.contentURL = AppDeepLink.zikr(zikr.id).url

        let item = CSSearchableItem(
            uniqueIdentifier: makeUniqueIdentifier(for: .zikr(zikr.id), scope: scope),
            domainIdentifier: domainIdentifier,
            attributeSet: attributeSet
        )
        item.expirationDate = .distantFuture
        return item
    }

    func loadArticles(language: Language) async throws -> [Article] {
        let databasePath = FileManager.default
            .appGroupContainerURL
            .appendingPathComponent("articles.db")
            .absoluteString
        let repository = try ArticlesSQLiteDatabaseService(
            language: language,
            databaseFilePath: databasePath
        )
        return try await repository.getArticles(limit: 500, newerThan: nil)
    }

    func makeArticleItem(_ article: Article, scope: String) -> CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
        attributeSet.title = article.title
        let plainText = article.textFormat == .markdown
            ? stripMarkdown(article.text)
            : article.text
        attributeSet.contentDescription = shortText(plainText, maxLength: 200)
        attributeSet.keywords = article.tags
        attributeSet.textContent = [
            article.title,
            normalizedText(plainText)
        ]
        .compactMap { $0 }
        .joined(separator: " ")
        attributeSet.contentURL = AppDeepLink.article(article.id).url

        switch article.coverImage?.imageType {
        case .link(let url):
            attributeSet.thumbnailURL = url
        case .resource(let name):
            attributeSet.thumbnailData = UIImage(named: name)?.jpegData(compressionQuality: 0.7)
        case .none:
            break
        }

        let item = CSSearchableItem(
            uniqueIdentifier: makeUniqueIdentifier(for: .article(article.id), scope: scope),
            domainIdentifier: domainIdentifier,
            attributeSet: attributeSet
        )
        item.expirationDate = .distantFuture
        return item
    }

    func makeHadithItem(_ hadith: Hadith, scope: String) -> CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
        attributeSet.title = shortText(hadith.translation, maxLength: 90)
            ?? shortText(hadith.text, maxLength: 90)
            ?? L10n.Common.dhikr(hadith.id)
        attributeSet.contentDescription = normalizedText(hadith.source)
        attributeSet.keywords = uniqueKeywords([
            "hadith",
            "ahadith",
            "حديث",
            "хадис",
            normalizedText(hadith.source)
        ].compactMap { $0 })
        attributeSet.textContent = [
            normalizedText(hadith.translation),
            normalizedText(hadith.text),
            normalizedText(hadith.source)
        ]
        .compactMap { $0 }
        .joined(separator: " ")
        attributeSet.contentURL = AppDeepLink.hadith(hadith.id).url

        let item = CSSearchableItem(
            uniqueIdentifier: makeUniqueIdentifier(for: .hadith(hadith.id), scope: scope),
            domainIdentifier: domainIdentifier,
            attributeSet: attributeSet
        )
        item.expirationDate = .distantFuture
        return item
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

    func stripMarkdown(_ text: String) -> String {
        var result = text
        // Remove images: ![alt](url)
        result = result.replacingOccurrences(
            of: #"!\[.*?\]\(.*?\)"#,
            with: "",
            options: .regularExpression
        )
        // Convert links [text](url) to just text
        result = result.replacingOccurrences(
            of: #"\[([^\]]*)\]\([^\)]*\)"#,
            with: "$1",
            options: .regularExpression
        )
        // Remove headings markers
        result = result.replacingOccurrences(
            of: #"(?m)^#{1,6}\s+"#,
            with: "",
            options: .regularExpression
        )
        // Remove bold/italic markers
        result = result.replacingOccurrences(
            of: #"(\*{1,3}|_{1,3})(.+?)\1"#,
            with: "$2",
            options: .regularExpression
        )
        // Remove inline code
        result = result.replacingOccurrences(
            of: #"`([^`]+)`"#,
            with: "$1",
            options: .regularExpression
        )
        // Remove blockquote markers
        result = result.replacingOccurrences(
            of: #"(?m)^>\s+"#,
            with: "",
            options: .regularExpression
        )
        // Remove horizontal rules
        result = result.replacingOccurrences(
            of: #"(?m)^[-*_]{3,}\s*$"#,
            with: "",
            options: .regularExpression
        )
        // Remove list markers
        result = result.replacingOccurrences(
            of: #"(?m)^[\s]*[-*+]\s+"#,
            with: "",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: #"(?m)^[\s]*\d+\.\s+"#,
            with: "",
            options: .regularExpression
        )
        return result
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

    func makeIdentifierScope(
        language: Language,
        zikrCollectionSource: ZikrCollectionSource
    ) -> String {
        "\(language.id).\(zikrCollectionSource.rawValue).\(versionSalt)"
    }

    func makeUniqueIdentifier(for deepLink: AppDeepLink, scope: String) -> String {
        deepLink.scopedSearchableIdentifier(scope: scope)
    }

    var deviceLanguage: String {
        Bundle.main.preferredLocalizations.first
            ?? Locale.current.languageCode
            ?? "en"
    }

    func makeIndexVersion(
        language: Language,
        zikrCollectionSource: ZikrCollectionSource
    ) -> String {
        let shortVersion = Bundle.main
            .object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        let build = Bundle.main
            .object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        return [versionSalt, shortVersion, build, language.id, deviceLanguage, zikrCollectionSource.rawValue]
            .joined(separator: "-")
    }

    func resetAndIndex(_ items: [CSSearchableItem]) async throws {
        try await deleteItemsInDomain()
        try await index(items)
    }

    func deleteItemsInDomain() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            index.deleteSearchableItems(
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
            index.indexSearchableItems(items) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func log(_ message: String) {
#if DEBUG
        print("[Spotlight] \(message)")
#endif
    }

    func logIdentifierUniqueness(of items: [CSSearchableItem]) {
#if DEBUG
        let identifiers = items.compactMap(\.uniqueIdentifier)
        let duplicates = Dictionary(grouping: identifiers, by: { $0 })
            .filter { $1.count > 1 }
            .map(\.key)

        if duplicates.isEmpty {
            log("Identifiers are unique: \(identifiers.count) items")
        } else {
            log("Found duplicate identifiers: \(duplicates.prefix(5))")
        }
#endif
    }

}
