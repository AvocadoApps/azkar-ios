//
//  AppDelegate.swift
//  Azkar
//
//  Created by Al Jawziyya on 06.04.2020.
//  Copyright © 2020 Al Jawziyya. All rights reserved.
//

import UIKit
import AudioPlayer
import UserNotifications
import SwiftUI
import RevenueCat
import Entities
import Library
import FirebaseCore
import FirebaseMessaging

import Mixpanel
import CoreSpotlight

private let quickActionTypePrefix = "io.jawziyya.azkar-app.quick-action."

@MainActor
@discardableResult
private func dispatchQuickActionItem(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
    let type = shortcutItem.type
    guard type.hasPrefix(quickActionTypePrefix) else { return false }
    let categoryRawValue = String(type.dropFirst(quickActionTypePrefix.count))
    guard let category = ZikrCategory(rawValue: categoryRawValue) else { return false }
    QuickActionDispatcher.shared.enqueue(.azkar(category))
    return true
}

@MainActor
final class AppDelegate: UIResponder, UIApplicationDelegate {

    let player = AudioPlayer()
    let notificationsHandler = NotificationsHandler.shared
    private let spotlightIndexer = SpotlightIndexer.shared

    private func buildShortcutItems() -> [UIApplicationShortcutItem] {
        ZikrCategory.allCases.map { category in
            UIApplicationShortcutItem(
                type: quickActionTypePrefix + category.rawValue,
                localizedTitle: category.title,
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: category.systemImageName)
            )
        }
    }

    @discardableResult
    fileprivate func handleQuickActionItem(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        dispatchQuickActionItem(shortcutItem)
    }
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        if CommandLine.arguments.contains("DISABLE_ANIMATIONS") {
            DispatchQueue.main.async {
                UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap(\.windows)
                    .forEach { $0.layer.speed = 100 }
            }
        }
        application.beginReceivingRemoteControlEvents()
        application.registerForRemoteNotifications()
        application.shortcutItems = buildShortcutItems()
        initialize(launchOptions: launchOptions)
        spotlightIndexer.indexIfNeeded()
        if let launchOptions, let userInfo = launchOptions[.remoteNotification] as? [AnyHashable: Any] {
            notificationsHandler.handleLaunchNotification(userInfo)
        }
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        if let shortcutItem = options.shortcutItem {
            dispatchQuickActionItem(shortcutItem)
        }
        return UISceneConfiguration(
            name: nil,
            sessionRole: connectingSceneSession.role
        )
    }

    func application(
        _ application: UIApplication,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(handleQuickActionItem(shortcutItem))
    }

    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        return false
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        notificationsHandler.handlePushNotificationToken(deviceToken)
    }

    private func initialize(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        FontsHelper.registerFonts()

        notificationsHandler.removeDeliveredNotifications()

        notificationsHandler
            .getNotificationsAuthorizationStatus(completion: { status in
                switch status {
                case .notDetermined:
                    NotificationsHandler.shared.requestNotificationsPermission { _ in }
                default:
                    break
                }
            })

        registerUserDefaults()
        migrateSharedPreferencesIfNeeded()
        ensureValidTransliterationPreference()
        setupRevenueCat()
        SubscriptionManager.shared.observeSubscriptionStatus()
        setupFirebase()
        setupMixpanel(launchOptions: launchOptions)
    }
        
    override func remoteControlReceived(with event: UIEvent?) {
        guard let event else {
            return
        }

        switch event.subtype {
        case .remoteControlPlay, .remoteControlStop, .remoteControlPause, .remoteControlTogglePlayPause:
            player.remoteControlReceived(with: event)

        default:
            return
        }
    }

    private func registerUserDefaults() {
        let defaults: [String: Any] = [
            Keys.expandTranslation: true,
            Keys.expandTransliteration: false,
            Keys.showTashkeel: true,
            
            Keys.enableGoToNextZikrOnCounterFinished: true,
            Keys.counterPosition: CounterPosition.left.rawValue,
            
            Keys.enableReminders: true,
            Keys.morningNotificationsTime: defaultMorningNotificationTime,
            Keys.eveningNotificationsTime: defaultEveningNotificationTime,
            
            Keys.appIcon: AppIcon.gold.rawValue,
            
            Keys.useSystemFontSize: true,
            Keys.sizeCategory: ContentSizeCategory.medium.floatValue,
            Keys.lineSpacing: LineSpacing.s.rawValue,
            Keys.translationLineSpacing: LineSpacing.s.rawValue,
            
            Keys.zikrReadingMode: ZikrReadingMode.normal.rawValue,
            Keys.zikrCollectionSource: ZikrCollectionSource.hisnulMuslim.rawValue,
        ]

        UserDefaults.standard.register(defaults: defaults)
    }

    private func migrateSharedPreferencesIfNeeded() {
        migrateDataPreferenceIfNeeded(Keys.zikrCollectionSource)
    }

    private func migrateDataPreferenceIfNeeded(_ key: String) {
        guard UserDefaults.appGroup.object(forKey: key) == nil else {
            return
        }

        guard let value = UserDefaults.standard.object(forKey: key) as? Data else {
            return
        }

        UserDefaults.appGroup.set(value, forKey: key)
    }
    
    private func setupRevenueCat() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: readSecret(AzkarSecretKey.REVENUE_CAT_API_KEY)!)
    }
    
    private func setupFirebase() {
        FirebaseApp.configure()
        Messaging.messaging().delegate = notificationsHandler
        AnalyticsReporter.addTarget(FirebaseAnalyticsTarget.shared)
        AnalyticsReporter.addTarget(MixpanelAnalyticsTarget.shared)
    }

    private func setupMixpanel(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        Mixpanel.initialize(
            token: readSecret(AzkarSecretKey.MIXPANEL_TOKEN)!,
            trackAutomaticEvents: false
        )
        Mixpanel.mainInstance().loggingEnabled = true
    }
    
    private func ensureValidTransliterationPreference() {
        let preferences = Preferences.shared
        let availableTypes: [ZikrTransliterationType]
        switch preferences.contentLanguage {
        case .arabic, .english, .georgian, .turkish:
            availableTypes = [.DIN31635]
        case .russian, .chechen:
            availableTypes = [.community, .ruScientific, .DIN31635]
        case .ingush, .kazakh, .kyrgyz, .uzbek, .tatar:
            availableTypes = [.ruScientific, .DIN31635]
        }
        
        if availableTypes.contains(preferences.transliterationType) == false {
            preferences.transliterationType = availableTypes.first ?? .community
        }
    }
    
}

