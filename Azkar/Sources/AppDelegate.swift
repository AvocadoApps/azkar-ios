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
import SuperwallKit
import Mixpanel
import CoreSpotlight

@MainActor
final class AppDelegate: UIResponder, UIApplicationDelegate {

    let player = AudioPlayer()
    let notificationsHandler = NotificationsHandler.shared
    private let spotlightIndexer = SpotlightIndexer.shared
    
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
        initialize(launchOptions: launchOptions)
        spotlightIndexer.indexIfNeeded()
        if let launchOptions, let userInfo = launchOptions[.remoteNotification] as? [AnyHashable: Any] {
            notificationsHandler.handleLaunchNotification(userInfo)
        }
        return true
    }

    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        if
            userActivity.activityType == CSSearchableItemActionType,
            let searchableIdentifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
            let deepLink = AppDeepLink(searchableIdentifier: searchableIdentifier)
        {
            Deeplinker.shared.route = deepLink.route
            return true
        }

        if
            let url = userActivity.webpageURL,
            let deepLink = AppDeepLink(url: url)
        {
            Deeplinker.shared.route = deepLink.route
            return true
        }

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
        ensureValidTransliterationPreference()
        setupRevenueCat()
        setupFirebase()
        setupSuperwall()
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
    
    private func setupSuperwall() {
        let options = SuperwallOptions()
        options.paywalls.shouldPreload = true
        let purchaseController = SubscriptionManager.shared
        Superwall.configure(
            apiKey: readSecret(AzkarSecretKey.SUPERWALL_API_KEY)!,
            purchaseController: purchaseController,
            options: options
        )
        purchaseController.syncSubscriptionStatus()
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
