import Foundation
import Combine
import AudioPlayer
import Library
import Entities
import AzkarServices
import DatabaseInteractors

final class AppDependencies {

    let preferences: Preferences
    let player: Player
    let preferencesDatabase: PreferencesDatabase
    let analytics: AppAnalyticsTracking
    let analyticsDatabase: AnalyticsDatabaseService?
    let articlesService: ArticlesServiceType
    let adsService: AdsServiceType

    var databaseService: AzkarDatabase {
        AzkarDatabase(language: preferences.contentLanguage)
    }

    init(
        preferences: Preferences,
        player: Player,
        analytics: AppAnalyticsTracking,
        analyticsDatabase: AnalyticsDatabaseService?
    ) {
        self.preferences = preferences
        self.player = player
        self.analytics = analytics

        let appGroupFolder = FileManager.default.appGroupContainerURL
        let language = preferences.contentLanguage.fallbackLanguage
        self.analyticsDatabase = analyticsDatabase

        let services: (ArticlesServiceType, AdsServiceType, PreferencesDatabase)

        do {
            services = (
                try ArticlesService(
                    databasePath: appGroupFolder
                        .appendingPathComponent("articles.db")
                        .absoluteString,
                    language: language,
                    analyticsDatabase: analyticsDatabase
                ),
                try AdsService(
                    databasePath: appGroupFolder
                        .appendingPathComponent("ads.db")
                        .absoluteString,
                    language: language,
                    analyticsDatabase: analyticsDatabase
                ),
                try PreferencesSQLiteDatabaseService(
                    databasePath: appGroupFolder
                        .appendingPathComponent("preferences.db")
                        .absoluteString
                )
            )
        } catch {
            services = (DemoArticlesService(), DemoAdsService(), MockPreferencesDatabase())
            print(error.localizedDescription)
        }

        articlesService = services.0
        adsService = services.1
        preferencesDatabase = services.2
    }

    func azkar(for category: ZikrCategory) -> [ZikrViewModel] {
        do {
            let adhkar: [Zikr]

            switch category {
            case .morning, .evening:
                adhkar = try databaseService.getAdhkar(category, collection: preferences.zikrCollectionSource)
            case .night, .afterSalah, .other:
                adhkar = try databaseService.getAdhkar(category, collection: .azkarRU)
            case .hundredDua:
                adhkar = try databaseService.getAdhkar(in: category)
            }

            return try adhkar.enumerated().map { index, zikr in
                try ZikrViewModel(
                    zikr: zikr,
                    isNested: true,
                    row: category != .other ? index + 1 : nil,
                    hadith: zikr.hadith.flatMap { id in
                        try databaseService.getHadith(id)
                    },
                    preferences: preferences,
                    player: player
                )
            }
        } catch {
            return []
        }
    }

    func standaloneZikrViewModel(request: StandaloneZikrRequest) -> ZikrViewModel? {
        guard let zikr = try? databaseService.getZikr(request.zikrId, language: request.language) else {
            return nil
        }

        let hadith = try? zikr.hadith.flatMap { id in
            try databaseService.getHadith(id)
        }

        return ZikrViewModel(
            zikr: zikr,
            isNested: request.isNested,
            highlightPattern: request.highlightPattern,
            hadith: hadith,
            preferences: preferences,
            player: player
        )
    }
}
