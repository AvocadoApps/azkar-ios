import SwiftUI
import Combine
import Library
import Entities
import ArticleReader
import ZikrCollectionsOnboarding

struct AppFlowView: View {

    @ObservedObject private var preferences: Preferences
    private let dependencies: AppDependencies
    private let articleShareActionHandler: ArticleShareActionHandler
    private let zikrShareActionHandler: ZikrShareActionHandler

    @StateObject private var navigator: AppNavigator
    @StateObject private var rootViewModel: RootViewModel

    init(
        preferences: Preferences,
        deeplinker: Deeplinker,
        player: Player
    ) {
        _preferences = ObservedObject(wrappedValue: preferences)
        let dependencies = AppDependencies(preferences: preferences, player: player)
        let navigator = AppNavigator(
            dependencies: dependencies,
            deeplinker: deeplinker
        )
        let rootViewModel = RootViewModel(
            mainMenuViewModel: MainMenuViewModel(
                databaseService: dependencies.databaseService,
                preferencesDatabase: dependencies.preferencesDatabase,
                navigator: navigator,
                preferences: dependencies.preferences,
                player: dependencies.player,
                articlesService: dependencies.articlesService,
                adsService: dependencies.adsService
            )
        )
        self.dependencies = dependencies
        articleShareActionHandler = ArticleShareActionHandler(
            preferences: preferences,
            articlesService: dependencies.articlesService
        )
        zikrShareActionHandler = ZikrShareActionHandler(
            preferences: preferences,
            player: player
        )
        _navigator = StateObject(
            wrappedValue: navigator
        )
        _rootViewModel = StateObject(wrappedValue: rootViewModel)
    }

    var body: some View {
        ZStack {
            preferences.colorTheme
                .getColor(.background)
                .ignoresSafeArea()

            NavigationControllerHost(
                stack: Binding(
                    get: { navigator.stack },
                    set: { navigator.stack = $0 }
                ),
                root: {
                    RootView(viewModel: rootViewModel)
                },
                destination: { destination in
                    AnyView(destinationView(destination))
                }
            )
            .ignoresSafeArea(.all, edges: .bottom)
        }
        .sheet(item: Binding(
            get: { navigator.sheet },
            set: { navigator.sheet = $0 }
        )) { sheet in
            sheetView(sheet)
        }
    }

    @ViewBuilder
    private func destinationView(_ destination: AppDestination) -> some View {
        switch destination {
        case .category(let category):
            if category == .other {
                CategoryRouteView(
                    category: category,
                    initialPage: navigator.selectedPage,
                    showsList: true,
                    showPageIndicators: false,
                    dependencies: dependencies,
                    navigator: navigator
                )
            } else {
                CategoryRouteView(
                    category: category,
                    initialPage: navigator.selectedPage,
                    showsList: false,
                    showPageIndicators: category == .hundredDua,
                    dependencies: dependencies,
                    navigator: navigator
                )
            }

        case .categoryReader(let request):
            CategoryRouteView(
                category: request.category,
                initialPage: request.initialPage,
                showsList: false,
                showPageIndicators: false,
                dependencies: dependencies,
                navigator: navigator
            )

        case .standaloneZikr(let request):
            StandaloneZikrRouteView(
                request: request,
                dependencies: dependencies,
                navigator: navigator
            )

        case .article(let article):
            ArticleRouteView(
                article: article,
                dependencies: dependencies,
                actionHandler: articleShareActionHandler
            )

        case .hadith(let hadith):
            HadithView(
                viewModel: HadithViewModel(
                    hadith: hadith,
                    highlightPattern: nil,
                    preferences: dependencies.preferences
                )
            )

        case .settings(let context):
            SettingsFlowView(
                preferences: dependencies.preferences,
                initialDestination: context.initialDestination,
                embedInNavigation: false
            )
        }
    }

    @ViewBuilder
    private func sheetView(_ sheet: AppSheet) -> some View {
        switch sheet.destination {
        case .settings(let context):
            SettingsFlowView(
                preferences: dependencies.preferences,
                initialDestination: context.initialDestination,
                embedInNavigation: true
            )

        case .share(let zikr):
            ZikrShareSheetView(
                zikr: zikr,
                actionHandler: zikrShareActionHandler
            )

        case .zikrCollectionsOnboarding(let preselectedCollection):
            ZikrCollectionsOnboardingFlowView(
                preselectedCollection: preselectedCollection,
                onZikrCollectionSelect: { newSource in
                    dependencies.preferences.zikrCollectionSource = newSource
                }
            )
        }
    }
}

private struct CategoryRouteView: View {

    @StateObject private var viewModel: ZikrPagesViewModel

    private let showsList: Bool
    private let showPageIndicators: Bool

    init(
        category: ZikrCategory,
        initialPage: Int,
        showsList: Bool,
        showPageIndicators: Bool,
        dependencies: AppDependencies,
        navigator: AppNavigator
    ) {
        self.showsList = showsList
        self.showPageIndicators = showPageIndicators
        _viewModel = StateObject(
            wrappedValue: ZikrPagesViewModel(
                navigator: navigator,
                category: category,
                title: category.title,
                azkar: dependencies.azkar(for: category),
                preferences: dependencies.preferences,
                selectedPagePublisher: navigator.selectedPagePublisher,
                initialPage: initialPage
            )
        )
    }

    var body: some View {
        if showsList {
            AzkarListView(viewModel: viewModel)
        } else {
            ZikrPagesView(
                viewModel: viewModel,
                showPageIndicators: showPageIndicators
            )
        }
    }
}

private struct StandaloneZikrRouteView: View {

    @StateObject private var viewModel: ZikrPagesViewModel

    init(
        request: StandaloneZikrRequest,
        dependencies: AppDependencies,
        navigator: AppNavigator
    ) {
        let zikrViewModel = dependencies.standaloneZikrViewModel(request: request) ?? .demo()
        _viewModel = StateObject(
            wrappedValue: ZikrPagesViewModel(
                navigator: navigator,
                category: .other,
                title: "",
                azkar: [zikrViewModel],
                preferences: dependencies.preferences,
                selectedPagePublisher: Empty().eraseToAnyPublisher(),
                initialPage: 0
            )
        )
    }

    var body: some View {
        ZikrPagesView(viewModel: viewModel)
    }
}

private struct ArticleRouteView: View {

    let article: Article
    let actionHandler: ArticleShareActionHandler

    @StateObject private var viewModel: ArticleViewModel

    init(article: Article, dependencies: AppDependencies, actionHandler: ArticleShareActionHandler) {
        self.article = article
        self.actionHandler = actionHandler
        _viewModel = StateObject(
            wrappedValue: ArticleViewModel(
                article: article,
                analyticsStream: {
                    await dependencies.articlesService.observeAnalyticsNumbers(articleId: article.id)
                },
                updateAnalytics: { numbers in
                    dependencies.articlesService.updateAnalyticsNumbers(
                        for: article.id,
                        views: numbers.viewsCount,
                        shares: numbers.sharesCount
                    )
                },
                fetchArticle: {
                    try? await dependencies.articlesService.getArticle(
                        article.id,
                        updatedAfter: article.updatedAt
                    )
                }
            )
        )
    }

    var body: some View {
        ArticleScreen(
            viewModel: viewModel,
            onShareButtonTap: {
                actionHandler.share(article)
            }
        )
    }
}
