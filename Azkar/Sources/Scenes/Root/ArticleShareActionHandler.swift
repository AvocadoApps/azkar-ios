import UIKit
import SwiftUI
import Library
import ArticleReader
import Entities
import AzkarServices
import PDFKit
import FactoryKit

final class ArticleShareActionHandler {

    @Injected(\.appDependencies) private var dependencies: AppDependencies
    private let mailPresenter = FeedbackMailPresenter()

    func share(_ article: Article) {
        assert(Thread.isMainThread)
        guard let rootViewController = topViewController() else {
            return
        }

        let preferences = dependencies.preferences
        let articlesService = dependencies.articlesService

        let composer = ArticlePDFComposer(
            article: article,
            titleFont: UIFont(name: preferences.preferredTranslationFont.postscriptName, size: 45)!,
            textFont: UIFont(name: preferences.preferredTranslationFont.postscriptName, size: 25)!,
            pageMargins: UIEdgeInsets(top: 65, left: 75, bottom: 65, right: 75),
            footer: ArticlePDFComposer.Footer(
                image: UIImage(named: "ink-icon", in: resourcesBundle, compatibleWith: nil),
                text: String(localized: "share.shared-with-azkar").uppercased(),
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
            logoImage: UIImage(named: "ink-icon", in: resourcesBundle, compatibleWith: nil),
            logoSubtitle: String(localized: "share.shared-with-azkar")
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
            applicationActivities: [ZikrFeedbackActivity(prepareAction: {
                self.mailPresenter.present(from: rootViewController)
            })]
        )
        activityController.excludedActivityTypes = [
            .init(rawValue: "com.apple.reminders.sharingextension")
        ]
        activityController.completionWithItemsHandler = { [articlesService] _, completed, _, _ in
            viewController.dismiss(animated: true)
            if completed {
                articlesService.sendAnalyticsEvent(.share, articleId: article.id)
            }
        }
        rootViewController.present(activityController, animated: true)
    }
}

private extension ArticleShareActionHandler {

    func topViewController() -> UIViewController? {
        guard
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = scene.windows.first
        else {
            return nil
        }

        return window.rootViewController?.topmostPresentedViewController
    }
}
