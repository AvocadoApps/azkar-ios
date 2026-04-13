import Foundation
import Entities
import GRDB
import AzkarServices
import Extensions

extension Ad: PersistableRecord, FetchableRecord {
    
    static public let databaseTableName = "ads"
    
    public static var databaseColumnEncodingStrategy: DatabaseColumnEncodingStrategy {
        .convertToSnakeCase
    }
    
    public static var databaseColumnDecodingStrategy: DatabaseColumnDecodingStrategy {
        .convertFromSnakeCase
    }
    
}

public final class AdsSQLiteRepository: AdsRepository {
    
    private let language: Language
    private let databasePool: GRDB.DatabasePool
    
    public init(
        language: Language,
        databaseFilePath: String
    ) throws {
        self.language = language
        databasePool = try DatabasePool(path: databaseFilePath)
        
        var migrator = DatabaseMigrator()
        migrator.registerMigration("Create ads") { db in
            try db.create(table: "ads") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("title", .text)
                t.column("body", .text)
                t.column("action_title", .text)
                t.column("action_link", .text)
                t.column("image_link", .text)
                
                t.column("background_color", .text)
                t.column("foreground_color", .text)
                t.column("accent_color", .text)
                
                t.column("presentation_type", .text).notNull()
                t.column("image_mode", .text).notNull()
                t.column("language", .text).notNull()
                
                t.column("created_at", .datetime).notNull()
                t.column("updated_at", .datetime).notNull()
                t.column("begin_date", .datetime).notNull()
                t.column("expire_date", .datetime).notNull()
                t.column("is_hidden", .boolean).defaults(to: false)
            }
        }
        migrator.registerMigration("Add is_hidden column") { db in
            if try db.tableExists("ads"), try !db.columns(in: "ads").map(\.name).contains("is_hidden") {
                try db.alter(table: "ads") { t in
                    t.add(column: "is_hidden", .boolean).defaults(to: false)
                }
            }
        }
        migrator.registerMigration("Add presentation_type column") { db in
            if try db.tableExists("ads"), try !db.columns(in: "ads").map(\.name).contains("presentation_type") {
                try db.alter(table: "ads") { t in
                    t.add(column: "presentation_type", .text).defaults(to: "banner_regular")
                }
            }
        }
        migrator.registerMigration("Add group_id column") { db in
            if try db.tableExists("ads"), try !db.columns(in: "ads").map(\.name).contains("group_id") {
                try db.alter(table: "ads") { t in
                    t.add(column: "group_id", .integer)
                }
            }
        }
        migrator.registerMigration("Create seen_ads table") { db in
            if try !db.tableExists("seen_ads") {
                try db.create(table: "seen_ads") { t in
                    t.column("group_key", .text).primaryKey()
                }
            }
        }
        migrator.eraseDatabaseOnSchemaChange = true
        
        do {
            try migrator.migrate(databasePool)
        } catch {
            print("Error", error.localizedDescription)
        }
    }
    
    public func getAds(
        newerThan: Date?,
        orUpdatedAfter: Date?,
        limit: Int
    ) async throws -> [Ad] {
        let lang = language.rawValue
        return try await databasePool
            .read { db in
                var query = Ad
                    .filter(sql: "language = ?", arguments: [lang])
                
                if let orUpdatedAfter {
                    let updateDate = orUpdatedAfter.addingTimeInterval(1).supabaseFormatted
                    if let newerThan {
                        let createDate = newerThan.addingTimeInterval(1).supabaseFormatted
                        query = query
                            .filter(sql: "created_at > ? OR updated_at > ?", arguments: [
                                createDate,
                                updateDate
                            ])
                    } else {
                        query = query.filter(sql: "updated_at > ?", arguments: [updateDate])
                    }
                } else if let newerThan {
                    let date = newerThan.addingTimeInterval(1).supabaseFormatted
                    query = query.filter(sql: "created_at > ?", arguments: [date])
                }
                
                let formattedDate = Date().supabaseFormatted
                
                return try query
                    .filter(sql: "begin_date < ?", arguments: [formattedDate])
                    .filter(sql: "expire_date > ?", arguments: [formattedDate])
                    .filter(sql: "is_hidden = ?", arguments: [false])
                    .filter(sql: "NOT EXISTS (SELECT 1 FROM seen_ads WHERE group_key = 'a:' || CAST(ads.id AS TEXT) OR (ads.group_id IS NOT NULL AND group_key = 'g:' || CAST(ads.group_id AS TEXT)))")
                    .order(sql: "created_at DESC")
                    .limit(limit)
                    .fetchAll(db)
            }
    }

    public func isAdSeen(_ ad: Ad) async throws -> Bool {
        let seenKeys = Self.seenKeys(for: ad)
        return try await databasePool.read { db in
            if seenKeys.count == 2 {
                return try Int.fetchOne(
                    db,
                    sql: "SELECT 1 FROM seen_ads WHERE group_key = ? OR group_key = ? LIMIT 1",
                    arguments: [seenKeys[0], seenKeys[1]]
                ) != nil
            }

            return try Int.fetchOne(
                db,
                sql: "SELECT 1 FROM seen_ads WHERE group_key = ? LIMIT 1",
                arguments: [seenKeys[0]]
            ) != nil
        }
    }
    
    public func getAd(_ id: Ad.ID) async throws -> Ad? {
        return try await databasePool
            .read { db in
                try Ad.fetchOne(db, id: id)
            }
    }
    
    public func saveAds(_ ads: [Ad]) async throws {
        try await databasePool.write { db in
            try Ad.deleteAll(db, ids: ads.map(\.id))
            for ad in ads {
                try ad.save(db)
            }
        }
    }
    
    public func saveAd(_ ad: Ad) async throws {
        try await databasePool.write { db in
            try Ad.deleteOne(db, key: ad.id)
            try ad.save(db)
        }
    }

    public func markAsSeen(ad: Ad) async throws {
        let seenKeys = Self.seenKeys(for: ad)
        try await databasePool.write { db in
            for seenKey in seenKeys {
                try db.execute(
                    sql: "INSERT OR REPLACE INTO seen_ads (group_key) VALUES (?)",
                    arguments: [seenKey]
                )
            }
        }
    }

    private static func seenKeys(for ad: Ad) -> [String] {
        var seenKeys = ["a:\(ad.id)"]
        if let groupId = ad.groupId {
            seenKeys.append("g:\(groupId)")
        }
        return seenKeys
    }

}
