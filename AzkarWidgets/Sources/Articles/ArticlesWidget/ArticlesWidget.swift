import SwiftUI
import WidgetKit
import Entities

struct ArticlesWidget: Widget {
    let kind = "AzkarArticles"

    @Preference(
        "kContentLanguage",
        defaultValue: Language.getSystemLanguage(),
        userDefaults: WIDGET_APP_GROUP_USER_DEFAULTS
    )
    var language: Language

    var body: some WidgetConfiguration {
        let config = StaticConfiguration(
            kind: kind,
            provider: ArticlesWidgetProvider(language: language.fallbackLanguage)
        ) { entry in
            if #available(iOS 17, *) {
                widgetContent(entry: entry)
                    .containerBackground(for: .widget) {
                        Color.clear
                    }
            } else {
                widgetContent(entry: entry)
            }
        }
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .configurationDisplayName("widget.articles.title")
        .description("widget.articles.description")

        if #available(iOS 17, *) {
            return config.contentMarginsDisabled()
        } else {
            return config
        }
    }

    @ViewBuilder
    private func widgetContent(entry: ArticlesWidgetEntry) -> some View {
        if let article = entry.article {
            ArticlesWidgetView(entry: entry)
                .widgetURL(URL(string: "azkar://article/\(article.id)"))
        } else {
            ArticlesWidgetView(entry: entry)
        }
    }
}
