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

    private struct ReleaseNotesPayloadSection: Decodable {
        let title: String
        let imageName: String?
        let items: [ReleaseNotes]
    }

    @InjectedObject(\.preferences) private var preferences: Preferences
    @Injected(\.appDependencies) private var dependencies: AppDependencies
    @Injected(\.articleShareActionHandler) private var articleShareActionHandler: ArticleShareActionHandler
    @Injected(\.zikrShareActionHandler) private var zikrShareActionHandler: ZikrShareActionHandler

    @InjectedObject(\.appNavigator) private var navigator: AppNavigator
    @InjectedObject(\.rootViewModel) private var rootViewModel: RootViewModel

    @State private var showWhatsNew = false
    @AppStorage("lastSeenVersion") private var lastSeenVersion: String = ""

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
        .sheet(isPresented: $showWhatsNew) {
            let notes = Self.loadReleaseNotes(lastSeenVersion: lastSeenVersion)
            ChangelogScreen(
                color: .white,
                background: .solidColor(Color(.systemBackground)),
                currentItems: notes.current,
                historySections: Self.groupIntoSections(notes.history),
                strings: Self.releaseNotesStrings,
                history: true,
                onContinue: {
                    showWhatsNew = false
                    lastSeenVersion = Self.appVersion
                }
            )
        }
        .onAppear {
            if lastSeenVersion != Self.appVersion {
                showWhatsNew = true
            }
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

    private static func loadReleaseNotesPayload() -> [ReleaseNotesPayloadSection]? {
        guard let url = Bundle.main.url(forResource: "data", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let sections = try? JSONDecoder().decode([ReleaseNotesPayloadSection].self, from: data) else {
            return nil
        }

        return sections
    }

    static func loadAllReleaseNotes() -> [ReleaseNotes] {
        loadReleaseNotesPayload()?.flatMap(\.items) ?? []
    }

    static func loadReleaseNotes(lastSeenVersion: String) -> (current: [ReleaseNotes], history: [ReleaseNotes]) {
        let all = loadAllReleaseNotes()
        guard !all.isEmpty else {
            return ([], [])
        }

        let current: [ReleaseNotes]
        if lastSeenVersion.isEmpty {
            current = Array(all.prefix(1))
        } else {
            let unseen = all.filter {
                $0.version.compare(lastSeenVersion, options: .numeric) == .orderedDescending
            }
            current = unseen.isEmpty ? Array(all.prefix(1)) : unseen
        }
        let history = all.filter { !current.contains($0) }
        return (current, history)
    }

    static var releaseNotesStrings: ChangelogStrings {
        ChangelogStrings(
            historyTitle: String(localized: "release-notes.history"),
            showHistoryButton: String(localized: "release-notes.show-history"),
            continueButton: String(localized: "common.done"),
            returnButton: String(localized: "release-notes.return"),
            dismissHistoryButton: String(localized: "common.done"),
            whatsNewIn: String(localized: "release-notes.whats-new-in"),
            version: String(localized: "common.version")
        )
    }

    static func groupIntoSections(_ items: [ReleaseNotes]) -> [ReleaseNotesSection] {
        guard let sections = loadReleaseNotesPayload() else {
            return []
        }

        let versions = Set(items.map(\.version))

        return sections.compactMap { section in
            let sectionItems = section.items.filter { versions.contains($0.version) }
            guard !sectionItems.isEmpty else {
                return nil
            }

            return ReleaseNotesSection(title: section.title, imageName: section.imageName, items: sectionItems)
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
