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
    /// Exact (vowelled) substrings to underline in the Arabic `text` field.
    /// When non-empty these take precedence over `highlightText`, which can't
    /// match the original text once vowels/alef-variants differ from the query.
    var textHighlights: [String] = []
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
        // Match against the normalized (vowel/alef-insensitive) text but display
        // the original text with its tashkeel, highlighting the matched spans.
        let arabicTextMatch = zikr.text.extractArabicHighlightContexts(query: query)
        let textMatches = arabicTextMatch?.snippet
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
            textHighlights: arabicTextMatch?.matches ?? [],
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
        searchTokens: AnyPublisher<[SearchToken], Never>,
        searchQuery: AnyPublisher<String, Never>,
        analytics: AppAnalyticsTracking
    ) {
        self.azkarDatabase = azkarDatabase
        self.analytics = analytics
        searchTokens.assign(to: &$selectedTokens)
        configureSearch(
            query: searchQuery.eraseToAnyPublisher(),
            tokens: searchTokens,
            azkarDatabase: azkarDatabase
        )
    }

    private func configureSearch(
        query: AnyPublisher<String, Never>,
        tokens: AnyPublisher<[SearchToken], Never>,
        azkarDatabase: AzkarDatabase
    ) {
        let searchManagers = ZikrCategory.allCases.map { category in
            return SearchManager(
                category: category,
                languages: Language.allCases.filter(azkarDatabase.translationExists(for:)),
                azkarDatabase: azkarDatabase
            )
        }

        let computedResults = query
            .combineLatest(tokens)
            .debounce(
                for: .seconds(0.3),
                scheduler: DispatchQueue.main
            )
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .flatMap(maxPublishers: .max(1)) { query, tokens -> AnyPublisher<[SearchResultsSection], Never> in
                guard let query = query.textOrNil, query.count >= 3 else {
                    SearchLog.log("ViewModel: query too short or empty (query=\(query.debugDescription)) — clearing results")
                    return Just([]).eraseToAnyPublisher()
                }

                let searchTokens = tokens.isEmpty ? SearchToken.allCases : tokens
                SearchLog.log("ViewModel: dispatching search query=\(query.debugDescription) activeTokens=\(searchTokens.map(\.rawValue))")
                searchManagers.forEach { manager in
                    if searchTokens.contains(where: { $0 == manager.category }) {
                        manager.performSearch(query: query)
                    }
                }
                return Publishers.ZipMany(searchManagers.map(\.searchResultSections))
                    .eraseToAnyPublisher()
            }
            .map { sections in
                let nonEmpty = sections.filter { $0.results.isEmpty == false }
                SearchLog.log("ViewModel: aggregated \(sections.count) section(s), \(nonEmpty.count) non-empty — \(nonEmpty.map { "\($0.title ?? "?"):\($0.results.count)" })")
                return nonEmpty
            }
            .receive(on: DispatchQueue.main)
            .share()
            .eraseToAnyPublisher()

        // Clear results immediately when the query changes, then replace with
        // real results once the search pipeline emits.
        Publishers.Merge(
            query.map { _ -> [SearchResultsSection] in [] },
            computedResults
        )
        .assign(to: &$searchResults)

        computedResults.combineLatest(query)
            .sink(receiveValue: { [weak self] results, query in
                guard let self, query.count >= 3 else { return }

                let resultCount = results.reduce(0) { $0 + $1.results.count }
                self.analytics.search.performed(
                    queryLength: query.count,
                    selectedTokenCount: self.selectedTokens.count,
                    sectionCount: results.count,
                    resultCount: resultCount
                )
            })
            .store(in: &cancellables)

        Publishers.Merge(
            query.map { $0.count >= 3 },
            computedResults.map { _ in false }
        )
        .assign(to: &$isPerformingSearch)
    }
    
}

extension SearchResultsViewModel {
    static var placeholder: SearchResultsViewModel {
        let vm = SearchResultsViewModel(
            azkarDatabase: .init(language: Language.english),
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
