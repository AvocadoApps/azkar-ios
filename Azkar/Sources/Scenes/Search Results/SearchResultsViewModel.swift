import SwiftUI
import Combine
import Library
import Entities

struct SearchResultZikr: Identifiable, Hashable {
    let id = UUID()
    var title: String?
    var text: String?
    var translation: String?
    var caption: String?
    var caption2: String?
    var footnote: String?
    let highlightText: String
    let zikrId: Zikr.ID
    let language: Language
}

extension SearchResultZikr {
    
    private static func extractContextFrom(
        _ string: String?,
        query: String
    ) -> String? {
        guard let string else { return nil }
        return string
            .extractContext(query).reduce("", { $0 + "\n\n" + $1.context })
            .textOrNil
    }
    
    init(zikr: Zikr, query: String) {
        var title: String?
        let titleMatches = SearchResultZikr.extractContextFrom(zikr.title, query: query)
        let textMatches = SearchResultZikr.extractContextFrom(zikr.text.trimmingArabicVowels, query: query.trimmingArabicVowels)
        let translationMatches = SearchResultZikr.extractContextFrom(zikr.translation, query: query)
        let sourceMatches = SearchResultZikr.extractContextFrom(zikr.source, query: query)
        let benefitsMatches = SearchResultZikr.extractContextFrom(zikr.benefits, query: query)
        let notesMatches = SearchResultZikr.extractContextFrom(zikr.notes, query: query)
        
        if titleMatches == nil, textMatches == nil, translationMatches == nil, sourceMatches == nil, benefitsMatches == nil, notesMatches == nil {
            if let zikrTitle = zikr.title {
                title = zikrTitle
            } else if let translation = zikr.translation {
                title = translation.prefix(50) + "..."
            }
        }
        
        self.init(
            title: title ?? titleMatches,
            text: textMatches,
            translation: translationMatches,
            caption: sourceMatches,
            caption2: benefitsMatches,
            footnote: notesMatches,
            highlightText: query,
            zikrId: zikr.id,
            language: zikr.language
        )
    }
}

struct SearchResultsSection: Identifiable {
    let id = UUID()
    let title: String?
    let image: String?
    let results: [SearchResultZikr]
}

final class SearchResultsViewModel: ObservableObject {
    
    @Published var searchResults: [SearchResultsSection] = []
    @Published var selectedTokens: [SearchToken] = []
    @Published var isPerformingSearch = false
    
    var haveSearchResults: Bool {
        searchResults.isEmpty == false
    }
    
    private let azkarDatabase: AzkarDatabase
    private let analytics: AppAnalyticsTracking
    private var cancellables = Set<AnyCancellable>()
    
    init(
        azkarDatabase: AzkarDatabase,
        preferencesDatabase: PreferencesDatabase,
        searchTokens: AnyPublisher<[SearchToken], Never>,
        searchQuery: AnyPublisher<String, Never>,
        analytics: AppAnalyticsTracking
    ) {
        self.azkarDatabase = azkarDatabase
        self.analytics = analytics
        searchTokens.assign(to: &$selectedTokens)
        searchQuery.map { _ in [] }.assign(to: &$searchResults)
        configureSearch(
            query: searchQuery.eraseToAnyPublisher(),
            tokens: searchTokens,
            azkarDatabase: azkarDatabase,
            preferencesDatabase: preferencesDatabase
        )
    }
    
    private func configureSearch(
        query: AnyPublisher<String, Never>,
        tokens: AnyPublisher<[SearchToken], Never>,
        azkarDatabase: AzkarDatabase,
        preferencesDatabase: PreferencesDatabase
    ) {
        let searchManagers = ZikrCategory.allCases.map { category in
            return SearchManager(
                category: category,
                languages: Language.allCases.filter(azkarDatabase.translationExists(for:)),
                azkarDatabase: azkarDatabase
            )
        }
        
        let searchResults = query
            .combineLatest(tokens)
            .debounce(
                for: .seconds(1),
                scheduler: DispatchQueue.main
            )
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .flatMap(maxPublishers: .max(1)) { query, tokens -> AnyPublisher<[SearchResultsSection], Never> in
                guard let query = query.textOrNil, query.count >= 3 else {
                    return Just([]).eraseToAnyPublisher()
                }
                
                let searchTokens = tokens.isEmpty ? SearchToken.allCases : tokens
                searchManagers.forEach { manager in
                    if searchTokens.contains(where: { $0 == manager.category }) {
                        manager.performSearch(query: query)
                    }
                }
                return Publishers.ZipMany(searchManagers.map(\.searchResultSections))
                    .eraseToAnyPublisher()
            }
            .map { sections in
                sections.filter { $0.results.isEmpty == false }
            }
            .receive(on: DispatchQueue.main)
            .share()
            .eraseToAnyPublisher()
        
        searchResults.combineLatest(query)
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink(receiveValue: { results, query in
                if query.count >= 3, results.contains(where: { !$0.results.isEmpty }) {
                    Task {
                        await preferencesDatabase.storeSearchQuery(query)
                    }
                }

                guard query.count >= 3 else {
                    return
                }

                let resultCount = results.reduce(0) { $0 + $1.results.count }
                self.analytics.track(.searchPerformed(
                    queryLength: query.count,
                    selectedTokenCount: self.selectedTokens.count,
                    sectionCount: results.count,
                    resultCount: resultCount
                ))
            })
            .store(in: &cancellables)
        
        searchResults.assign(to: &$searchResults)
        
        Publishers.Merge(
            query.map { _ in true },
            searchResults.map { _ in false }
        )
        .assign(to: &$isPerformingSearch)
    }
    
}

extension SearchResultsViewModel {
    static var placeholder: SearchResultsViewModel {
        let vm = SearchResultsViewModel(
            azkarDatabase: .init(language: Language.english),
            preferencesDatabase: MockPreferencesDatabase(),
            searchTokens: Empty().eraseToAnyPublisher(),
            searchQuery: Empty().eraseToAnyPublisher(),
            analytics: NoopAppAnalytics()
        )
        vm.searchResults = [
            .init(title: "Placeholder", image: "book", results: [
                SearchResultZikr(zikr: .placeholder(id: 1), query: "title"),
                SearchResultZikr(zikr: .placeholder(id: 2), query: "translation"),
                SearchResultZikr(zikr: .placeholder(id: 3), query: "notes"),
            ])
        ]
        return vm
    }
}
