import SwiftUI
import Library
import Entities

@dynamicMemberLookup
public final class ArticleViewModel: ObservableObject {
    
    var article: Article
    @Published var views: Int?
    @Published var viewsAbbreviated: String?
    @Published var shares: Int?
    @Published var sharesAbbreviated: String?
    
    private let analyticsStream: () async -> AsyncStream<ArticleAnalytics>
    private let updateAnalytics: (ArticleAnalytics) async -> Void
    private let fetchArticle: () async -> Article?
    
    subscript<T>(dynamicMember keyPath: KeyPath<Article, T>) -> T {
        article[keyPath: keyPath]
    }
    
    public init(
        article: Article,
        analyticsStream: @escaping () async -> AsyncStream<ArticleAnalytics>,
        updateAnalytics: @escaping (ArticleAnalytics) async -> Void,
        fetchArticle: @escaping () async -> Article?
    ) {
        self.article = article
        self.analyticsStream = analyticsStream
        self.updateAnalytics = updateAnalytics
        self.fetchArticle = fetchArticle
        updateNumbers()
        
        Task {
            await observeAnalyticsNumbers()
        }
        
        Task(priority: .utility) {
            await updateArticle()
        }
    }
    
    @MainActor private func observeAnalyticsNumbers() async {
        for await numbers in await analyticsStream() {
            withAnimationIfAllowed(.spring) {
                setViews(numbers.viewsCount)
                setShares(numbers.sharesCount)
            }
            Task.detached {
                await self.updateAnalytics(numbers)
            }
        }
    }
    
    @MainActor private func updateArticle() async {
        if let updatedArticle = await fetchArticle() {
            self.article = updatedArticle
            self.updateNumbers()
        }
    }
    
    private func updateNumbers() {
        setViews(article.views)
        setShares(article.shares)
    }
    
    private func setViews(_ number: Int) {
        guard number > 0 else { return }
        views = number
        viewsAbbreviated = number.toAbbreviatedString()
    }
    
    private func setShares(_ number: Int) {
        guard number > 0 else { return }
        shares = number
        sharesAbbreviated = number.toAbbreviatedString()
    }
    
}
