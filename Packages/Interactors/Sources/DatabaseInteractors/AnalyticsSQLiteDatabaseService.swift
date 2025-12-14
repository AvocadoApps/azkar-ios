import Foundation
import Entities
import GRDB
import AzkarServices

struct ProcessedAnalyticsEvent: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "processed_analytics_events"

    let objectId: Int
    let recordType: String
    let actionType: String
    let firstSeenAt: Date

    enum CodingKeys: String, CodingKey {
        case objectId = "object_id"
        case recordType = "record_type"
        case actionType = "action_type"
        case firstSeenAt = "first_seen_at"
    }

    static func createTable(in db: Database) throws {
        try db.create(table: databaseTableName) { t in
            t.column("object_id", .integer).notNull()
            t.column("record_type", .text).notNull()
            t.column("action_type", .text).notNull()
            t.column("first_seen_at", .datetime).notNull()
            t.primaryKey(["object_id", "record_type", "action_type"])
        }
    }
}

public final class AnalyticsSQLiteDatabaseService: AnalyticsDatabaseService {

    private let database: DatabaseWriter

    public init(databasePath: String) throws {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("Create processed_analytics_events table") { db in
            try ProcessedAnalyticsEvent.createTable(in: db)
        }

        migrator.registerMigration("Add index on first_seen_at") { db in
            try db.create(index: "idx_first_seen_at", on: ProcessedAnalyticsEvent.databaseTableName, columns: ["first_seen_at"])
        }

        let config = GRDB.Configuration()
        database = try DatabasePool(path: databasePath, configuration: config)
        try migrator.migrate(database)
    }

    public func checkAndMarkEventAsProcessed(
        objectId: Int,
        recordType: AnalyticsRecord.RecordType,
        actionType: AnalyticsRecord.ActionType
    ) async throws -> AnalyticsEvent.OccurrenceKind {
        try await database.write { db in
            let event = ProcessedAnalyticsEvent(
                objectId: objectId,
                recordType: recordType.rawValue,
                actionType: actionType.rawValue,
                firstSeenAt: Date()
            )

            do {
                try event.insert(db)
                // Insert succeeded, this is the first occurrence
                return .first
            } catch let error as DatabaseError {
                // Check if it's a primary key constraint violation
                if error.resultCode == .SQLITE_CONSTRAINT {
                    // Event already exists, this is a repeat
                    return .repeat
                }
                // Some other database error, rethrow it
                throw error
            }
        }
    }

    public func cleanupOldEvents(olderThan interval: TimeInterval) async throws {
        try await database.write { db in
            let cutoffDate = Date().addingTimeInterval(-interval)
            try ProcessedAnalyticsEvent
                .filter(Column("first_seen_at") < cutoffDate)
                .deleteAll(db)
        }
    }

}