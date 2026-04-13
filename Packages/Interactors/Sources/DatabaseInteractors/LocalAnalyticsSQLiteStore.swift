import Foundation
import GRDB
import AzkarServices

public final class LocalAnalyticsSQLiteStore: LocalAnalyticsStore {

    private let writer: DatabaseWriter

    public convenience init(databasePath: String) throws {
        try self.init(database: AnalyticsSQLiteDatabase(databasePath: databasePath))
    }

    public init(database: AnalyticsSQLiteDatabase) {
        writer = database.writer
    }

    public func recordEvent(
        name: String,
        kind: LocalAnalyticsEventKind,
        metadata: [String: String],
        sessionId: String?,
        recordedAt: Date
    ) async throws {
        let payload = try metadata.isEmpty
            ? nil
            : String(data: JSONEncoder().encode(metadata), encoding: .utf8)

        try await writer.write { db in
            var record = StoredLocalAnalyticsEvent(
                id: nil,
                kind: kind.rawValue,
                name: name,
                metadata: payload,
                sessionId: sessionId,
                recordedAt: recordedAt
            )
            try record.insert(db)
        }
    }

    public func fetchSummary(since date: Date?) async throws -> LocalAnalyticsSummary {
        try await writer.read { db in
            let totalEvents = try Int.fetchOne(
                db,
                sql: """
                SELECT COUNT(*)
                FROM \(StoredLocalAnalyticsEvent.databaseTableName)
                \(date == nil ? "" : "WHERE recorded_at >= ?")
                """,
                arguments: date.map(statementArguments(for:)) ?? StatementArguments()
            ) ?? 0

            let totalSessions = try Int.fetchOne(
                db,
                sql: """
                SELECT COUNT(DISTINCT session_id)
                FROM \(StoredLocalAnalyticsEvent.databaseTableName)
                WHERE session_id IS NOT NULL
                \(date == nil ? "" : "AND recorded_at >= ?")
                """,
                arguments: date.map(statementArguments(for:)) ?? StatementArguments()
            ) ?? 0

            let uniqueEventNames = try Int.fetchOne(
                db,
                sql: """
                SELECT COUNT(DISTINCT name)
                FROM \(StoredLocalAnalyticsEvent.databaseTableName)
                WHERE kind = ?
                \(date == nil ? "" : "AND recorded_at >= ?")
                """,
                arguments: summaryArguments(kind: .event, date: date)
            ) ?? 0

            let uniqueScreens = try Int.fetchOne(
                db,
                sql: """
                SELECT COUNT(DISTINCT name)
                FROM \(StoredLocalAnalyticsEvent.databaseTableName)
                WHERE kind = ?
                \(date == nil ? "" : "AND recorded_at >= ?")
                """,
                arguments: summaryArguments(kind: .screen, date: date)
            ) ?? 0

            let lastRecordedAt = try Date.fetchOne(
                db,
                sql: """
                SELECT MAX(recorded_at)
                FROM \(StoredLocalAnalyticsEvent.databaseTableName)
                \(date == nil ? "" : "WHERE recorded_at >= ?")
                """,
                arguments: date.map(statementArguments(for:)) ?? StatementArguments()
            )

            return LocalAnalyticsSummary(
                totalEvents: totalEvents,
                totalSessions: totalSessions,
                uniqueEventNames: uniqueEventNames,
                uniqueScreens: uniqueScreens,
                lastRecordedAt: lastRecordedAt
            )
        }
    }

    public func fetchTopEvents(
        kind: LocalAnalyticsEventKind?,
        limit: Int,
        since date: Date?
    ) async throws -> [LocalAnalyticsEventCount] {
        let safeLimit = max(1, limit)

        return try await writer.read { db in
            let rows = try Row.fetchAll(
                db,
                sql: """
                SELECT name, COUNT(*) AS count
                FROM \(StoredLocalAnalyticsEvent.databaseTableName)
                WHERE (? IS NULL OR kind = ?)
                AND (? IS NULL OR recorded_at >= ?)
                GROUP BY name
                ORDER BY count DESC, name ASC
                LIMIT ?
                """,
                arguments: StatementArguments([
                    kind?.rawValue,
                    kind?.rawValue,
                    date,
                    date,
                    safeLimit
                ])
            )

            return rows.map {
                LocalAnalyticsEventCount(name: $0["name"], count: $0["count"])
            }
        }
    }

    public func cleanupEvents(olderThan interval: TimeInterval) async throws {
        try await writer.write { db in
            let cutoffDate = Date().addingTimeInterval(-interval)
            try StoredLocalAnalyticsEvent
                .filter(Column("recorded_at") < cutoffDate)
                .deleteAll(db)
        }
    }

}

private func summaryArguments(kind: LocalAnalyticsEventKind, date: Date?) -> StatementArguments {
    var arguments = StatementArguments([kind.rawValue])
    if let date {
        arguments += StatementArguments([date])
    }
    return arguments
}

private func statementArguments(for date: Date) -> StatementArguments {
    StatementArguments([date])
}
