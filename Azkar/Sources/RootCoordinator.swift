import UIKit
import SwiftUI
import Combine
import Stinsen
import MessageUI
import Library
import ArticleReader
import Entities
import PDFKit
import ZikrCollectionsOnboarding
import AzkarServices
import DatabaseInteractors

enum RootSection: Equatable, RouteKind {
    case category(ZikrCategory)
    case zikr(_ zikr: Zikr, index: Int? = nil)
    case goToZikr(_ id: Zikr.ID)
    case searchResult(result: SearchResultZikr, searchQuery: String)
    case zikrPages(_ vm: ZikrPagesViewModel)
    case goToPage(Int)
    case settings(_ intitialRoute: SettingsRoute? = nil, presentModally: Bool = false)
    case shareOptions(Zikr)
    case article(Article)
    case hadith(Hadith)
    case zikrCollectionsOnboarding
}

final class RootCoordinator: NSObject, RouteTrigger, NavigationCoordinatable {
    
    var stack: Stinsen.NavigationStack<RootCoordinator> = .init(initial: \.root)
    
    @Root var root = makeRootView
    @Route(.push) var zikrCategory = makeCategoryView
    @Route(.push) var zikrPages = makeZikrPagesView
    @Route(.push) var zikr = makeZikrView
    @Route(.push) var azkarList = makeAzkarListView
    @Route(.push) var settings = makeSettingsView
    @Route(.modal) var modalSettings = makeModalSettingsView
    @Route(.modal) var shareOptions = makeShareOptionsView
    @Route(.push) var articleView = makeArticleView
    @Route(.push) var hadithView = makeHadithView
    @Route(.modal) var zikrCollectionsOnboarding = makeZikrCollectionsOnboardingCoordinator
    
    let preferences: Preferences
    var databaseService: AzkarDatabase {
        AzkarDatabase(language: preferences.contentLanguage)
    }
    var preferencesDatabase: PreferencesDatabase?
    var analyticsDatabase: AnalyticsDatabaseService?
    let deeplinker: Deeplinker
    let player: Player
    var articlesService: ArticlesServiceType?
    var adsService: AdsServiceType?

    private let selectedZikrPageIndex = CurrentValueSubject<Int, Never>(0)

    private var cancellables = Set<AnyCancellable>()
    
    private var childCoordinators: [any Identifiable] = []
    
    private var section: RootSection? {
        didSet {
            guard let section else { return }
            DispatchQueue.main.async {
                self.handleSelection(section)
            }
        }
    }
    
    init(
        preferences: Preferences,
        deeplinker: Deeplinker,
        player: Player
    ) {
        self.preferences = preferences
        self.deeplinker = deeplinker
        self.player = player

        let appGroupFolder = FileManager.default
            .appGroupContainerURL
        
        do {
            let language = preferences.contentLanguage.fallbackLanguage
            
            let analyticsDatabasePath = appGroupFolder
                .appendingPathComponent("analytics.db")
                .absoluteString
            analyticsDatabase = try? AnalyticsSQLiteDatabaseService(databasePath: analyticsDatabasePath)
            
            articlesService = try ArticlesService(
                databasePath: appGroupFolder
                    .appendingPathComponent("articles.db")
                    .absoluteString,
                language: language,
                analyticsDatabase: analyticsDatabase
            )
            adsService = try AdsService(
                databasePath: appGroupFolder
                    .appendingPathComponent("ads.db")
                    .absoluteString,
                language: language,
                analyticsDatabase: analyticsDatabase
            )

            let preferencesDatabasePath = appGroupFolder
                .appendingPathComponent("preferences.db")
                .absoluteString
            preferencesDatabase = try PreferencesSQLiteDatabaseService(databasePath: preferencesDatabasePath)
        } catch {
            articlesService = DemoArticlesService()
            preferencesDatabase = MockPreferencesDatabase()
            print(error.localizedDescription)
        }
        
        super.init()
        
        deeplinker
            .$route
            .handleEvents(receiveOutput: { [unowned self] route in
                guard route != nil else {
                    return
                }
                popToRoot()
            })
            .receive(on: DispatchQueue.main)
            .delay(for: 0.5, scheduler: DispatchQueue.main)
            .sink(receiveValue: { [unowned self] route in
                guard let route else {
                    return
                }

                switch route {

                case .home:
                    break

                case .settings(let section):
                    self.trigger(.settings(section))
                    
                case .azkar(let category):
                    self.trigger(.category(category))

                case .zikr(let id):
                    self.trigger(.goToZikr(id))

                case .article(let id):
                    Task {
                        guard let article = try? await self.articlesService?.getArticle(id, updatedAfter: nil) else {
                            return
                        }
                        await MainActor.run {
                            self.trigger(.article(article))
                        }
                    }

                case .hadith(let id):
                    guard let hadith = try? self.databaseService.getHadith(id) else {
                        return
                    }
                    self.trigger(.hadith(hadith))

                }
            })
            .store(in: &cancellables)
    }
    
    func azkarForCategory(_ category: ZikrCategory) -> [ZikrViewModel] {
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
            
            let viewModels = try adhkar.enumerated().map { idx, zikr in
                try ZikrViewModel(
                    zikr: zikr,
                    isNested: true,
                    row: category != .other ? idx + 1 : nil,
                    hadith: zikr.hadith.flatMap { id in
                        try databaseService.getHadith(id)
                    },
                    preferences: preferences,
                    player: player
                )
            }
            return viewModels
        } catch {
            return []
        }
    }

    func trigger(_ route: RootSection) {
        section = route
    }

    func goToSettings() {
        section = .settings()
    }
    
}

private extension RootCoordinator {

    func handleSelection(_ section: RootSection) {
        
        let rootViewController = UINavigationController()
        
        switch section {
        case .category, .settings:
            selectedZikrPageIndex.send(0)
        default:
            break
        }
        
        switch section {

        case .category(let category):
            if category == .other {
                route(to: \.azkarList, category)
            } else {
                route(to: \.zikrCategory, category)
            }
            
        case .article(let article):
            route(to: \.articleView, article)
            articlesService?.sendAnalyticsEvent(.view, articleId: article.id)

        case .hadith(let hadith):
            route(to: \.hadithView, hadith)

        case .zikrPages(let vm):
            route(to: \.zikrPages, vm)
            
        case .searchResult(let searchResult, let query):
            guard let zikr = try? databaseService.getZikr(searchResult.zikrId, language: searchResult.language) else {
                return
            }
            
            Task {
                await preferencesDatabase?.storeOpenedZikr(zikr.id, language: zikr.language)
            }
            
            let hadith = try? zikr.hadith.flatMap { id in
                try databaseService.getHadith(id)
            }
            let viewModel = ZikrViewModel(
                zikr: zikr,
                isNested: false,
                highlightPattern: query,
                hadith: hadith,
                preferences: preferences,
                player: player
            )
            route(to: \.zikr, viewModel)
            
        case .goToZikr(let zikrId):
            guard let zikr = try? databaseService.getZikr(zikrId, language: preferences.contentLanguage) else {
                return
            }
            let hadith = try? zikr.hadith.flatMap { id in
                try databaseService.getHadith(id)
            }
            let viewModel = ZikrViewModel(zikr: zikr, isNested: true, hadith: hadith, preferences: preferences, player: player)
            route(to: \.zikr, viewModel)

        case .zikr(let zikr, let index):
            assert(Thread.isMainThread)
            if let index = index, rootViewController.isPadInterface {
                self.selectedZikrPageIndex.send(index)
                return
            }
            
            Task {
                await preferencesDatabase?.storeOpenedZikr(zikr.id, language: zikr.language)
            }

            let hadith = try? zikr.hadith.flatMap { id in
                try databaseService.getHadith(id)
            }
            let viewModel = ZikrViewModel(
                zikr: zikr,
                isNested: true,
                hadith: hadith,
                preferences: preferences,
                player: player
            )
            route(to: \.zikr, viewModel)

        case .goToPage(let page):
            selectedZikrPageIndex.send(page)
            
        case .settings(let initialRoute, let presentModally):
            if presentModally {
                route(to: \.modalSettings, initialRoute)
            } else {
                route(to: \.settings, initialRoute)
            }
            
        case .shareOptions(let zikr):
            route(to: \.shareOptions, zikr)
            
        case .zikrCollectionsOnboarding:
            route(to: \.zikrCollectionsOnboarding)

        }
    }

}

extension RootCoordinator {
    
    @ViewBuilder func makeRootView() -> some View {
        if let preferencesDatabase, let articlesService, let adsService {
            RootView(
                viewModel: RootViewModel(
                    mainMenuViewModel: MainMenuViewModel(
                        databaseService: databaseService,
                        preferencesDatabase: preferencesDatabase,
                        router: UnownedRouteTrigger(router: self),
                        preferences: preferences,
                        player: player,
                        articlesService: articlesService,
                        adsService: adsService
                    )
                )
            )
        } else {
            EmptyView()
        }
    }
    
    func makeZikrPagesViewModel(_ category: ZikrCategory) -> ZikrPagesViewModel {
        return ZikrPagesViewModel(
            router: UnownedRouteTrigger(router: self),
            category: category,
            title: category.title,
            azkar: azkarForCategory(category),
            preferences: preferences,
            selectedPagePublisher: selectedZikrPageIndex.removeDuplicates().eraseToAnyPublisher(),
            initialPage: selectedZikrPageIndex.value
        )
    }
    
    func makeCategoryView(_ category: ZikrCategory) -> ZikrPagesView {
        let viewModel = makeZikrPagesViewModel(category)
        return ZikrPagesView(viewModel: viewModel, showPageIndicators: category == .hundredDua)
    }
    
    func makeAzkarListView(_ category: ZikrCategory) -> some View {
        let viewModel = makeZikrPagesViewModel(category)
        return AzkarListView(viewModel: viewModel)
    }
    
    func makeZikrPagesView(_ viewModel: ZikrPagesViewModel) -> some View {
        ZikrPagesView(viewModel: viewModel)
    }
    
    func makeZikrView(_ viewModel: ZikrViewModel) -> some View {
        ZikrPagesView(
            viewModel: ZikrPagesViewModel(
                router: UnownedRouteTrigger(router: self),
                category: .other,
                title: "",
                azkar: [viewModel],
                preferences: preferences,
                selectedPagePublisher: Empty().eraseToAnyPublisher(),
                initialPage: 0
            )
        )
    }
    
    func makeSettingsView(_ initialRoute: SettingsRoute?) -> SettingsCoordinator {
        SettingsCoordinator(
            databaseService: databaseService,
            preferences: preferences,
            initialRoute: initialRoute
        )
    }
    
    func makeModalSettingsView(_ initialRoute: SettingsRoute?) -> NavigationViewCoordinator<SettingsCoordinator> {
        NavigationViewCoordinator(
            SettingsCoordinator(
                databaseService: databaseService,
                preferences: preferences,
                initialRoute: initialRoute
            )
        )
    }
    
    func makeShareOptionsView(zikr: Zikr) -> NavigationViewCoordinator<ZikrShareCoordinator> {
        NavigationViewCoordinator(
            ZikrShareCoordinator(
                zikr: zikr,
                preferences: preferences,
                player: player
            )
        )
    }
    
    func makeHadithView(_ hadith: Hadith) -> some View {
        HadithView(viewModel: HadithViewModel(hadith: hadith, highlightPattern: nil, preferences: preferences))
    }

    func makeZikrCollectionsOnboardingCoordinator() -> NavigationViewCoordinator<ZikrCollectionsOnboardingCoordinator> {
        NavigationViewCoordinator(
            ZikrCollectionsOnboardingCoordinator(
                preselectedCollection: .azkarRU,
                onZikrCollectionSelect: { [weak self] newSource in
                    self?.preferences.zikrCollectionSource = newSource
                }
            )
        )
    }
    
}

extension RootCoordinator: MFMailComposeViewControllerDelegate {
      
    func presentMailComposer(from viewController: UIViewController) {
        guard MFMailComposeViewController.canSendMail() else {
            UIApplication.shared.open(URL(string: "https://t.me/jawziyya_feedback")!)
            return
        }
        let mailComposerViewController = MFMailComposeViewController()
        mailComposerViewController.setToRecipients(["azkar.app@pm.me"])
        mailComposerViewController.mailComposeDelegate = self
        viewController.present(mailComposerViewController, animated: true)
    }
    
}
