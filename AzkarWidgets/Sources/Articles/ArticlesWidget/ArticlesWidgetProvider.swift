import WidgetKit
import Entities

struct ArticlesWidgetProvider: TimelineProvider {
    private let language: Language

    init(language: Language) {
        self.language = language
    }

    func placeholder(in context: Context) -> ArticlesWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (ArticlesWidgetEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }

        Task {
            let articles = ArticlesWidgetDataSource.fetchArticles(language: language)
            guard let article = articles.first else {
                completion(ArticlesWidgetEntry(date: Date(), article: nil, imageData: nil))
                return
            }

            let imageData = await ArticlesWidgetDataSource.loadImageData(from: article)
            completion(ArticlesWidgetEntry(date: Date(), article: article, imageData: imageData))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ArticlesWidgetEntry>) -> Void) {
        Task {
            let articles = ArticlesWidgetDataSource.fetchArticles(language: language)

            guard let article = articles.first else {
                let entry = ArticlesWidgetEntry(date: Date(), article: nil, imageData: nil)
                completion(Timeline(entries: [entry], policy: .after(nextUpdate())))
                return
            }

            let imageData = await ArticlesWidgetDataSource.loadImageData(from: article)
            let entry = ArticlesWidgetEntry(date: Date(), article: article, imageData: imageData)
            completion(Timeline(entries: [entry], policy: .after(nextUpdate())))
        }
    }

    private func nextUpdate() -> Date {
        Calendar.current.date(byAdding: .hour, value: 6, to: Date())!
    }
}
