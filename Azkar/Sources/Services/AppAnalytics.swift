import Foundation
import Extensions
import DatabaseInteractors
import AzkarServices

protocol AppAnalyticsTracking {
    func start()
    func track(_ event: AppAnalyticsEvent)
}

final class AppAnalyticsStack {

    let processedEventsStore: AnalyticsDatabaseService?
    let localAnalytics: AppAnalyticsTracking

    init(
        preferences: Preferences = .shared,
        notificationsHandler: NotificationsHandler = .shared
    ) {
        let databasePath = FileManager.default
            .appGroupContainerURL
            .appendingPathComponent("analytics.db")
            .absoluteString

        guard let database = try? AnalyticsSQLiteDatabase(databasePath: databasePath) else {
            processedEventsStore = nil
            localAnalytics = NoopAppAnalytics()
            return
        }

        processedEventsStore = AnalyticsSQLiteDatabaseService(database: database)
        localAnalytics = AppAnalytics(
            store: LocalAnalyticsSQLiteStore(database: database),
            preferences: preferences,
            notificationsHandler: notificationsHandler
        )
    }

}

final class AppAnalytics: AppAnalyticsTracking {

    private let recorder: LocalAnalyticsRecorder
    private let usageTracker: AppUsageTracker
    private var hasStarted = false

    init(
        store: LocalAnalyticsStore,
        preferences: Preferences,
        notificationsHandler: NotificationsHandler
    ) {
        let metadataProvider = AppAnalyticsMetadataProvider(preferences: preferences)
        let recorder = LocalAnalyticsRecorder(
            store: store,
            commonMetadata: metadataProvider.metadata
        )
        self.recorder = recorder
        usageTracker = AppUsageTracker(
            recorder: recorder,
            preferences: preferences,
            notificationsHandler: notificationsHandler
        )
    }

    func start() {
        guard hasStarted == false else {
            return
        }
        hasStarted = true
        AnalyticsReporter.addTarget(LocalAnalyticsTarget(recorder: recorder))
        usageTracker.start()
    }

    func track(_ event: AppAnalyticsEvent) {
        Task {
            await recorder.record(event)
        }
    }

}

final class NoopAppAnalytics: AppAnalyticsTracking {
    func start() {}
    func track(_ event: AppAnalyticsEvent) {}
}
