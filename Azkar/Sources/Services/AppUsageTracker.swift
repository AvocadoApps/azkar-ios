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

        beginSessionIfNeeded(source: .appLaunch)
        Task {
            await recorder.cleanup(retainingEventsFor: retentionInterval)
        }
    }

    private func observeLifecycle() {
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.beginSessionIfNeeded(source: .foreground)
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
            .contentLanguage,
            publisher: preferences.$contentLanguage.eraseToAnyPublisher(),
            serialize: { $0.rawValue }
        )
        observeSetting(
            .zikrCollectionSource,
            publisher: preferences.$zikrCollectionSource.eraseToAnyPublisher(),
            serialize: { $0.rawValue }
        )
        observeSetting(
            .colorTheme,
            publisher: preferences.$colorTheme.eraseToAnyPublisher(),
            serialize: String.init(describing:)
        )
        observeSetting(
            .appTheme,
            publisher: preferences.$appTheme.eraseToAnyPublisher(),
            serialize: String.init(describing:)
        )
        observeSetting(
            .zikrReadingMode,
            publisher: preferences.$zikrReadingMode.eraseToAnyPublisher(),
            serialize: String.init(describing:)
        )
        observeSetting(
            .counterType,
            publisher: preferences.$counterType.eraseToAnyPublisher(),
            serialize: String.init(describing:)
        )
        observeSetting(
            .counterPosition,
            publisher: preferences.$counterPosition.eraseToAnyPublisher(),
            serialize: String.init(describing:)
        )
        observeSetting(
            .enableAdhkarReminder,
            publisher: preferences.$enableAdhkarReminder.eraseToAnyPublisher(),
            serialize: String.init(describing:)
        )
        observeSetting(
            .enableJumuaReminder,
            publisher: preferences.$enableJumuaReminder.eraseToAnyPublisher(),
            serialize: String.init(describing:)
        )
        observeSetting(
            .transliterationType,
            publisher: preferences.$transliterationType.eraseToAnyPublisher(),
            serialize: String.init(describing:)
        )
        observeSetting(
            .appIcon,
            publisher: preferences.$appIcon.eraseToAnyPublisher(),
            serialize: String.init(describing:)
        )
    }

    private func observeSetting<T: Equatable>(
        _ setting: AppAnalyticsSetting,
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
                    setting: setting,
                    oldValue: previousValue,
                    newValue: value
                ))
            }
            .store(in: &cancellables)
    }

    private func beginSessionIfNeeded(source: AppAnalyticsSource) {
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

    var analyticsValue: AppAnalyticsNotificationPermissionState {
        switch self {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .noSound:
            return .grantedNoSound
        case .granted:
            return .granted
        }
    }

}
