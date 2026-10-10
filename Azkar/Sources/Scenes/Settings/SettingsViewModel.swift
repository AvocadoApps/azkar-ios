//
//  SettingsViewModel.swift
//  Azkar
//
//  Created by Abdurahim Jauzee on 04.05.2020.
//  Copyright © 2020 Al Jawziyya. All rights reserved.
//

import SwiftUI
import Combine
import UIKit
import UserNotifications
import Entities
import FactoryKit
import Library

@MainActor
final class SettingsViewModel: ObservableObject {

    @Injected(\.notificationsHandler) private var notificationsHandler: NotificationsHandler
    @Injected(\.preferences) var preferences: Preferences
    @Injected(\.subscriptionManager) private var subscriptionManager: SubscriptionManagerType
    @Injected(\.notificationsScheduler) private var notificationsScheduler: NotificationsScheduler

    private let formatter: DateFormatter

    /// Read live: purchases from any paywall and RevenueCat updates write the
    /// stored flag, and the storage-changes subscription below re-renders the view.
    var isProUser: Bool {
        subscriptionManager.isProUser()
    }

    var themeTitle: String {
        "\(preferences.theme.title), \(preferences.colorTheme.title)"
    }

    private var cancellables = Set<AnyCancellable>()
    private let navigator: any SettingsNavigationRouting

    init(navigator: any SettingsNavigationRouting) {
        self.navigator = navigator

        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short

        self.formatter = formatter

        preferences
            .storageChangesPublisher()
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [unowned self] in
                self.objectWillChange.send()
            })
            .store(in: &cancellables)

        setupNotificationsRescheduler()
    }
    
    func navigateToAppearanceSettings() {
        navigator.show(.appearance)
    }
    
    func navigateToTextSettings() {
        navigator.show(.text)
    }
    
    func navigateToCounterSettings() {
        navigator.show(.counter)
    }
    
    func navigateToRemindersSettings() {
        navigator.show(.reminders)
    }
    
    func navigateToAboutAppScreen() {
        navigator.show(.aboutApp)
    }

    func navigateToSubscription() {
        guard isProUser == false else { return }
        navigator.presentSubscription(sourceScreen: SettingsView.viewName)
    }

    /// Observes some preferences to reschedule notifications if needed.
    private func setupNotificationsRescheduler() {
        Publishers.MergeMany(
                preferences.$enableMorningReminder.toVoid().dropFirst(),
                preferences.$enableEveningReminder.toVoid().dropFirst(),
                preferences.$morningNotificationTime.toVoid().dropFirst(),
                preferences.$eveningNotificationTime.toVoid().dropFirst(),
                preferences.$morningReminderSound.toVoid().dropFirst(),
                preferences.$eveningReminderSound.toVoid().dropFirst(),
                preferences.$morningReminderTitle.toVoid().dropFirst(),
                preferences.$eveningReminderTitle.toVoid().dropFirst(),
                preferences.$enableJumuaReminder.toVoid().dropFirst(),
                preferences.$jumuaReminderTime.toVoid().dropFirst(),
                preferences.$jumuahDuaReminderSound.toVoid().dropFirst(),
                preferences.$jumuaReminderTitle.toVoid().dropFirst(),
                // Quote and random reminder bodies are rendered in the content language.
                preferences.$contentLanguage.toVoid().dropFirst()
            )
            .receive(on: DispatchQueue.main)
            .throttle(for: 2, scheduler: DispatchQueue.main, latest: true)
            .sink(receiveValue: { [unowned self] in
                self.notificationsScheduler.rescheduleAll()
            })
            .store(in: &cancellables)
    }
    
}
