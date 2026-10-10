import Foundation
import BackgroundTasks
import UserNotifications
import Entities
import FactoryKit
import Library
import DatabaseInteractors

final class NotificationsScheduler {

    @Injected(\.preferences) var preferences: Preferences
    @Injected(\.notificationsHandler) var notificationsHandler: NotificationsHandler

    static let backgroundRefreshTaskIdentifier = "io.jawziyya.azkar-app.reminders.refresh"

    private var database: AzkarDatabase {
        AzkarDatabase(language: preferences.contentLanguage)
    }

    private func quoteCategory(for category: NotificationCategory) -> NotificationQuoteCategory {
        switch category {
        case .morning, .evening:
            return .adhkar
        case .jumua:
            return .jumua
        }
    }

    func rescheduleAll() {
        notificationsHandler.removeScheduledNotifications()

        var reminders: [(id: String, category: NotificationCategory, fireTime: Date, quoteCategory: NotificationQuoteCategory, selection: ReminderTitleSelection, sound: ReminderSound, isDaily: Bool)] = []

        if preferences.enableMorningReminder {
            reminders.append((
                id: Keys.morningReminderId,
                category: .morning,
                fireTime: preferences.morningNotificationTime,
                quoteCategory: .adhkar,
                selection: preferences.morningReminderTitle,
                sound: preferences.morningReminderSound,
                isDaily: true
            ))
        }

        if preferences.enableEveningReminder {
            reminders.append((
                id: Keys.eveningReminderId,
                category: .evening,
                fireTime: preferences.eveningNotificationTime,
                quoteCategory: .adhkar,
                selection: preferences.eveningReminderTitle,
                sound: preferences.eveningReminderSound,
                isDaily: true
            ))
        }

        if preferences.enableJumuaReminder {
            reminders.append((
                id: Keys.jumuaReminderId,
                category: .jumua,
                fireTime: preferences.jumuaReminderTime,
                quoteCategory: .jumua,
                selection: preferences.jumuaReminderTitle,
                sound: preferences.jumuahDuaReminderSound,
                isDaily: false
            ))
        }

        // At most 15 repeating requests: seven weekdays per daily reminder
        // and one Friday request. Delivery does not depend on background refresh.
        var hasRandom = false

        for reminder in reminders {
            switch reminder.selection {
            case .default:
                scheduleDefault(reminder)
            case .quote(let id):
                scheduleQuote(reminder, quoteId: id)
            case .random:
                hasRandom = true
                scheduleRandom(reminder)
            }
        }

        if hasRandom {
            scheduleBackgroundRefresh()
        } else {
            // Nothing left to rotate: drop a refresh request submitted earlier.
            cancelBackgroundRefresh()
        }
    }

    /// Default titles are localized by the system when the notification is
    /// delivered, so a language change applies without rescheduling.
    private func deliveryLocalizedTitle(for category: NotificationCategory) -> String {
        NSString.localizedUserNotificationString(forKey: category.defaultNotificationTitleKey, arguments: nil)
    }

    private func quoteBody(text: String, source: String?) -> String {
        if let source, !source.isEmpty {
            return "\(text) (\(source))"
        }
        return text
    }

    private func scheduleDefault(_ reminder: (id: String, category: NotificationCategory, fireTime: Date, quoteCategory: NotificationQuoteCategory, selection: ReminderTitleSelection, sound: ReminderSound, isDaily: Bool)) {
        if reminder.isDaily {
            notificationsHandler.scheduleNotification(
                id: reminder.id,
                date: reminder.fireTime,
                title: deliveryLocalizedTitle(for: reminder.category),
                subtitle: nil,
                category: reminder.category,
                sound: reminder.sound
            )
        } else {
            var components = Calendar.current.dateComponents([.hour, .minute, .weekday], from: reminder.fireTime)
            components.weekday = 6
            notificationsHandler.scheduleNotification(
                id: reminder.id,
                title: deliveryLocalizedTitle(for: reminder.category),
                subtitle: nil,
                dateComponents: components,
                category: reminder.category,
                sound: reminder.sound
            )
        }
    }

    private func scheduleQuote(_ reminder: (id: String, category: NotificationCategory, fireTime: Date, quoteCategory: NotificationQuoteCategory, selection: ReminderTitleSelection, sound: ReminderSound, isDaily: Bool), quoteId: Int) {
        guard let quote = try? database.getNotificationQuote(id: quoteId) else {
            scheduleDefault(reminder)
            return
        }
        if reminder.isDaily {
            notificationsHandler.scheduleNotification(
                id: reminder.id,
                date: reminder.fireTime,
                body: quoteBody(text: quote.text, source: quote.source),
                category: reminder.category,
                sound: reminder.sound
            )
        } else {
            var components = Calendar.current.dateComponents([.hour, .minute, .weekday], from: reminder.fireTime)
            components.weekday = 6
            notificationsHandler.scheduleNotification(
                id: reminder.id,
                body: quoteBody(text: quote.text, source: quote.source),
                dateComponents: components,
                category: reminder.category,
                sound: reminder.sound
            )
        }
    }

    private func scheduleRandom(_ reminder: (id: String, category: NotificationCategory, fireTime: Date, quoteCategory: NotificationQuoteCategory, selection: ReminderTitleSelection, sound: ReminderSound, isDaily: Bool)) {
        guard let quotes = try? database.getNotificationQuotes(category: reminder.quoteCategory), !quotes.isEmpty else {
            scheduleDefault(reminder)
            return
        }

        let pool = quotes.shuffled()
        let time = Calendar.current.dateComponents([.hour, .minute], from: reminder.fireTime)
        let slotCount = reminder.isDaily ? 7 : 1

        for slot in 1...slotCount {
            var components = time
            if reminder.isDaily {
                components.weekday = slot
            } else {
                // Keep delivering this quote weekly if the app cannot refresh.
                // Foreground/background refresh selects a new random quote.
                components.weekday = 6
            }
            let quote = pool[(slot - 1) % pool.count]
            notificationsHandler.scheduleNotification(
                id: "\(reminder.id).random.\(slot)",
                body: quoteBody(text: quote.text, source: quote.source),
                dateComponents: components,
                category: reminder.category,
                sound: reminder.sound
            )
        }
    }

    func scheduleBackgroundRefresh() {
        #if !targetEnvironment(macCatalyst)
        if #available(iOS 13.0, *) {
            let request = BGAppRefreshTaskRequest(identifier: Self.backgroundRefreshTaskIdentifier)
            request.earliestBeginDate = Date(timeIntervalSinceNow: 12 * 3600)
            do {
                try BGTaskScheduler.shared.submit(request)
            } catch {
                print("Failed to schedule background refresh: \(error)")
            }
        }
        #endif
    }

    private func cancelBackgroundRefresh() {
        #if !targetEnvironment(macCatalyst)
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.backgroundRefreshTaskIdentifier)
        #endif
    }
}
