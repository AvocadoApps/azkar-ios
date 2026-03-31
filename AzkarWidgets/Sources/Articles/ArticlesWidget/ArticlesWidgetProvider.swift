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
            let currentDate = Date()

            guard !articles.isEmpty else {
                let entry = ArticlesWidgetEntry(date: currentDate, article: nil, imageData: nil)
                completion(Timeline(entries: [entry], policy: .after(nextUpdate())))
                return
            }

            let entries = await withTaskGroup(of: ArticlesWidgetEntry.self) { group in
                for (index, article) in articles.prefix(10).enumerated() {
                    group.addTask {
                        let entryDate = Calendar.current.date(byAdding: .hour, value: index, to: currentDate) ?? currentDate
                        let imageData = await ArticlesWidgetDataSource.loadImageData(from: article)
                        return ArticlesWidgetEntry(date: entryDate, article: article, imageData: imageData)
                    }
                }

                var collectedEntries: [ArticlesWidgetEntry] = []
                for await entry in group {
                    collectedEntries.append(entry)
                }

                return collectedEntries.sorted { $0.date < $1.date }
            }

            completion(Timeline(entries: entries, policy: .after(nextUpdate())))
        }
    }

    private func nextUpdate() -> Date {
        Calendar.current.date(byAdding: .hour, value: 6, to: Date())!
    }
}
