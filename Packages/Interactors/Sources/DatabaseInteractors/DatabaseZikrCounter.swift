// Copyright © 2022 Al Jawziyya. All rights reserved.

import Foundation
import Combine
import Entities
import GRDB
import AzkarServices

public final class DatabaseZikrCounter: ZikrCounterType {
    
    private let databasePath: String
    private let getKey: () -> Int
    
    private var completedRepeatsPublishers: [ZikrCategory: CurrentValueSubject<Int, Never>] = [:]
    
    public init(
        databasePath: String,
        getKey: @escaping () -> Int
    ) {
        self.databasePath = databasePath
        self.getKey = getKey
        
        do {
            let tableName = ZikrCounter.databaseTableName
            
            var migrator = DatabaseMigrator()
            let queue = try DatabaseQueue(path: databasePath)
            
            if DatabaseHelper.tableExists(tableName, databaseQueue: queue) == false {
                try queue.write { db in
                    try db.create(table: tableName) { t in
                        t.autoIncrementedPrimaryKey("id").notNull()
                        t.column("key", .integer).notNull()
                        t.column("zikr_id", .integer).notNull()
                        t.column("category", .text).notNull()
                    }
                }
            }
            
            migrator.registerMigration("create_completion_marks") { db in
                try db.create(table: "completion_marks") { t in
                    t.autoIncrementedPrimaryKey("id").notNull()
                    t.column("key", .integer).notNull()
                    t.column("category", .text).notNull()
                }
            }
            
            try migrator.migrate(queue)
        } catch {
            // TODO: Handle errors.
            print(error)
        }
    }

    private func getDatabaseQueue() throws -> DatabaseQueue {
        return try DatabaseQueue(path: databasePath)
    }
        
    public func getRemainingRepeats(for zikr: Zikr) async -> Int? {
        let key = getKey()
        do {
            return try await getDatabaseQueue().read { db in
                if let category = zikr.category, let row = try Row.fetchOne(
                    db,
                    sql: "SELECT COUNT(*) as count FROM counters WHERE key = ? AND zikr_id = ? AND category = ?",
                    arguments: [key, zikr.id, category.rawValue]
                ) {
                    let count: Int = row["count"]
                    return max(0, zikr.repeats - count)
                }
                return nil
            }
        } catch {
            return nil
        }
    }
    
    public func markCategoryAsCompleted(_ category: ZikrCategory) async throws {
        let key = getKey()
        try await getDatabaseQueue().write { db in
            try db.execute(
                sql: "INSERT INTO completion_marks (key, category) VALUES (?, ?)",
                arguments: [key, category.rawValue]
            )
        }
    }
    
    public func isCategoryCompleted(_ category: ZikrCategory) async -> Bool {
        let key = getKey()
        do {
            return try await getDatabaseQueue().read { db in
                let count = try Int.fetchOne(
                    db,
                    sql: "SELECT COUNT(*) FROM completion_marks WHERE key = ? AND category = ?",
                    arguments: [key, category.rawValue]
                ) ?? 0
                return count > 0
            }
        } catch {
            print("Error checking category completion: \(error)")
            return false
        }
    }
    
    public func incrementCounter(for zikr: Zikr) async throws {
        try await incrementCounter(for: zikr, by: 1)
    }
    
    public func incrementCounter(for zikr: Zikr, by count: Int) async throws {
        let key = getKey()
        let newRecords = Array(repeating: ZikrCounter(key: key, zikrId: zikr.id, category: zikr.category), count: count)
        try await getDatabaseQueue().inTransaction { db in
            for record in newRecords {
                try record.insert(db)
            }
            return .commit
        }
        
        let remainingRepeats = await getRemainingRepeats(for: zikr)
        
        // Also update the completed repeats publisher if this zikr has a category
        if let category = zikr.category, let publisher = completedRepeatsPublishers[category] {
            do {
                let count = try await getDatabaseQueue().read { db in
                    try Int.fetchOne(
                        db,
                        sql: "SELECT COUNT(*) FROM counters WHERE key = ? AND category = ?",
                        arguments: [key, category.rawValue]
                    ) ?? 0
                }
                publisher.send(count)
            } catch {
                print("Error updating completed repeats count: \(error)")
            }
        }
    }
    
    public func observeCompletedRepeats(in category: ZikrCategory) -> AnyPublisher<Int, Never> {
        let key = getKey()
        
        // Create or get an existing publisher for this category
        let publisher = completedRepeatsPublishers[category] ?? CurrentValueSubject<Int, Never>(0)
        completedRepeatsPublishers[category] = publisher
        
        // Immediately start fetching the current count
        Task {
            do {
                let count = try await getDatabaseQueue().read { db in
                    try Int.fetchOne(
                        db,
                        sql: "SELECT COUNT(*) FROM counters WHERE key = ? AND category = ?",
                        arguments: [key, category.rawValue]
                    ) ?? 0
                }
                publisher.send(count)
            } catch {
                print("Error fetching completed repeats count: \(error)")
            }
        }
        
        // Set up observation using GRDB's ValueObservation
        do {
            let queue = try getDatabaseQueue()
            
            // Use ValueObservation to track changes to the counters table for this category
            let observation = ValueObservation.tracking { db in
                try Int.fetchOne(
                    db,
                    sql: "SELECT COUNT(*) FROM counters WHERE key = ? AND category = ?",
                    arguments: [key, category.rawValue]
                ) ?? 0
            }
            
            // Start the observation on a background queue
            observation.start(
                in: queue,
                onError: { error in
                    print("Error observing completed repeats: \(error)")
                },
                onChange: { [weak publisher] count in
                    publisher?.send(count)
                }
            )
        } catch {
            print("Failed to start observation: \(error)")
        }
        
        return publisher.eraseToAnyPublisher()
    }
    
    public func resetCounterForCategory(_ category: ZikrCategory) async {
        let key = getKey()
        do {
            try await getDatabaseQueue().write { db in
                try db.execute(
                    sql: "DELETE FROM counters WHERE key = ? AND category = ?",
                    arguments: [key, category.rawValue]
                )
            }
        } catch {
            print("Error resetting category counter: \(error)")
        }
    }
    
    public func getCompletionHistory(days: Int) async -> [Int: Set<String>] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let keys = (0..<days).compactMap { offset -> Int? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return Int(date.timeIntervalSince1970)
        }

        guard !keys.isEmpty else { return [:] }

        do {
            return try await getDatabaseQueue().read { db in
                let placeholders = keys.map { _ in "?" }.joined(separator: ",")
                let sql = """
                    SELECT DISTINCT key, category FROM completion_marks
                    WHERE key IN (\(placeholders))
                    AND category IN ('morning', 'evening', 'night')
                    """
                let rows = try Row.fetchAll(db, sql: sql, arguments: StatementArguments(keys))
                var result: [Int: Set<String>] = [:]
                for row in rows {
                    let key: Int = row["key"]
                    let category: String = row["category"]
                    result[key, default: []].insert(category)
                }
                return result
            }
        } catch {
            return [:]
        }
    }

    public func resetCategoryCompletionMark(_ category: ZikrCategory) async {
        let key = getKey()
        do {
            try await getDatabaseQueue().write { db in
                try db.execute(
                    sql: "DELETE FROM completion_marks WHERE key = ? AND category = ?",
                    arguments: [key, category.rawValue]
                )
            }
        } catch {
            print("Error resetting category completion mark: \(error)")
        }
    }
    
}
