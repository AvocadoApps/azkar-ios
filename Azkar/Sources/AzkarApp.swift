// Copyright © 2023 Azkar
// All Rights Reserved.

import SwiftUI
import FactoryKit
import Library
import Entities
import StoreKit
import CoreSpotlight
import Combine

@MainActor
@main
struct AzkarApp: App {

    private static var hasHandledLaunchPaywall = false

    @UIApplicationDelegateAdaptor var delegate: AppDelegate

    @Injected(\.preferences) private var preferences: Preferences
    @Injected(\.deeplinker) private var deepLinker: Deeplinker
    @Injected(\.quickActionDispatcher) private var quickActionDispatcher: QuickActionDispatcher
    @Injected(\.subscriptionManager) private var subscriptionManager: SubscriptionManagerType

    init() {
        setNavigationBarFont(theme: preferences.appTheme, colorTheme: preferences.colorTheme)
        applyWindowBackground(colorTheme: preferences.colorTheme)
    }

    var body: some Scene {
        WindowGroup {
            AppFlowView()
            .task { await presentPaywall() }
            .connectAppTheme()
            .connectCustomFonts()
            .attachEnvironmentOverrides(onChange: { _ in
                setNavigationBarFont(theme: preferences.appTheme, colorTheme: preferences.colorTheme)
                applyWindowBackground(colorTheme: preferences.colorTheme)
            })
            .onReceive(preferences.$appTheme) { newTheme in
                setNavigationBarFont(theme: newTheme, colorTheme: preferences.colorTheme)
                applyWindowBackground(colorTheme: preferences.colorTheme)
            }
            .onReceive(preferences.$colorTheme) { colorTheme in
                setNavigationBarFont(theme: preferences.appTheme, colorTheme: colorTheme)
                applyWindowBackground(colorTheme: colorTheme)
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
                self.deepLinker.open(.azkar(category))
            }
            .onReceive(quickActionDispatcher.routes) { route in
                deepLinker.open(route)
            }
            .onOpenURL { url in
                handleIncomingURL(url)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                handlePendingQuickAction()
                handleControlCenterDeepLink()
            }
            .onContinueUserActivity(CSSearchableItemActionType) { userActivity in
                handleSearchActivity(userActivity)
            }
        }
    }

    private func handleControlCenterDeepLink() {
        let defaults = UserDefaults(suiteName: "group.io.jawziyya.azkar-app")
        guard let urlString = defaults?.string(forKey: "controlCenterDeepLink"),
              let url = URL(string: urlString)
        else {
            return
        }
        defaults?.removeObject(forKey: "controlCenterDeepLink")
        handleIncomingURL(url)
    }

    private func handlePendingQuickAction() {
        guard let route = quickActionDispatcher.takePendingRoute() else {
            return
        }
        deepLinker.open(route)
    }

    private func handleIncomingURL(_ url: URL) {
        guard let deepLink = AppDeepLink(url: url) else {
            return
        }
        deepLinker.open(deepLink.route)
    }

    private func handleSearchActivity(_ userActivity: NSUserActivity) {
        guard
            let searchableIdentifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
            let deepLink = AppDeepLink(searchableIdentifier: searchableIdentifier)
        else {
            return
        }
        deepLinker.open(deepLink.route)
    }
    
    private func getColor(_ type: ColorType, theme: ColorTheme) -> Color {
        return Color.getColor(type.rawValue, theme: theme)
    }

    private func applyWindowBackground(colorTheme: ColorTheme) {
        let backgroundColor = UIColor(getColor(.background, theme: colorTheme))

        guard let scenes = UIApplication.shared.connectedScenes as? Set<UIWindowScene> else {
            return
        }

        scenes.forEach { scene in
            scene.windows.forEach { window in
                window.backgroundColor = backgroundColor
            }
        }
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
        guard Self.hasHandledLaunchPaywall == false else {
            return
        }
        Self.hasHandledLaunchPaywall = true

        if preferences.hasCompletedFirstLaunch == false {
            preferences.hasCompletedFirstLaunch = true
            return
        }

        guard subscriptionManager.isProUser() == false && CommandLine.arguments.contains("DISABLE_LAUNCH_PAYWALL") == false else {
            return
        }
        subscriptionManager.presentPaywall(
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
