import Foundation
import Entities
import GRDB
import AzkarServices

public final class AnalyticsSQLiteDatabase {

    let writer: DatabaseWriter

    public init(databasePath: String) throws {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("Create processed_analytics_events table") { db in
            try ProcessedAnalyticsEvent.createTable(in: db)
        }
        migrator.registerMigration("Add index on first_seen_at") { db in
            try db.create(
                index: "idx_first_seen_at",
                on: ProcessedAnalyticsEvent.databaseTableName,
                columns: ["first_seen_at"]
            )
        }
        migrator.registerMigration("Create local_analytics_events table") { db in
            try StoredLocalAnalyticsEvent.createTable(in: db)
        }
        migrator.registerMigration("Add local analytics indexes") { db in
            try db.create(
                index: "idx_local_analytics_recorded_at",
                on: StoredLocalAnalyticsEvent.databaseTableName,
                columns: ["recorded_at"]
            )
            try db.create(
                index: "idx_local_analytics_kind_name",
                on: StoredLocalAnalyticsEvent.databaseTableName,
                columns: ["kind", "name"]
            )
            try db.create(
                index: "idx_local_analytics_session_id",
                on: StoredLocalAnalyticsEvent.databaseTableName,
                columns: ["session_id"]
            )
        }

        let configuration = GRDB.Configuration()
        let writer = try DatabasePool(path: databasePath, configuration: configuration)
        try migrator.migrate(writer)
        self.writer = writer
    }

}

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

struct StoredLocalAnalyticsEvent: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "local_analytics_events"

    var id: Int64?
    let kind: String
    let name: String
    let metadata: String?
    let sessionId: String?
    let recordedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case kind
        case name
        case metadata
        case sessionId = "session_id"
        case recordedAt = "recorded_at"
    }

    static func createTable(in db: Database) throws {
        try db.create(table: databaseTableName) { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("kind", .text).notNull()
            t.column("name", .text).notNull()
            t.column("metadata", .text)
            t.column("session_id", .text)
            t.column("recorded_at", .datetime).notNull()
        }
    }
}

public final class AnalyticsSQLiteDatabaseService: AnalyticsDatabaseService {

    private let writer: DatabaseWriter

    public convenience init(databasePath: String) throws {
        try self.init(database: AnalyticsSQLiteDatabase(databasePath: databasePath))
    }

    public init(database: AnalyticsSQLiteDatabase) {
        writer = database.writer
    }

    public func checkAndMarkEventAsProcessed(
        objectId: Int,
        recordType: AnalyticsRecord.RecordType,
        actionType: AnalyticsRecord.ActionType
    ) async throws -> AnalyticsEvent.OccurrenceKind {
        try await writer.write { db in
            let event = ProcessedAnalyticsEvent(
                objectId: objectId,
                recordType: recordType.rawValue,
                actionType: actionType.rawValue,
                firstSeenAt: Date()
            )

            do {
                try event.insert(db)
                return .first
            } catch let error as DatabaseError {
                if error.resultCode == .SQLITE_CONSTRAINT {
                    return .repeat
                }
                throw error
            }
        }
    }

    public func cleanupOldEvents(olderThan interval: TimeInterval) async throws {
        try await writer.write { db in
            let cutoffDate = Date().addingTimeInterval(-interval)
            try ProcessedAnalyticsEvent
                .filter(Column("first_seen_at") < cutoffDate)
                .deleteAll(db)
        }
    }

}
