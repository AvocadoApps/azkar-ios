import Foundation
import Combine
import UIKit
import AzkarServices

final class AppUsageTracker {

    private let recorder: LocalAnalyticsRecorder
    private let preferences: Preferences
    private let notificationsHandler: NotificationsHandler

    private let sessionTimeout: TimeInterval = 30 * 60
    private let retentionInterval: TimeInterval = 180 * 24 * 60 * 60

    private var currentSessionId: String?
    private var lastBackgroundAt: Date?
    private var cancellables = Set<AnyCancellable>()
    private var hasStarted = false

    init(
        recorder: LocalAnalyticsRecorder,
        preferences: Preferences,
        notificationsHandler: NotificationsHandler
    ) {
        self.recorder = recorder
        self.preferences = preferences
        self.notificationsHandler = notificationsHandler
    }

    func start() {
        guard hasStarted == false else {
            return
        }
        hasStarted = true

        observeLifecycle()
        observeNotificationPermissions()
        observeSettingChanges()

        beginSessionIfNeeded(source: "app_launch")
        Task {
            await recorder.cleanup(retainingEventsFor: retentionInterval)
        }
    }

    private func observeLifecycle() {
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.beginSessionIfNeeded(source: "foreground")
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                guard let self else {
                    return
                }
                self.lastBackgroundAt = Date()
                let recorder = self.recorder
                let retentionInterval = self.retentionInterval
                Task {
                    await recorder.cleanup(retainingEventsFor: retentionInterval)
                }
            }
            .store(in: &cancellables)
    }

    private func observeNotificationPermissions() {
        notificationsHandler.notificationsPermissionStatePublisher
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] state in
                self?.track(.notificationPermissionChanged(state: state.analyticsValue))
            }
            .store(in: &cancellables)
    }

    private func observeSettingChanges() {
        observeSetting(
            name: "content_language",
            publisher: preferences.$contentLanguage.eraseToAnyPublisher(),
            serialize: { $0.rawValue }
        )
        observeSetting(
            name: "zikr_collection_source",
            publisher: preferences.$zikrCollectionSource.eraseToAnyPublisher(),
            serialize: { $0.rawValue }
        )
        observeSetting(
            name: "color_theme",
            publisher: preferences.$colorTheme.eraseToAnyPublisher(),
            serialize: String.init(describing:)
        )
        observeSetting(
            name: "app_theme",
            publisher: preferences.$appTheme.eraseToAnyPublisher(),
            serialize: String.init(describing:)
        )
        observeSetting(
            name: "zikr_reading_mode",
            publisher: preferences.$zikrReadingMode.eraseToAnyPublisher(),
            serialize: String.init(describing:)
        )
        observeSetting(
            name: "counter_type",
            publisher: preferences.$counterType.eraseToAnyPublisher(),
            serialize: String.init(describing:)
        )
        observeSetting(
            name: "counter_position",
            publisher: preferences.$counterPosition.eraseToAnyPublisher(),
            serialize: String.init(describing:)
        )
        observeSetting(
            name: "enable_adhkar_reminder",
            publisher: preferences.$enableAdhkarReminder.eraseToAnyPublisher(),
            serialize: String.init(describing:)
        )
        observeSetting(
            name: "enable_jumua_reminder",
            publisher: preferences.$enableJumuaReminder.eraseToAnyPublisher(),
            serialize: String.init(describing:)
        )
        observeSetting(
            name: "transliteration_type",
            publisher: preferences.$transliterationType.eraseToAnyPublisher(),
            serialize: String.init(describing:)
        )
        observeSetting(
            name: "app_icon",
            publisher: preferences.$appIcon.eraseToAnyPublisher(),
            serialize: String.init(describing:)
        )
    }

    private func observeSetting<T: Equatable>(
        name: String,
        publisher: AnyPublisher<T, Never>,
        serialize: @escaping (T) -> String
    ) {
        var previousValue: String?

        publisher
            .map(serialize)
            .removeDuplicates()
            .sink { [weak self] value in
                defer { previousValue = value }
                guard let self, let previousValue else {
                    return
                }

                self.track(.settingChanged(
                    name: name,
                    oldValue: previousValue,
                    newValue: value
                ))
            }
            .store(in: &cancellables)
    }

    private func beginSessionIfNeeded(source: String) {
        let now = Date()
        let shouldStartNewSession: Bool

        if let currentSessionId {
            let elapsed = lastBackgroundAt.map { now.timeIntervalSince($0) } ?? 0
            shouldStartNewSession = elapsed >= sessionTimeout || currentSessionId.isEmpty
        } else {
            shouldStartNewSession = true
        }

        guard shouldStartNewSession else {
            return
        }

        currentSessionId = UUID().uuidString
        lastBackgroundAt = nil
        let sessionId = currentSessionId

        Task {
            await recorder.setSessionId(sessionId)
            await recorder.record(.sessionStarted(
                source: source,
                isFirstLaunch: preferences.hasCompletedFirstLaunch == false
            ))

            if preferences.hasCompletedFirstLaunch == false {
                await recorder.record(.appFirstOpened)
            }
        }
    }

    private func track(_ event: AppAnalyticsEvent) {
        Task {
            await recorder.record(event)
        }
    }

}

private extension NotificationsHandler.NotificationsPermissionState {

    var analyticsValue: String {
        switch self {
        case .notDetermined:
            return "not_determined"
        case .denied:
            return "denied"
        case .noSound:
            return "granted_no_sound"
        case .granted:
            return "granted"
        }
    }

}
