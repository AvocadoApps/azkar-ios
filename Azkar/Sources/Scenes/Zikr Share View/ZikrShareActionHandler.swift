import SwiftUI
import UIKit
import Library
import Entities
import FactoryKit

final class ZikrShareActionHandler {

    @Injected(\.preferences) private var preferences: Preferences
    @Injected(\.player) private var player: Player
    @Injected(\.subscriptionManager) private var subscriptionManager: SubscriptionManagerType
    @Injected(\.localAnalytics) private var analytics: AppAnalyticsTracking
    private let mailPresenter = FeedbackMailPresenter()
    func handle(_ options: ZikrShareOptionsView.ShareOptions, for zikr: Zikr) {
        if options.containsProItem, subscriptionManager.isProUser() == false {
            subscriptionManager.presentPaywall(
                presentationType: .screen(ZikrShareOptionsView.viewName),
                completion: nil
            )
            return
        }

        if options.shareType == .text {
            shareText(options: options, zikr: zikr)
        } else {
            shareImage(options: options, zikr: zikr)
        }
    }
}

private extension ZikrShareActionHandler {

    func shareText(options: ZikrShareOptionsView.ShareOptions, zikr: Zikr) {
        guard let rootViewController = topViewController() else {
            return
        }

        let viewModel = ZikrViewModel(
            zikr: zikr,
            isNested: true,
            hadith: nil,
            preferences: preferences,
            player: player
        )

        let text = viewModel.getShareText(
            includeTitle: options.includeTitle,
            includeTranslation: options.includeTranslation,
            includeTransliteration: options.includeTransliteration,
            includeBenefits: options.includeBenefits,
            enableLineBreaks: options.enableLineBreaks
        )

        if options.actionType == .copyText {
            UIPasteboard.general.string = text
            analytics.sharing.sharedZikr(id: zikr.id, shareType: .text, action: .copy)
        } else if options.actionType == .sheet {
            let activityController = UIActivityViewController(
                activityItems: [text],
                applicationActivities: [ZikrFeedbackActivity(prepareAction: {
                    self.mailPresenter.present(from: rootViewController)
                })]
            )

            activityController.excludedActivityTypes = [
                .init(rawValue: "com.apple.reminders.sharingextension")
            ]

            activityController.completionWithItemsHandler = { _, completed, _, _ in
                guard completed else {
                    return
                }
                self.analytics.sharing.sharedZikr(id: zikr.id, shareType: .text, action: .sheet)
            }

            rootViewController.present(activityController, animated: true)
        }
    }

    func shareImage(options: ZikrShareOptionsView.ShareOptions, zikr: Zikr) {
        guard let rootViewController = topViewController() else {
            return
        }

        let viewModel = ZikrViewModel(
            zikr: zikr,
            isNested: true,
            hadith: nil,
            preferences: preferences,
            player: player
        )

        let renderer = ZikrShareImageRenderer()
        let image = renderer.render(ZikrShareImageRenderer.Options(
            viewModel: viewModel,
            includeTitle: options.includeTitle,
            includeOriginalText: options.includeOriginalText,
            includeTranslation: options.includeTranslation,
            includeTransliteration: options.includeTransliteration,
            includeBenefits: options.includeBenefits,
            includeLogo: options.includeLogo,
            textAlignment: options.textAlignment,
            useFullScreen: options.shareType != .text,
            selectedBackground: options.selectedBackground,
            enableLineBreaks: options.enableLineBreaks,
            arabicFont: options.arabicFont,
            translationFont: options.translationFont
        ))

        if options.actionType == .saveImage {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            analytics.sharing.sharedZikr(id: zikr.id, shareType: .image, action: .save)
            return
        }

        guard options.actionType == .sheet else {
            return
        }

        let tempDir = FileManager.default.temporaryDirectory
        let title = viewModel.title ?? viewModel.zikr.id.description
        let imgFileName = "\(title).png".normalizeForPath()
        let tempImagePath = tempDir.appendingPathComponent(imgFileName)
        try? image.pngData()?.write(to: tempImagePath)

        let activityController = UIActivityViewController(
            activityItems: [tempImagePath],
            applicationActivities: [ZikrFeedbackActivity(prepareAction: {
                self.mailPresenter.present(from: rootViewController)
            })]
        )

        activityController.excludedActivityTypes = [
            .init(rawValue: "com.apple.reminders.sharingextension")
        ]

        activityController.completionWithItemsHandler = { _, completed, _, _ in
            guard completed else {
                return
            }
            self.analytics.sharing.sharedZikr(id: zikr.id, shareType: .image, action: .sheet)
        }

        rootViewController.present(activityController, animated: true)
    }

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
