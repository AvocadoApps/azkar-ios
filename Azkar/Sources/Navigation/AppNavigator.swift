import Foundation
import Combine
import Entities
import Library

@MainActor
final class AppNavigator: ObservableObject, AppNavigationRouting {

    @Published var stack: [AppDestination] = [] {
        didSet {
            syncCurrentCategoryContext()
        }
    }

    @Published var sheet: AppSheet?

    private let dependencies: AppDependencies
    private let deeplinker: Deeplinker
    private let selectedZikrPageIndex = CurrentValueSubject<Int, Never>(0)

    private var cancellables = Set<AnyCancellable>()
    private var currentCategoryContext: ZikrCategory?

    init(dependencies: AppDependencies, deeplinker: Deeplinker) {
        self.dependencies = dependencies
        self.deeplinker = deeplinker
        observeDeepLinks()
        handlePendingDeepLinkIfNeeded()
    }

    var selectedPagePublisher: AnyPublisher<Int, Never> {
        selectedZikrPageIndex
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var selectedPage: Int {
        selectedZikrPageIndex.value
    }

    func showCategory(_ category: ZikrCategory) {
        selectedZikrPageIndex.send(0)
        stack.append(.category(category))
    }

    func showCategoryReader(category: ZikrCategory, initialPage: Int) {
        selectedZikrPageIndex.send(initialPage)
        stack.append(.categoryReader(.init(category: category, initialPage: initialPage)))
    }

    func showZikr(_ zikr: Zikr) {
        selectedZikrPageIndex.send(0)
        storeOpenedZikr(zikr.id, language: zikr.language)
        stack.append(.standaloneZikr(.init(
            zikrId: zikr.id,
            language: zikr.language,
            highlightPattern: nil,
            isNested: true
        )))
    }

    func showRecentZikr(id: Zikr.ID) {
        guard let zikr = try? dependencies.databaseService.getZikr(id, language: dependencies.preferences.contentLanguage) else {
            return
        }
        showZikr(zikr)
    }

    func showSearchResult(_ result: SearchResultZikr, query: String) {
        selectedZikrPageIndex.send(0)
        storeOpenedZikr(result.zikrId, language: result.language)
        stack.append(.standaloneZikr(.init(
            zikrId: result.zikrId,
            language: result.language,
            highlightPattern: query,
            isNested: false
        )))
    }

    func showArticle(_ article: Article) {
        stack.append(.article(article))
        dependencies.articlesService.sendAnalyticsEvent(.view, articleId: article.id)
    }

    func showSettings(
        initialDestination: SettingsDestination? = nil,
        presentationStyle: SettingsPresentationStyle = .push
    ) {
        selectedZikrPageIndex.send(0)
        currentCategoryContext = nil

        let context = SettingsFlowContext(initialDestination: initialDestination)
        switch presentationStyle {
        case .push:
            stack.append(.settings(context))
        case .sheet:
            sheet = .init(destination: .settings(context))
        }
    }

    func showShareOptions(for zikr: Zikr) {
        sheet = .init(destination: .share(zikr))
    }

    func showZikrCollectionsOnboarding() {
        currentCategoryContext = nil
        sheet = .init(destination: .zikrCollectionsOnboarding(
            preselectedCollection: dependencies.preferences.zikrCollectionSource
        ))
    }

    func goToPage(_ page: Int) {
        selectedZikrPageIndex.send(page)
    }
}

private extension AppNavigator {

    func observeDeepLinks() {
        deeplinker.routes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] route in
                self?.handleDeepLink(route)
                _ = self?.deeplinker.takePendingRoute()
            }
            .store(in: &cancellables)
    }

    func handlePendingDeepLinkIfNeeded() {
        guard let route = deeplinker.takePendingRoute() else {
            return
        }
        handleDeepLink(route)
    }

    func handleDeepLink(_ route: Deeplinker.Route) {
        guard isNoopDeepLink(route) == false else {
            return
        }

        switch route {
        case .home:
            resetToRoot()

        case .settings(let destination):
            replaceStackForDeepLink(with: .settings(.init(initialDestination: destination)))

        case .azkar(let category):
            guard currentCategoryContext != category else {
                return
            }
            replaceStackForDeepLink(with: .category(category))

        case .categoryZikr(let category, let id):
            let azkar = dependencies.azkar(for: category)
            guard let index = azkar.firstIndex(where: { $0.zikr.id == id }) else {
                return
            }
            replaceStackForDeepLink(with: .categoryReader(.init(category: category, initialPage: index)))

        case .zikr(let id):
            guard (try? dependencies.databaseService.getZikr(id, language: dependencies.preferences.contentLanguage)) != nil else {
                return
            }
            replaceStackForDeepLink(with: .standaloneZikr(.init(
                zikrId: id,
                language: dependencies.preferences.contentLanguage,
                highlightPattern: nil,
                isNested: true
            )))

        case .article(let id):
            Task {
                guard let article = try? await dependencies.articlesService.getArticle(id, updatedAfter: nil) else {
                    return
                }
                await MainActor.run {
                    self.replaceStackForDeepLink(with: .article(article))
                    self.dependencies.articlesService.sendAnalyticsEvent(.view, articleId: article.id)
                }
            }

        case .hadith(let id):
            guard let hadith = try? dependencies.databaseService.getHadith(id) else {
                return
            }
            replaceStackForDeepLink(with: .hadith(hadith))
        }
    }

    func resetToRoot() {
        sheet = nil
        selectedZikrPageIndex.send(0)
        currentCategoryContext = nil
        stack = []
    }

    func replaceStackForDeepLink(with destination: AppDestination) {
        resetToRoot()
        stack = [destination]
    }

    func isNoopDeepLink(_ route: Deeplinker.Route) -> Bool {
        guard sheet == nil else {
            return false
        }

        switch route {
        case .home:
            return stack.isEmpty

        case .settings(let destination):
            guard case .settings(let context)? = stack.last else {
                return false
            }
            return context.initialDestination == destination

        case .azkar(let category):
            switch stack.last {
            case .category(let currentCategory):
                return currentCategory == category

            case .categoryReader(let request):
                return request.category == category

            default:
                return false
            }

        case .categoryZikr(let category, let id):
            guard case .categoryReader(let request)? = stack.last else {
                return false
            }
            let azkar = dependencies.azkar(for: category)
            guard azkar.indices.contains(request.initialPage) else {
                return false
            }
            return request.category == category && azkar[request.initialPage].zikr.id == id

        case .zikr(let id):
            guard case .standaloneZikr(let request)? = stack.last else {
                return false
            }
            return request.zikrId == id
                && request.language == dependencies.preferences.contentLanguage
                && request.highlightPattern == nil

        case .article(let id):
            guard case .article(let article)? = stack.last else {
                return false
            }
            return article.id == id

        case .hadith(let id):
            guard case .hadith(let hadith)? = stack.last else {
                return false
            }
            return hadith.id == id
        }
    }

    func storeOpenedZikr(_ id: Zikr.ID, language: Language) {
        Task {
            await dependencies.preferencesDatabase.storeOpenedZikr(id, language: language)
        }
    }

    func syncCurrentCategoryContext() {
        switch stack.last {
        case .category(let category):
            currentCategoryContext = category

        case .categoryReader(let request):
            currentCategoryContext = request.category == .other ? nil : request.category

        case .article,
             .hadith,
             .standaloneZikr,
             .settings,
             .none:
            currentCategoryContext = nil
        }
    }
}
