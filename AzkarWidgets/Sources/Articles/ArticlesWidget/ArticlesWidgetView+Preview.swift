import SwiftUI
import WidgetKit
import Entities
import UIKit

#if DEBUG
private enum ArticlesWidgetPreviewFactory {
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
            imageData: makeImageData(color: article.color)
        )
    }

    static let meaningOfDhikr = MockArticle(
        title: "Что означает «Поминание Аллаха»?",
        text: "Поистине, поминание Аллаха Всевышнего — это жизнь и спокойствие сердец, умиротворение и отдых души, это то, что оживляет души и это основа самой жизни. Нет ни успокоения, ни избавления от горечи, кроме как посредством поминания Аллаха.",
        language: .russian,
        color: .systemTeal,
        views: 18420,
        shares: 910
    )

    static let supplicationRemedy = MockArticle(
        title: "Мольба — лекарство",
        text: "Мольба относится к наиболее полезным лекарствам. Она является врагом бедствия, отталкивая его и становясь лекарством от него. Она препятствует его приходу и избавляет от него или же облегчает его, если оно всё-таки постигает человека.",
        language: .russian,
        color: .systemOrange,
        views: 12840,
        shares: 320
    )

    static let ranksOfDhikr = MockArticle(
        title: "Степени поминания Аллаха Всевышнего",
        text: "- Высшей степенью зикра является поминание Аллаха сердцем, которое сопровождается произношением на языке и делами тела.\n- За ним следует поминание в сердце, совмещённое с делами тела.\n- За этим следует поминание сердцем вместе с произнесением на языке.",
        language: .russian,
        color: .systemBlue,
        views: 9630,
        shares: 250
    )

    static let fortressOfDhikr = MockArticle(
        title: "Крепость поминания",
        text: "Слова Пророка ﷺ: «Я повелеваю вам поминать Аллаха, Свят Он и Велик. Поистине, это подобно человеку, за которым очень быстро гонятся его враги, и этот человек приходит к защищённой крепости и находит там для себя убежище».",
        language: .russian,
        color: .systemGreen,
        views: 54210,
        shares: 1400
    )

    static let tenBestNights = MockArticle(
        title: "10 лучших ночей",
        text: "Начинаются 10 последних ночей Рамадана, одна из которых — ночь Предопределения, о которой Всевышний Аллах сказал в Коране: «Ночь Предопределения лучше тысячи месяцев». То есть поклонение Аллаху в эту ночь лучше, чем поклонение в течение 1000 месяцев.",
        language: .russian,
        color: .systemPurple,
        views: 980,
        shares: 42
    )

    static let supplicationIsRemedy = MockArticle(
        title: "Supplication Is a Remedy",
        text: "Supplication (du‘a) is among the most beneficial remedies. It is an enemy of affliction: it repels it, serves as a cure for it, prevents its arrival, removes it, or lessens its impact if it does befall a person.",
        language: .english,
        color: .systemIndigo,
        views: 7340,
        shares: 185
    )

    static func mockArticle(
        title: String,
        text: String,
        language: Language = .english,
        views: Int = 0,
        shares: Int = 0,
        color: UIColor
    ) -> MockArticle {
        MockArticle(
            title: title,
            text: text,
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
}

@available(iOS 17, *)
#Preview("Small • Short Title", as: .systemSmall) {
    ArticlesWidget()
} timeline: {
    ArticlesWidgetPreviewFactory.entry(ArticlesWidgetPreviewFactory.supplicationRemedy)
}

@available(iOS 17, *)
#Preview("Small • Long Title", as: .systemSmall) {
    ArticlesWidget()
} timeline: {
    ArticlesWidgetPreviewFactory.entry(ArticlesWidgetPreviewFactory.ranksOfDhikr)
}

@available(iOS 17, *)
#Preview("Medium • Stats", as: .systemMedium) {
    ArticlesWidget()
} timeline: {
    ArticlesWidgetPreviewFactory.entry(ArticlesWidgetPreviewFactory.meaningOfDhikr)
}

@available(iOS 17, *)
#Preview("Medium • No Stats", as: .systemMedium) {
    ArticlesWidget()
} timeline: {
    ArticlesWidgetPreviewFactory.entry(
        ArticlesWidgetPreviewFactory.mockArticle(
            title: "Мольбы праведных",
            text: "Отсутствие самого дуа — страшнее отсутствия ответа на него.",
            language: .russian,
            color: .systemBlue
        )
    )
}

@available(iOS 17, *)
#Preview("Large • Full Content", as: .systemLarge) {
    ArticlesWidget()
} timeline: {
    ArticlesWidgetPreviewFactory.entry(ArticlesWidgetPreviewFactory.fortressOfDhikr)
}

@available(iOS 17, *)
#Preview("Large • Long Excerpt", as: .systemLarge) {
    ArticlesWidget()
} timeline: {
    ArticlesWidgetPreviewFactory.entry(ArticlesWidgetPreviewFactory.supplicationIsRemedy)
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
