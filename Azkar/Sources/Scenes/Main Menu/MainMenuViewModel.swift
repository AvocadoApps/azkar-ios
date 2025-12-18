import SwiftUI
import AudioPlayer
import Combine
import Entities
import Fakery
import ArticleReader
import Library
import AzkarServices

typealias SearchToken = ZikrCategory

final class MainMenuViewModel: ObservableObject {

    @Published var searchQuery = ""
    @Published var searchTokens: [SearchToken] = []
    @Published var availableSearchTokens: [SearchToken] = SearchToken.allCases
    
    private let searchQueryPublisher = CurrentValueSubject<String, Never>("")

    let router: UnownedRouteTrigger<RootSection>
    let azkarDatabase: AzkarDatabase
    let preferencesDatabase: PreferencesDatabase
    
    private(set) lazy var searchViewModel = SearchResultsViewModel(
        azkarDatabase: azkarDatabase,
        preferencesDatabase: preferencesDatabase,
        searchTokens: $searchTokens.eraseToAnyPublisher(),
        searchQuery: searchQueryPublisher.removeDuplicates().eraseToAnyPublisher()
    )
    
    private(set) lazy var searchSuggestionsViewModel = SearchSuggestionsViewModel(
        searchQuery: $searchQuery.removeDuplicates().eraseToAnyPublisher(),
        azkarDatabase: azkarDatabase,
        preferencesDatabase: preferencesDatabase,
        router: router
    )

    let currentYear: String
    
    let otherAzkarModels: [AzkarMenuItem]
    
    @Published var fadl: Fadl?

    @Published var additionalMenuItems: [AzkarMenuOtherItem] = []
    @Published var enableEidBackground = false
    @Published var articles: [Article] = []
    @Published var ad: Ad?

    @Preference("kDidDisplayIconPacksMessage", defaultValue: false)
    var didDisplayIconPacksMessage
    
    @Preference("kDidDisplayZikrCollectionsOnboarding", defaultValue: false)
    var didDisplayZikrCollectionsOnboarding

    let player: Player
    private(set) var additionalAdhkar: [ZikrMenuItem]?

    let preferences: Preferences
    private let articlesService: ArticlesServiceType
    private let adsService: AdsServiceType

    private var cancellables = Set<AnyCancellable>()

    init(
        databaseService: AzkarDatabase,
        preferencesDatabase: PreferencesDatabase,
        router: UnownedRouteTrigger<RootSection>,
        preferences: Preferences,
        player: Player,
        articlesService: ArticlesServiceType,
        adsService: AdsServiceType
    ) {
        self.azkarDatabase = databaseService
        self.preferencesDatabase = preferencesDatabase
        self.router = router
        self.preferences = preferences
        self.player = player
        self.articlesService = articlesService
        self.adsService = adsService
                
        if Date().isRamadan {
            var adhkar: [ZikrMenuItem] = []
            if let fastindDua = databaseService.getZikrBeforeBreakingFast() {
                adhkar.append(ZikrMenuItem(
                    color: Color.blue,
                    iconType: IconType.emoji,
                    imageName: "🥛",
                    zikr: fastindDua
                ))
            }
            if let laylatulQadrDua = databaseService.getLaylatulQadrDua() {
                adhkar.append(ZikrMenuItem(
                    color: Color.green,
                    iconType: IconType.emoji,
                    imageName: "🌕",
                    zikr: laylatulQadrDua
                ))
            }
            additionalAdhkar = adhkar
        }
        
        otherAzkarModels = [
            AzkarMenuItem(
                category: .night,
                imageName: "categories/night",
                title: L10n.Category.night,
                color: Color.init(uiColor: .systemMint),
                count: nil,
                iconType: .bundled(resourcesBunbdle)
            ),
            AzkarMenuItem(
                category: .afterSalah,
                imageName: "categories/after-salah",
                title: L10n.Category.afterSalah,
                color: Color.init(.systemBlue),
                count: nil,
                iconType: .bundled(resourcesBunbdle)
            ),
            AzkarMenuItem(
                category: .other,
                imageName: "categories/important-adhkar",
                title: L10n.Category.other,
                color: Color.init(.systemTeal),
                count: nil,
                iconType: .bundled(resourcesBunbdle)
            ),
            AzkarMenuItem(
                category: .hundredDua,
                imageName: "categories/hundred-dua",
                title: L10n.Category.hundredDua,
                color: Color.init(.systemPink),
                count: nil,
                iconType: .bundled(resourcesBunbdle)
            ),
        ]

        do {
            if let fadl = try databaseService.getRandomFadl() {
                print(fadl)
            }
        } catch {
            print(error)
        }

        var year = "\(Date().hijriYear) г.х."
        switch Calendar.current.identifier {
        case .islamic, .islamicCivil, .islamicTabular, .islamicUmmAlQura:
            break
        default:
            year += " (\(Date().year) г.)"
        }
        currentYear = year

        preferences.$enableFunFeatures
            .map { flag in flag && Date().isRamadanEidDays }
            .assign(to: \.enableEidBackground, on: self)
            .store(in: &cancellables)
        
        preferences
            .storageChangesPublisher()
            .receive(on: RunLoop.main)
            .sink { [unowned self] in
                self.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        preferences
            .$contentLanguage
            .handleEvents(receiveOutput: { language in
                ArticleCategory.language = language
            })
            .map { language in
                try? databaseService.getRandomFadl(language: language)
            }
            .assign(to: &$fadl)
        
        $searchQuery
            .removeDuplicates()
            .subscribe(on: DispatchQueue.global(qos: .userInteractive))
            .subscribe(searchQueryPublisher)
            .store(in: &cancellables)
        
        Task {
            await loadArticles()
        }
        
        Task {
            await loadAds()
        }
        
        if !didDisplayZikrCollectionsOnboarding, !InstallationDateChecker.isRecentlyInstalled(days: 3) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                router.trigger(.zikrCollectionsOnboarding)
                self.didDisplayZikrCollectionsOnboarding = true
            }
        }
    }
    
    private func loadArticles() async {
        do {
            for try await articles in articlesService.getArticles(
                limit: 5
            ) {
                await MainActor.run {
                    withAnimation {                    
                        self.articles = articles
                    }
                }
            }
        } catch {
            print(error)
        }
    }
    
    @MainActor private func loadAds() async {
        for await ad in adsService.getAd() {
            self.ad = ad
        }
    }
    
    func navigateToArticle(_ article: Article) {
        router.trigger(.article(article))
    }
    
    func naviateToSearchResult(_ searchResult: SearchResultZikr) {
        router.trigger(.searchResult(result: searchResult, searchQuery: searchQuery))
    }

    func navigateToZikr(_ zikr: Zikr) {
        router.trigger(.zikr(zikr))
    }

    func navigateToCategory(_ category: ZikrCategory) {
        router.trigger(.category(category))
    }

    func navigateToSettings() {
        router.trigger(.settings())
    }

    func navigateToIconPacksList() {
        router.trigger(.settings(.appearance))
    }
    
    func hideAd(_ ad: Ad, permanently: Bool = false) {
        self.ad = nil
        Task {
            var hiddenAd = ad
            if permanently {
                hiddenAd.isHidden = true
                try await adsService.saveAd(hiddenAd)
            }
        }
        adsService.sendAnalytics(for: ad, action: .hide)
        AnalyticsReporter.reportEvent("azkar_ads_hide", metadata: ["id": ad.id])
    }
    
    func handleAdSelection(_ ad: Ad) {
        UIApplication.shared.open(ad.actionLink)
        adsService.sendAnalytics(for: ad, action: .open)
        AnalyticsReporter.reportEvent("azkar_ads_open", metadata: ["id": ad.id])
    }
    
    func sendAdImpressionEvent(_ ad: Ad) {
        adsService.sendAnalytics(for: ad, action: .impression)
        AnalyticsReporter.reportEvent("azkar_ads_impression", metadata: ["id": ad.id])
    }
        
}

extension MainMenuViewModel {
    
    static var placeholder: MainMenuViewModel {
        MainMenuViewModel(
            databaseService: AzkarDatabase(language: Language.getSystemLanguage()),
            preferencesDatabase: MockPreferencesDatabase(),
            router: .empty,
            preferences: Preferences.shared,
            player: .test,
            articlesService: DemoArticlesService(),
            adsService: DemoAdsService()
        )
    }
    
}
