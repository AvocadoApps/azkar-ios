// Copyright © 2023 Azkar
// All Rights Reserved.

import SwiftUI
import Library
import Entities
import AudioPlayer
import Stinsen
import StoreKit
import CoreSpotlight

@main
struct AzkarApp: App {
    
    @UIApplicationDelegateAdaptor var delegate: AppDelegate
    
    let preferences = Preferences.shared
    let deepLinker = Deeplinker.shared
    
    init() {
        setNavigationBarFont(theme: preferences.appTheme, colorTheme: preferences.colorTheme)
    }
        
    var body: some Scene {
        WindowGroup {
            NavigationViewCoordinator(
                RootCoordinator(
                    preferences: Preferences.shared,
                    deeplinker: deepLinker,
                    player: Player(player: AudioPlayer())
                )
            )
            .view()
            .task { await presentPaywall() }
            .connectAppTheme()
            .connectCustomFonts()
            .attachEnvironmentOverrides(onChange: { _ in
                setNavigationBarFont(theme: preferences.appTheme, colorTheme: preferences.colorTheme)
            })
            .onReceive(preferences.$appTheme) { newTheme in
                setNavigationBarFont(theme: newTheme, colorTheme: preferences.colorTheme)
            }
            .onReceive(preferences.$colorTheme) { colorTheme in
                setNavigationBarFont(theme: preferences.appTheme, colorTheme: colorTheme)
            }
            .onReceive(preferences.$theme) { theme in
                let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                let window = scene?.keyWindow
                window?.overrideUserInterfaceStyle = theme.userInterfaceStyle
            }
            .onReceive(delegate.notificationsHandler.selectedNotificationCategory) { notificationCategory in
                guard let notificationCategory else { return }
                let category: ZikrCategory
                switch notificationCategory {
                case .morning: category = .morning
                case .evening: category = .evening
                case .jumua: category = .hundredDua
                }
                self.deepLinker.route = .azkar(category)
            }
            .onOpenURL { url in
                handleIncomingURL(url)
            }
            .onContinueUserActivity(CSSearchableItemActionType) { userActivity in
                handleSearchActivity(userActivity)
            }
        }
    }

    private func handleIncomingURL(_ url: URL) {
        guard let deepLink = AppDeepLink(url: url) else {
            return
        }
        deepLinker.route = deepLink.route
    }

    private func handleSearchActivity(_ userActivity: NSUserActivity) {
        guard
            let searchableIdentifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
            let deepLink = AppDeepLink(searchableIdentifier: searchableIdentifier)
        else {
            return
        }
        deepLinker.route = deepLink.route
    }
    
    private func getColor(_ type: ColorType, theme: ColorTheme) -> Color {
        return Color.getColor(type.rawValue, theme: theme)
    }
    
    private func setNavigationBarFont(theme: AppTheme, colorTheme: ColorTheme) {
        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithOpaqueBackground()
        
        let scrollEdgeAppearance = UINavigationBarAppearance()
        scrollEdgeAppearance.configureWithTransparentBackground()
                
        let fontDesign: UIFontDescriptor.SystemDesign
        switch theme.fontDesign {
        case .monospaced: fontDesign = .monospaced
        case .rounded: fontDesign = .rounded
        case .serif: fontDesign = .serif
        default: fontDesign = .default
        }
        
        let largeTitleTextAttributes: [NSAttributedString.Key: Any] = [
            .font: getFont(customName: theme.font, style: .largeTitle, design: fontDesign),
            .foregroundColor: UIColor(getColor(.text, theme: colorTheme))
        ]
        let titleTextAttributes: [NSAttributedString.Key: Any] = [
            .font: getFont(customName: theme.font, style: .title3, design: fontDesign),
            .foregroundColor: UIColor(getColor(.text, theme: colorTheme))
        ]
        
        standardAppearance.titleTextAttributes = titleTextAttributes
        standardAppearance.largeTitleTextAttributes = largeTitleTextAttributes
        standardAppearance.backgroundColor = UIColor(getColor(.background, theme: colorTheme))
        
        scrollEdgeAppearance.titleTextAttributes = titleTextAttributes
        scrollEdgeAppearance.largeTitleTextAttributes = largeTitleTextAttributes
        if #unavailable(iOS 26) {
            scrollEdgeAppearance.backgroundColor = UIColor(getColor(.background, theme: colorTheme))
        }

        UINavigationBar.appearance().standardAppearance = standardAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = scrollEdgeAppearance
        UINavigationBar.appearance().tintColor = UIColor(getColor(.text, theme: colorTheme))

        // Apply appearance to all existing navigation controllers
        if let scenes = UIApplication.shared.connectedScenes as? Set<UIWindowScene> {
            scenes.forEach { scene in
                scene.windows.forEach { window in
                    var navigationControllers: [UINavigationController] = []
                    if let navigationController = window.rootViewController as? UINavigationController {
                        navigationControllers.append(navigationController)
                    }
                    let childControllers = window.rootViewController?.allChildViewControllers.compactMap { $0 as? UINavigationController }
                    navigationControllers.append(contentsOf: childControllers ?? [])
                    for navigationController in navigationControllers {
                        navigationController.navigationBar.standardAppearance = standardAppearance
                        navigationController.navigationBar.scrollEdgeAppearance = scrollEdgeAppearance
                        navigationController.navigationBar.tintColor = UIColor(getColor(.text, theme: colorTheme))
                    }
                }
            }
        }
    }
    
    private func setNavigationControllerAppearance(
        navigationController: UINavigationController,
        standardAppearance: UINavigationBarAppearance,
        scrollEdgeAppearance: UINavigationBarAppearance,
        tintColor: UIColor
    ) {
        navigationController.navigationBar.standardAppearance = standardAppearance
        navigationController.navigationBar.scrollEdgeAppearance = scrollEdgeAppearance
        navigationController.navigationBar.tintColor = tintColor
    }

    private func getFont(customName: String?, style: UIFont.TextStyle, design: UIFontDescriptor.SystemDesign) -> UIFont {
        let systemFont = UIFont.preferredFont(forTextStyle: style)
        let font: UIFont
        if let descriptor = systemFont.fontDescriptor.withDesign(design) {
            let size = min(30, descriptor.pointSize)
            if let customName {
                font = UIFont(name: customName, size: size) ?? UIFont(descriptor: descriptor, size: size)
            } else {
                font = UIFont(descriptor: descriptor, size: systemFont.pointSize)
            }
        } else {
            font = systemFont
        }
        return font
    }
    
    private func requestAppReview() {
        #if !DEBUG
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if let windowScene = UIApplication.shared.connectedScenes.first?.session.scene as? UIWindowScene {
                SKStoreReviewController.requestReview(in: windowScene)
            }
        }
        #endif
    }
    
    private func presentPaywall() async {
        guard SubscriptionManager.shared.isProUser() == false && CommandLine.arguments.contains("DISABLE_LAUNCH_PAYWALL") == false else {
            return
        }
        SubscriptionManager.shared.presentPaywall(
            presentationType: .appLaunch,
            completion: {
                requestAppReview()
            }
        )
    }
    
}

// Extension to get all child view controllers recursively
extension UIViewController {
    var allChildViewControllers: [UIViewController] {
        var all = [self]
        for child in children {
            all.append(contentsOf: child.allChildViewControllers)
        }
        return all
    }
}
