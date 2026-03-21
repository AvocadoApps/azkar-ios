import Foundation
import Combine
import Entities

private let SEARCH_RESULTS_LIMIT: UInt8 = 5

final class SearchManager {
    
    var searchResultSections: AnyPublisher<SearchResultsSection, Never> {
        searchResultSectionsPublisher.eraseToAnyPublisher()
    }
    let category: ZikrCategory

    private var searchTask: Task<Void, Never>?
    private let searchResultSectionsPublisher = PassthroughSubject<SearchResultsSection, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    private let languages: [Language]
    private let azkarDatabase: AzkarDatabase

    init(
        category: ZikrCategory,
        languages: [Language],
        azkarDatabase: AzkarDatabase
    ) {
        self.category = category
        self.languages = languages
        self.azkarDatabase = azkarDatabase
    }

    func performSearch(
        query: String
    ) {
        // Cancel the previous task if it's still running
        searchTask?.cancel()

        // Start a new search task
        searchTask = Task {
            let results = await executeSearch(query: query)
            searchResultSectionsPublisher.send(SearchResultsSection(
                title: category.title,
                image: category.systemImageName,
                results: results.map { zikr in
                    SearchResultZikr(zikr: zikr, query: query)
                }
            ))
        }
    }

    private func executeSearch(
        query: String
    ) async -> [Zikr] {
        do {
            return try await azkarDatabase.searchAdhkar(
                query,
                resultsLimit: SEARCH_RESULTS_LIMIT,
                category: category,
                languages: languages
            )
        } catch {
            print(error.localizedDescription)
            return []
        }
    }
    
}
