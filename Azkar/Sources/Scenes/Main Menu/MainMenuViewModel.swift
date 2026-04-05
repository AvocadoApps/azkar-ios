import SwiftUI
import AudioPlayer
import Combine
import Entities
import Fakery
import ArticleReader
import Library
import AzkarServices

typealias SearchToken = ZikrCategory

@MainActor
final class MainMenuViewModel: ObservableObject {

    @Published var searchQuery = ""
    @Published var searchTokens: [SearchToken] = []
    @Published var availableSearchTokens: [SearchToken] = SearchToken.allCases
    
    private let searchQueryPublisher = CurrentValueSubject<String, Never>("")

    let navigator: any AppNavigationRouting
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
        navigator: navigator
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
        navigator: any AppNavigationRouting,
        preferences: Preferences,
        player: Player,
        articlesService: ArticlesServiceType,
        adsService: AdsServiceType
    ) {
        self.azkarDatabase = databaseService
        self.preferencesDatabase = preferencesDatabase
        self.navigator = navigator
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
                title: String(localized: "category.night"),
                color: Color.init(uiColor: .systemMint),
                count: nil,
                iconType: .bundled(resourcesBunbdle)
            ),
            AzkarMenuItem(
                category: .afterSalah,
                imageName: "categories/after-salah",
                title: String(localized: "category.after-salah"),
                color: Color.init(.systemBlue),
                count: nil,
                iconType: .bundled(resourcesBunbdle)
            ),
            AzkarMenuItem(
                category: .other,
                imageName: "categories/important-adhkar",
                title: String(localized: "category.other"),
                color: Color.init(.systemTeal),
                count: nil,
                iconType: .bundled(resourcesBunbdle)
            ),
            AzkarMenuItem(
                category: .hundredDua,
                imageName: "categories/hundred-dua",
                title: String(localized: "category.hundred-dua"),
                color: Color.init(.systemPink),
                count: nil,
                iconType: .bundled(resourcesBunbdle)
            ),
        ]

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
                navigator.showZikrCollectionsOnboarding()
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
        navigator.showArticle(article)
    }
    
    func naviateToSearchResult(_ searchResult: SearchResultZikr) {
        navigator.showSearchResult(searchResult, query: searchQuery)
    }

    func navigateToZikr(_ zikr: Zikr) {
        navigator.showZikr(zikr)
    }

    func navigateToCategory(_ category: ZikrCategory) {
        navigator.showCategory(category)
    }

    func navigateToSettings() {
        navigator.showSettings(initialDestination: nil, presentationStyle: .push)
    }

    func navigateToIconPacksList() {
        navigator.showSettings(initialDestination: .appearance, presentationStyle: .push)
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
        adsService.markAsSeen(ad: ad)
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
            navigator: EmptyAppNavigator(),
            preferences: Preferences.shared,
            player: .test,
            articlesService: DemoArticlesService(),
            adsService: DemoAdsService()
        )
    }
    
}
