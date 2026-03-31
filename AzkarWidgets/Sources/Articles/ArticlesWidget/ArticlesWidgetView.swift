import SwiftUI
import WidgetKit
import Entities
import UIKit

struct ArticlesWidgetView: View {
    let entry: ArticlesWidgetEntry

    @Environment(\.widgetFamily) private var family

    private let cardCornerRadius: CGFloat = 22

    var body: some View {
        if let article = entry.article {
            content(article: article)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(articleAccessibilityLabel(for: article))
                .accessibilityHint(Text("widget.articles.a11y.open"))
        } else {
            emptyView
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("widget.articles.empty"))
        }
    }

    @ViewBuilder
    private func content(article: Article) -> some View {
        switch family {
        case .systemSmall:
            smallView(article: article)
        case .systemMedium:
            mediumView(article: article)
        case .systemLarge:
            largeView(article: article)
        default:
            smallView(article: article)
        }
    }

    @ViewBuilder
    private func smallView(article: Article) -> some View {
        GeometryReader { _ in
            VStack {
                Spacer(minLength: 0)

                HStack(alignment: .bottom) {
                    contentCard(horizontalPadding: 12, verticalPadding: 11) {
                        titleView(
                            article.title,
                            font: .system(size: 15, weight: .bold, design: .serif),
                            lineLimit: 3
                        )
                    }

                    Spacer(minLength: 0)
                }
            }
            .padding(10)
            .background {
                imageBackground(article: article)
            }
            .widgetContainer(cornerRadius: cardCornerRadius)
        }
    }

    @ViewBuilder
    private func mediumView(article: Article) -> some View {
        GeometryReader { geo in
            let imageColumnWidth = max(116, geo.size.width * 0.42)
            let contentWidth = max(110, geo.size.width - imageColumnWidth - 24)

            HStack(spacing: 0) {
                Color.clear
                    .frame(width: imageColumnWidth)

                VStack {
                    Spacer(minLength: 0)

                    HStack(alignment: .bottom) {
                        contentCard(horizontalPadding: 14, verticalPadding: 13) {
                            VStack(alignment: .leading, spacing: 8) {
                                titleView(
                                    article.title,
                                    font: .system(size: 17, weight: .bold, design: .serif),
                                    lineLimit: 3
                                )

                                statsRow(article: article)
                            }
                        }
                        .frame(maxWidth: contentWidth, alignment: .leading)

                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(12)
            .background {
                imageBackground(article: article)
            }
            .widgetContainer(cornerRadius: cardCornerRadius)
        }
    }

    @ViewBuilder
    private func largeView(article: Article) -> some View {
        GeometryReader { _ in
            VStack {
                Spacer(minLength: 0)

                HStack(alignment: .bottom) {
                    contentCard(horizontalPadding: 16, verticalPadding: 14) {
                        VStack(alignment: .leading, spacing: 8) {
                            titleView(
                                article.title,
                                font: .system(size: 20, weight: .black, design: .serif),
                                lineLimit: 3
                            )

                            statsRow(article: article)

                            articleExcerpt(article: article, lineLimit: 3, opacity: 0.82)
                        }
                    }

                    Spacer(minLength: 0)
                }
            }
            .padding(14)
            .background {
                imageBackground(article: article)
            }
            .widgetContainer(cornerRadius: cardCornerRadius)
        }
    }

    private func articleExcerpt(
        article: Article,
        lineLimit: Int,
        opacity: Double
    ) -> some View {
        Text(stripMarkdown(article.text))
            .font(.system(size: 13))
            .foregroundStyle(.white.opacity(opacity))
            .lineLimit(lineLimit)
            .multilineTextAlignment(.leading)
            .minimumScaleFactor(0.8)
    }

    private func titleView(
        _ title: String,
        font: Font,
        lineLimit: Int
    ) -> some View {
        Text(title)
            .font(font)
            .minimumScaleFactor(0.62)
            .lineLimit(lineLimit)
            .multilineTextAlignment(.leading)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func stripMarkdown(_ text: String) -> String {
        text
            .replacingOccurrences(of: #"[*_]{1,3}(.+?)[*_]{1,3}"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"\[(.+?)\]\(.+?\)"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"^#{1,6}\s+"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"^[>\-\*]\s+"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"`(.+?)`"#, with: "$1", options: .regularExpression)
    }

    private func articleAccessibilityLabel(for article: Article) -> String {
        var parts = [article.title]

        if family != .systemSmall {
            if article.views > 0 {
                parts.append(
                    String(
                        format: String(localized: "widget.articles.a11y.views", bundle: .main),
                        locale: Locale.current,
                        article.views.formatted()
                    )
                )
            }

            if article.shares > 0 {
                parts.append(
                    String(
                        format: String(localized: "widget.articles.a11y.shares", bundle: .main),
                        locale: Locale.current,
                        article.shares.formatted()
                    )
                )
            }
        }

        if family == .systemLarge {
            let excerpt = truncatedAccessibilityExcerpt(from: article.text)
            if excerpt.isEmpty == false {
                parts.append(excerpt)
            }
        }

        return parts.joined(separator: ". ")
    }

    private func truncatedAccessibilityExcerpt(from text: String, maxLength: Int = 180) -> String {
        let stripped = stripMarkdown(text)
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard stripped.count > maxLength else {
            return stripped
        }

        let index = stripped.index(stripped.startIndex, offsetBy: maxLength)
        return stripped[stripped.startIndex..<index].trimmingCharacters(in: .whitespacesAndNewlines) + "…"
    }

    @ViewBuilder
    private func statsRow(article: Article) -> some View {
        if article.views > 0 || article.shares > 0 {
            HStack(spacing: 12) {
                if article.views > 0 {
                    Label(abbreviateNumber(article.views), systemImage: "eye")
                }
                if article.shares > 0 {
                    Label(abbreviateNumber(article.shares), systemImage: "square.and.arrow.up")
                }
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white.opacity(0.76))
        }
    }

    @ViewBuilder
    private func imageBackground(article: Article) -> some View {
        if let imageData = entry.imageData,
           let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .accessibilityHidden(true)
        } else if let resourceName = article.imageResourceName {
            Image(resourceName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .accessibilityHidden(true)
        } else {
            ZStack {
                Color(.systemBackground)
                Image(systemName: "doc.richtext")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
            .accessibilityHidden(true)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.richtext")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("widget.articles.empty")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    @ViewBuilder
    private func contentCard<Content: View>(
        horizontalPadding: CGFloat,
        verticalPadding: CGFloat,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 4)
    }

    private var cardBackground: some View {
        LinearGradient(
            colors: [
                .black.opacity(0.93),
                Color(red: 0.14, green: 0.14, blue: 0.16)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func abbreviateNumber(_ number: Int) -> String {
        if number >= 1_000_000 {
            return String(format: "%.1fM", Double(number) / 1_000_000)
        } else if number >= 1_000 {
            return String(format: "%.1fK", Double(number) / 1_000)
        }
        return "\(number)"
    }
}

private extension View {
    func widgetContainer(cornerRadius: CGFloat) -> some View {
        self
            .background(Color("WidgetBackground"))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
