import UIKit
import SwiftUI
import Library
import ArticleReader
import Entities
import PDFKit

extension RootCoordinator {

    func makeArticleView(_ article: Article) -> some View {
        return ArticleScreen(
            viewModel: ArticleViewModel(
                article: article,
                analyticsStream: { [unowned self] in
                    guard let articlesService = self.articlesService else {
                        return .never
                    }
                    return await articlesService.observeAnalyticsNumbers(articleId: article.id)
                },
                updateAnalytics: { [unowned self] (numbers: ArticleAnalytics) in
                    self.articlesService?
                        .updateAnalyticsNumbers(
                            for: article.id,
                            views: numbers.viewsCount,
                            shares: numbers.sharesCount
                        )
                },
                fetchArticle: { [unowned self] in
                    try? await self.articlesService?.getArticle(article.id, updatedAfter: article.updatedAt)
                }
            ),
            onShareButtonTap: { [unowned self] in
                self.shareArticle(article)
            }
        )
    }

    private func shareArticle(_ article: Article) {
        assert(Thread.isMainThread)
        guard
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = scene.windows.first,
            let rootViewController = window.rootViewController?.topmostPresentedViewController
        else {
            return
        }

        let composer = ArticlePDFComposer(
            article: article,
            titleFont: UIFont(name: self.preferences.preferredTranslationFont.postscriptName, size: 45)!,
            textFont: UIFont(name: self.preferences.preferredTranslationFont.postscriptName, size: 25)!,
            pageMargins: UIEdgeInsets(horizontal: 75, vertical: 65),
            footer: ArticlePDFComposer.Footer(
                image: UIImage(named: "ink-icon", in: resourcesBunbdle, compatibleWith: nil),
                text: L10n.Share.sharedWithAzkar.uppercased(),
                link: URL(string: "https://apple.co/41O1pzQ")
            )
        )

        let fileName = "\(article.title).pdf"
        let tempFilePath = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            let data = try composer.renderPDF()
            try? FileManager.default.removeItem(at: tempFilePath)
            try data.write(to: tempFilePath)
        } catch {
            return
        }

        let view = ArticlePDFCoverView(
            article: article,
            maxHeight: 842,
            logoImage: UIImage(named: "ink-icon", in: resourcesBunbdle, compatibleWith: nil),
            logoSubtitle: L10n.Share.sharedWithAzkar
        )
        .frame(width: 595, height: 842)
        .environment(\.colorScheme, .light)
        .background(Color.white)

        let viewController = UIHostingController(rootView: view)
        let image = viewController.snapshot()

        guard
            image.size != .zero,
            let pdfDocument = PDFDocument(url: tempFilePath),
            let pdfPage = PDFPage(image: image)
        else {
            return
        }
        pdfDocument.insert(pdfPage, at: 0)
        guard let data = pdfDocument.dataRepresentation() else {
            return
        }
        do {
            try? FileManager.default.removeItem(at: tempFilePath)
            try data.write(to: tempFilePath)
        } catch {
            return
        }

        let activityController = UIActivityViewController(
            activityItems: [tempFilePath],
            applicationActivities: [ZikrFeedbackActivity(prepareAction: { [unowned self] in
                self.presentMailComposer(from: rootViewController)
            })]
        )
        activityController.excludedActivityTypes = [
            .init(rawValue: "com.apple.reminders.sharingextension")
        ]
        activityController.completionWithItemsHandler = { [unowned self] (_, completed, _, _) in
            viewController.dismiss()
            if completed {
                self.articlesService?.sendAnalyticsEvent(.share, articleId: article.id)
            }
        }
        rootViewController.present(activityController, animated: true)
    }
}
