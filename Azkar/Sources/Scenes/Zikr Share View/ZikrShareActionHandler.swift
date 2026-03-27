import SwiftUI
import UIKit
import Library
import Entities

final class ZikrShareActionHandler {

    private let preferences: Preferences
    private let player: Player
    private let mailPresenter = FeedbackMailPresenter()

    init(preferences: Preferences, player: Player) {
        self.preferences = preferences
        self.player = player
    }

    func handle(_ options: ZikrShareOptionsView.ShareOptions, for zikr: Zikr) {
        if options.containsProItem, SubscriptionManager.shared.isProUser() == false {
            SubscriptionManager.shared.presentPaywall(
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

        let view = ZikrShareView(
            viewModel: viewModel,
            includeTitle: options.includeTitle,
            includeOriginalText: options.includeOriginalText,
            includeTranslation: options.includeTranslation,
            includeTransliteration: options.includeTransliteration,
            includeBenefits: options.includeBenefits,
            includeLogo: options.includeLogo,
            includeSource: false,
            arabicTextAlignment: options.textAlignment.isCentered ? .center : .trailing,
            otherTextAlignment: options.textAlignment.isCentered ? .center : .leading,
            nestIntoScrollView: false,
            useFullScreen: options.shareType != .text,
            selectedBackground: options.selectedBackground,
            enableLineBreaks: options.enableLineBreaks
        )
        .environment(\.arabicFont, options.arabicFont)
        .environment(\.translationFont, options.translationFont)
        .frame(width: min(440, UIScreen.main.bounds.width))

        let image = view.snapshot()

        if options.actionType == .saveImage {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
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
