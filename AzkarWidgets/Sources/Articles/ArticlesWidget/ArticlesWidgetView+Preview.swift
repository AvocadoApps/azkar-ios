import SwiftUI
import WidgetKit
import Entities
import UIKit

#if DEBUG
private enum ArticlesWidgetPreviewFactory {
    struct LocalizedText {
        let russian: String
        let english: String
        let arabic: String
        let turkish: String

        func value(for language: Language) -> String {
            switch language {
            case .russian:
                return russian
            case .arabic:
                return arabic
            case .turkish:
                return turkish
            default:
                return english
            }
        }
    }

    struct MockArticle {
        let title: String
        let text: String
        let language: Language
        let color: UIColor
        let views: Int
        let shares: Int
    }

    static func entry(_ article: MockArticle) -> ArticlesWidgetEntry {
        ArticlesWidgetEntry(
            date: Date(),
            article: Article.placeholder(
                id: Int.random(in: 1...9999),
                language: article.language,
                title: article.title,
                text: article.text,
                createdAt: Date(),
                updatedAt: Date(),
                textFormat: .markdown,
                coverImageFormat: .titleBackground
            )
            .withAnalytics(views: article.views, shares: article.shares),
            imageData: previewImageData() ?? makeImageData(color: article.color)
        )
    }

    static let placeholderTitle = LocalizedText(
        russian: "Мольба — лекарство",
        english: "Supplication Is a Remedy",
        arabic: "الدعاء دواء",
        turkish: "Dua bir ilactir"
    )

    static let placeholderText = LocalizedText(
        russian: "Мольба относится к наиболее полезным лекарствам.",
        english: "Supplication is among the most beneficial remedies.",
        arabic: "الدعاء من انفع الادوية.",
        turkish: "Dua en faydali ilaclardan biridir."
    )

    static func placeholder(
        language: Language,
        views: Int = 0,
        shares: Int = 0,
        color: UIColor
    ) -> MockArticle {
        MockArticle(
            title: placeholderTitle.value(for: language),
            text: placeholderText.value(for: language),
            language: language,
            color: color,
            views: views,
            shares: shares
        )
    }

    private static func makeImageData(
        color: UIColor,
        size: CGSize = CGSize(width: 900, height: 900)
    ) -> Data? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let overlayColors = [
                color.withAlphaComponent(0.15).cgColor,
                UIColor.black.withAlphaComponent(0.28).cgColor
            ] as CFArray
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let locations: [CGFloat] = [0, 1]

            guard let gradient = CGGradient(colorsSpace: colorSpace, colors: overlayColors, locations: locations) else {
                return
            }

            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )
        }

        return image.jpegData(compressionQuality: 0.9)
    }

    private static func previewImageData() -> Data? {
        UIImage(named: "article-widget-preview")?.jpegData(compressionQuality: 0.88)
    }
}

@available(iOS 17, *)
#Preview("Small • Short Title", as: .systemSmall) {
    ArticlesWidget()
} timeline: {
    ArticlesWidgetPreviewFactory.entry(
        ArticlesWidgetPreviewFactory.placeholder(
            language: .russian,
            views: 12840,
            shares: 320,
            color: .systemOrange
        )
    )
}

@available(iOS 17, *)
#Preview("Small • Long Title", as: .systemSmall) {
    ArticlesWidget()
} timeline: {
    ArticlesWidgetPreviewFactory.entry(
        ArticlesWidgetPreviewFactory.placeholder(
            language: .arabic,
            views: 9630,
            shares: 250,
            color: .systemBlue
        )
    )
}

@available(iOS 17, *)
#Preview("Medium • Stats", as: .systemMedium) {
    ArticlesWidget()
} timeline: {
    ArticlesWidgetPreviewFactory.entry(
        ArticlesWidgetPreviewFactory.placeholder(
            language: .russian,
            views: 18420,
            shares: 910,
            color: .systemTeal
        )
    )
}

@available(iOS 17, *)
#Preview("Medium • No Stats", as: .systemMedium) {
    ArticlesWidget()
} timeline: {
    ArticlesWidgetPreviewFactory.entry(
        ArticlesWidgetPreviewFactory.placeholder(
            language: .russian,
            color: .systemBlue
        )
    )
}

@available(iOS 17, *)
#Preview("Large • Full Content", as: .systemLarge) {
    ArticlesWidget()
} timeline: {
    ArticlesWidgetPreviewFactory.entry(
        ArticlesWidgetPreviewFactory.placeholder(
            language: .turkish,
            views: 54210,
            shares: 1400,
            color: .systemGreen
        )
    )
}

@available(iOS 17, *)
#Preview("Large • Long Excerpt", as: .systemLarge) {
    ArticlesWidget()
} timeline: {
    ArticlesWidgetPreviewFactory.entry(
        ArticlesWidgetPreviewFactory.placeholder(
            language: .english,
            views: 7340,
            shares: 185,
            color: .systemBlue
        )
    )
}
#endif

private extension Article {
    func withAnalytics(views: Int, shares: Int) -> Article {
        var article = self
        article.views = views
        article.shares = shares
        return article
    }
}
