//
//  NotificationsHandler.swift
//  Azkar
//
//  Created by Abdurahim Jauzee on 16.05.2020.
//  Copyright © 2020 Al Jawziyya. All rights reserved.
//

import UIKit
import SwiftUI
import Combine
import FirebaseMessaging
import Entities

enum NotificationCategory: String, Identifiable, Hashable {
    case morning, evening, jumua

    var id: Self { self }
}

enum NotificationUserInfoKey {
    static let sound = "sound"
}

private let notificationCenter = UNUserNotificationCenter.current()

final class NotificationsHandler: NSObject {
    
    enum NotificationsPermissionState: Equatable {
        /// Azkar did not ask for permissions.
        case notDetermined
        
        /// Azkar asked permission but user denied.
        case denied
        
        /// Azkar has access to send notifications withoud sound.
        case noSound
        
        /// Azkar has access to send notifications.
        case granted
        
        var hasAccess: Bool {
            switch self {
            case .noSound, .granted:
                return true
            case .denied, .notDetermined:
                return false
            }
        }
        
        var isDenied: Bool {
            switch self {
            case .denied:
                return true
            default:
                return false
            }
        }
    }

    static let shared = NotificationsHandler()

    let selectedNotificationCategory = CurrentValueSubject<NotificationCategory?, Never>(nil)
    
    var notificationsPermissionStatePublisher: AnyPublisher<NotificationsPermissionState, Never> {
        Publishers
            .Merge(
                NotificationCenter.default
                    .publisher(for: UIApplication.didBecomeActiveNotification, object: nil)
                    .eraseToAnyPublisher()
                    .toVoid()
                    .prepend(())
                    .flatMap { [unowned self] in self.readNotificationSettings() },
                readNotificationSettings()
            )
            .map { settings -> NotificationsPermissionState in
                switch settings.authorizationStatus {
                case .notDetermined:
                    return .notDetermined
                case .denied:
                    return .denied
                case .authorized, .ephemeral, .provisional:
                    let soundAccessDisabled = settings.soundSetting == .disabled
                    if soundAccessDisabled {
                        return .noSound
                    } else {
                        return .granted
                    }
                default:
                    return .notDetermined
                }
            }
            .eraseToAnyPublisher()
    }

    private var cancellables = Set<AnyCancellable>()

    private override init() {
        super.init()
        notificationCenter.delegate = self
    }
    
    private func readNotificationSettings() -> AnyPublisher<UNNotificationSettings, Never> {
        Future { observer in
            notificationCenter
                .getNotificationSettings { settings in
                    observer(.success(settings))
                }
        }
        .eraseToAnyPublisher()
    }

    func removeDeliveredNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
    }

    func removeScheduledNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    func scheduleNotification(
        id: String,
        date: Date,
        title: String? = nil,
        subtitle: String? = nil,
        body: String? = nil,
        category: NotificationCategory,
        sound: ReminderSound
    ) {
        let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: date)
        scheduleNotification(
            id: id,
            title: title,
            subtitle: subtitle,
            body: body,
            dateComponents: dateComponents,
            category: category,
            sound: sound
        )
    }
    
    func scheduleNotification(
        id: String,
        title: String? = nil,
        subtitle: String? = nil,
        body: String? = nil,
        dateComponents: DateComponents,
        category: NotificationCategory,
        sound: ReminderSound
    ) {
        let content = UNMutableNotificationContent()
        if let title {
            content.title = title
        }
        if let subtitle {
            content.subtitle = subtitle
        }
        if let body {
            content.body = body
        }
        content.sound = sound.notificationSound
        content.categoryIdentifier = category.rawValue
        content.userInfo[NotificationUserInfoKey.sound] = sound.rawValue
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        notificationCenter.add(request)
    }

    func scheduleNotification(
        id: String,
        title: String? = nil,
        subtitle: String? = nil,
        body: String? = nil,
        fireDate: Date,
        category: NotificationCategory,
        sound: ReminderSound
    ) {
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let content = UNMutableNotificationContent()
        if let title {
            content.title = title
        }
        if let subtitle {
            content.subtitle = subtitle
        }
        if let body {
            content.body = body
        }
        content.sound = sound.notificationSound
        content.categoryIdentifier = category.rawValue
        content.userInfo[NotificationUserInfoKey.sound] = sound.rawValue
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        notificationCenter.add(request)
    }

    func getNotificationsAuthorizationStatus(
        completion: @escaping ((UNAuthorizationStatus) -> Void)
    ) {
        notificationCenter.getNotificationSettings { settings
            in
            completion(settings.authorizationStatus)
        }
    }

    func requestNotificationsPermission(
        completion: @escaping ((Result<Bool, Error>) -> Void)
    ) {
        notificationCenter
            .requestAuthorization(options: [.alert, .sound]) { (granted, error) in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(granted))
                }
            }
    }

}

extension NotificationsHandler: UNUserNotificationCenterDelegate {
    
    func handleLaunchNotification(_ userInfo: [AnyHashable: Any]) {
        guard
            let aps = userInfo["aps"] as? [String: Any],
            let category = aps["category"] as? String,
            let notificationCategory = NotificationCategory(rawValue: category)
        else {
            return
        }
        
        selectedNotificationCategory.send(notificationCategory)
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Just present the notification as it comes.
        completionHandler([.list, .sound, .banner])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        handleNotification(request: response.notification.request, completionHandler: completionHandler)
    }

    private func handleNotification(
        request: UNNotificationRequest,
        completionHandler: @escaping () -> Void
    ) {
        let category = request.content.categoryIdentifier
        defer {
            completionHandler()
        }
        guard let notificationCategory = NotificationCategory(rawValue: category) else {
            return
        }
        selectedNotificationCategory.send(notificationCategory)
    }

}

extension NotificationsHandler: MessagingDelegate {
    
    func handlePushNotificationToken(_ token: Data) {
        Messaging.messaging().apnsToken = token
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        // Token refresh handling is not needed for FCM APNs integration
    }
        
}
