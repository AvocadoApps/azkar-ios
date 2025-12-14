import Foundation
import Entities

public protocol AnalyticsDatabaseService {

    /// Atomically check and mark an analytics event as processed
    /// Returns the occurrence kind (.first if newly inserted, .repeat if already exists)
    func checkAndMarkEventAsProcessed(
        objectId: Int,
        recordType: AnalyticsRecord.RecordType,
        actionType: AnalyticsRecord.ActionType
    ) async throws -> AnalyticsEvent.OccurrenceKind

    /// Clean up old processed events
    func cleanupOldEvents(olderThan interval: TimeInterval) async throws

}