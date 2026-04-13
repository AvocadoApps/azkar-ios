import Foundation
import Entities

enum SettingsPresentationStyle {
    case push
    case sheet
}

struct SettingsFlowContext: Hashable {
    let initialDestination: SettingsDestination?
}

struct CategoryReaderRequest: Hashable {
    let category: ZikrCategory
    let initialPage: Int
}

struct StandaloneZikrRequest: Hashable {
    let zikrId: Zikr.ID
    let language: Language
    let highlightPattern: String?
    let isNested: Bool
}

enum AppDestination: Hashable {
    case category(ZikrCategory)
    case categoryReader(CategoryReaderRequest)
    case standaloneZikr(StandaloneZikrRequest)
    case article(Article)
    case hadith(Hadith)
    case settings(SettingsFlowContext)
}

struct AppSheet: Identifiable {
    enum Destination {
        case settings(SettingsFlowContext)
        case share(Zikr)
        case zikrCollectionsOnboarding(preselectedCollection: ZikrCollectionSource)
    }

    let id = UUID()
    let destination: Destination
}

@MainActor
protocol AppNavigationRouting: AnyObject {
    func showCategory(_ category: ZikrCategory)
    func showCategoryReader(category: ZikrCategory, initialPage: Int)
    func showZikr(_ zikr: Zikr)
    func showRecentZikr(id: Zikr.ID)
    func showSearchResult(_ result: SearchResultZikr, query: String)
    func showArticle(_ article: Article)
    func showSettings(initialDestination: SettingsDestination?, presentationStyle: SettingsPresentationStyle)
    func showShareOptions(for zikr: Zikr)
    func showZikrCollectionsOnboarding()
    func goToPage(_ page: Int)
}

@MainActor
final class EmptyAppNavigator: AppNavigationRouting {
    func showCategory(_ category: ZikrCategory) {}
    func showCategoryReader(category: ZikrCategory, initialPage: Int) {}
    func showZikr(_ zikr: Zikr) {}
    func showRecentZikr(id: Zikr.ID) {}
    func showSearchResult(_ result: SearchResultZikr, query: String) {}
    func showArticle(_ article: Article) {}
    func showSettings(initialDestination: SettingsDestination?, presentationStyle: SettingsPresentationStyle) {}
    func showShareOptions(for zikr: Zikr) {}
    func showZikrCollectionsOnboarding() {}
    func goToPage(_ page: Int) {}
}
