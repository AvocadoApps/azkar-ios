// Copyright © 2023 Al Jawziyya. All rights reserved.

import SwiftUI
import Stinsen
import UIKit
import Nuke
import MessageUI
import Library

final class ZikrShareCoordinator: NavigationCoordinatable {
    var stack: Stinsen.NavigationStack<ZikrShareCoordinator> = .init(initial: \.options)
    
    @Root var options = makeOptionsView
    
    let zikr: Zikr
    let preferences: Preferences
    let player: Player
    let backgroundsService: ShareBackgroundsServiceType

    init(zikr: Zikr, preferences: Preferences, player: Player) {
        self.zikr = zikr
        self.preferences = preferences
        self.player = player
        self.backgroundsService = ShareBackgroundsServiceProvider.createShareBackgroundsService()
    }
    
    func makeOptionsView() -> some View {
        ZikrShareOptionsView(zikr: zikr) { [weak self] options in
            guard let self = self else { return }
            self.share(using: options)
        }
        .environmentObject(backgroundsService)
    }
    
    private func share(using options: ZikrShareOptionsView.ShareOptions) {
        if options.containsProItem, SubscriptionManager.shared.isProUser() == false {
            SubscriptionManager.shared.presentPaywall(presentationType: .screen(ZikrShareOptionsView.viewName), completion: nil)
            return
        }
        
        if options.shareType == .text {
            shareText(options: options)
        } else {
            shareImage(options: options)
        }
    }

    private func shareText(options: ZikrShareOptionsView.ShareOptions) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first,
              let rootViewController = window.rootViewController?.topmostPresentedViewController else {
            return
        }
        
        let viewModel = ZikrViewModel(zikr: zikr, isNested: true, hadith: nil, preferences: preferences, player: player)
        
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
                    self.presentMailComposer(from: rootViewController)
                })]
            )
            
            activityController.excludedActivityTypes = [
                .init(rawValue: "com.apple.reminders.sharingextension")
            ]
            
            rootViewController.present(activityController, animated: true)
        }
    }
    
    private func shareImage(options: ZikrShareOptionsView.ShareOptions) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first,
              let rootViewController = window.rootViewController?.topmostPresentedViewController else {
            return
        }
        
        let viewModel = ZikrViewModel(zikr: zikr, isNested: true, hadith: nil, preferences: preferences, player: player)

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
        } else if options.actionType == .sheet {
            let tempDir = FileManager.default.temporaryDirectory
            let title = viewModel.title ?? viewModel.zikr.id.description
            let imgFileName = "\(title).png".normalizeForPath()
            let tempImagePath = tempDir.appendingPathComponent(imgFileName)
            try? image.pngData()?.write(to: tempImagePath)
            
            let activityController = UIActivityViewController(
                activityItems: [tempImagePath],
                applicationActivities: [ZikrFeedbackActivity(prepareAction: {
                    self.presentMailComposer(from: rootViewController)
                })]
            )
            
            activityController.excludedActivityTypes = [
                .init(rawValue: "com.apple.reminders.sharingextension")
            ]
            
            rootViewController.present(activityController, animated: true)
        }
    }
    
    private func presentMailComposer(from viewController: UIViewController) {
        guard MFMailComposeViewController.canSendMail() else {
            UIApplication.shared.open(URL(string: "https://t.me/jawziyya_feedback")!)
            return
        }
        
        let mailComposerViewController = MFMailComposeViewController()
        mailComposerViewController.setToRecipients(["azkar.app@pm.me"])
        mailComposerViewController.mailComposeDelegate = viewController as? MFMailComposeViewControllerDelegate
        viewController.present(mailComposerViewController, animated: true)
    }
}
