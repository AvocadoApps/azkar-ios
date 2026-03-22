import UIKit
import CoreSpotlight
import UniformTypeIdentifiers
import Entities
import DatabaseInteractors

final class SpotlightIndexer {

    static let shared = SpotlightIndexer()

    private let defaults = UserDefaults.standard
    let searchableIndex = CSSearchableIndex(name: "AzkarMainIndex")
    let domainIdentifier = "io.jawziyya.azkar-app.spotlight"
    let versionSalt = "spotlight-v1"

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
        attributeSet.title = String(localized: "app-name")
        attributeSet.displayName = String(localized: "app-name")
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
        attributeSet.contentDescription = String(localized: "app-name")
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
            ?? String(format: String(localized: "common.dhikr"), locale: Locale.current, String(describing: hadith.id))
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

        return String(format: String(localized: "common.dhikr"), locale: Locale.current, String(describing: zikr.id))
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

}
