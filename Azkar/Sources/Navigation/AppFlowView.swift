import SwiftUI
import Combine
import FactoryKit
import Library
import Entities
import ArticleReader
import ZikrCollectionsOnboarding
import ChangelogKit

@MainActor
struct AppFlowView: View {

    @InjectedObject(\.preferences) private var preferences: Preferences
    @Injected(\.appDependencies) private var dependencies: AppDependencies
    @Injected(\.articleShareActionHandler) private var articleShareActionHandler: ArticleShareActionHandler
    @Injected(\.zikrShareActionHandler) private var zikrShareActionHandler: ZikrShareActionHandler

    @InjectedObject(\.appNavigator) private var navigator: AppNavigator
    @InjectedObject(\.rootViewModel) private var rootViewModel: RootViewModel

    init() {
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
                    showPageIndicators: preferences.showPageIndicators(for:category),
                    dependencies: dependencies,
                    navigator: navigator
                )
            } else {
                CategoryRouteView(
                    category: category,
                    initialPage: navigator.selectedPage,
                    showsList: false,
                    showPageIndicators: preferences.showPageIndicators(for:category),
                    dependencies: dependencies,
                    navigator: navigator
                )
            }

        case .categoryReader(let request):
            CategoryRouteView(
                category: request.category,
                initialPage: request.initialPage,
                showsList: false,
                showPageIndicators: preferences.showPageIndicators(for:request.category),
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

    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    static func loadAllSections() -> [ReleaseNotesSection] {
        guard let url = Bundle.main.url(forResource: "data", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let sections = try? JSONDecoder().decode([ReleaseNotesSection].self, from: data) else {
            return []
        }
        return sections
    }

    static func loadAllReleaseNotes() -> [ReleaseNotes] {
        loadAllSections().flatMap(\.items)
    }

    static func hasUnseenReleaseNotes(since lastSeenVersion: String) -> Bool {
        if lastSeenVersion.isEmpty {
            return loadAllReleaseNotes().isEmpty == false
        }

        return boundaryVersion(for: lastSeenVersion) != nil
    }

    /// Returns the version string that marks the boundary between new and previously seen notes.
    ///
    /// If `lastSeenVersion` doesn't exist in the changelog, the highest version
    /// that is less than or equal to it is used instead.
    static func boundaryVersion(for lastSeenVersion: String) -> String? {
        guard !lastSeenVersion.isEmpty else { return nil }
        let all = loadAllReleaseNotes()
        let hasUnseen = all.contains {
            $0.version.compare(lastSeenVersion, options: .numeric) == .orderedDescending
        }
        guard hasUnseen else { return nil }
        // Pick the highest changelog version <= lastSeenVersion.
        let seen = all.filter {
            $0.version.compare(lastSeenVersion, options: .numeric) != .orderedDescending
        }
        return seen.first?.version ?? all.last?.version
    }

    static var releaseNotesStrings: ChangelogStrings {
        ChangelogStrings(
            previouslySeenTitle: String(localized: "release-notes.previously-seen"),
            screenTitle: String(localized: "release-notes.whats-new"),
            continueButton: String(localized: "common.done")
        )
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
                analytics: dependencies.analytics,
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
                analytics: dependencies.analytics,
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
