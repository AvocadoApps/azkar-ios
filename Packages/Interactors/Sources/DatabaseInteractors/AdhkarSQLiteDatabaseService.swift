// Copyright © 2022 Al Jawziyya. All rights reserved. 

import Foundation
import Entities
import GRDB
import AzkarServices

extension Language {
    var databaseTableName: String {
        switch self {
        case .arabic: return "azkar"
        default: return "azkar_\(self.id)"
        }
    }
}

private func getFadailTableName(for language: Language) -> String {
    var base = "fadail"
    if language != .arabic {
        base += "_\(language.fallbackLanguage.id)"
    }
    return base
}

public final class AdhkarSQLiteDatabaseService: AdhkarDatabaseService {
    
    public let language: Language

    public init(
        language: Language
    ) {
        self.language = language
    }

    private func getDatabasePath() throws -> String {
        guard let path = Bundle.main.path(forResource: "azkar", ofType: "db") else {
            throw DatabaseServiceError.databaseFileAccesingError
        }
        return path
    }

    private func getDatabaseQueue() throws -> DatabaseQueue {
        var config = Configuration()
        config.readonly = true
        return try DatabaseQueue(path: getDatabasePath(), configuration: config)
    }
    
    public func translationExists(for language: Language) -> Bool {
        do {
            return try DatabaseHelper.tableExists(language.databaseTableName, databaseQueue: getDatabaseQueue())
        } catch {
            return false
        }
    }

    public func getAhadith() throws -> [Hadith] {
        return try getDatabaseQueue().read { db in
            let ahadith = try Row.fetchAll(db, sql: "SELECT * FROM ahadith")
            return ahadith.map { row in
                Hadith(row: row, language: language)
            }
        }
    }

    public func getHadith(_ id: Int) throws -> Hadith? {
        return try getDatabaseQueue().read { db in
            if let hadith = try Row.fetchOne(db, sql: "SELECT * FROM ahadith WHERE id = ?", arguments: [id]) {
                return Hadith(row: hadith, language: language)
            }
            return nil
        }
    }

    public func getFadailCount() throws -> Int {
        let tableName = getFadailTableName(for: language ?? self.language)
        return try getDatabaseQueue().read { db in
            if let row = try Row.fetchOne(db, sql: "SELECT COUNT(*) as count FROM \(tableName)") {
                return row["count"]
            }
            return 0
        }
    }

    public func getFadl(_ id: Int, language: Language? = nil) throws -> Fadl? {
        let tableName = getFadailTableName(for: language ?? self.language)
        return try getDatabaseQueue().read { db in
            if let fadl = try Row.fetchOne(db, sql: "SELECT * FROM \(tableName) WHERE id = ?", arguments: [id]) {
                return Fadl(row: fadl)
            }
            return nil
        }
    }

    public func getRandomFadl(language: Language? = nil) throws -> Fadl? {
        let count = try getFadailCount()
        let id = Int.random(in: 1...count)
        return try getFadl(id, language: language)
    }

    public func getFadail(language: Language? = nil) throws -> [Fadl] {
        let tableName = getFadailTableName(for: language ?? self.language)
        return try getDatabaseQueue().read { db in
            let fadail = try Row.fetchAll(db, sql: "SELECT * FROM \(tableName)")
            return fadail.compactMap { row in
                Fadl(row: row)
            }
        }
    }
    
    private func getAudio(_ audioId: Int, database: Database) throws -> Audio? {
        try Audio.fetchOne(
            database,
            sql: "SELECT * FROM audios WHERE id = ?",
            arguments: [audioId]
        )
    }
    
    private func getAudioTimings(_ audioId: Int, database: Database) throws -> [AudioTiming] {
        try AudioTiming.fetchAll(
            database,
            sql: "SELECT * FROM audio_timings WHERE audio_id = ?",
            arguments: [audioId]
        )
    }

}

// MARK: - Adhkar
public extension AdhkarSQLiteDatabaseService {

    func getZikr(_ id: Int, language: Language?) throws -> Zikr? {
        let lang = language ?? self.language
        return try getDatabaseQueue().read { db in
            let record = try ZikrOrigin.fetchOne(db, id: id)
            let translation = try ZikrTranslation.fetchOne(
                db,
                sql: "SELECT * FROM \(lang.databaseTableName) WHERE id = ?",
                arguments: [id]
            )
            guard let record, let translation else {
                return nil
            }
            
            let audio = try record.audioId.flatMap { id in
                try getAudio(id, database: db)
            }
            let audioTimings = try record.audioId.flatMap { id in
                try getAudioTimings(id, database: db)
            }
            
            return Zikr(
                origin: record,
                language: lang,
                category: nil,
                translation: lang == .arabic ? nil : translation,
                transliteration: translation.transliteration,
                audio: audio,
                audioTimings: audioTimings ?? []
            )
        }
    }
    
    func getZikrBeforeBreakingFast() -> Zikr? {
        let fastBreakingZikrId = 48
        return try? getZikr(fastBreakingZikrId, language: language)
    }

    func getLaylatulQadrDua() -> Zikr? {
        let id = 49
        return try? getZikr(id, language: language)
    }
    
    func getAllAdhkar() throws -> [Zikr] {
        return try getDatabaseQueue().read { db in
            let records = try ZikrOrigin.fetchAll(db, sql: "SELECT * FROM azkar")
            let translations = try ZikrTranslation.fetchAll(
                db,
                sql: "SELECT * FROM \(language.databaseTableName)"
            )
            return zip(records, translations).map { zikr, translation in
                Zikr(
                    origin: zikr,
                    language: language,
                    category: nil,
                    translation: language == .arabic ? nil : translation,
                    transliteration: translation.transliteration,
                    audio: nil,
                    audioTimings: []
                )
            }
        }
    }
    
    func getAdhkar(
        _ category: ZikrCategory,
        collection: ZikrCollectionSource,
        language: Language?
    ) throws -> [Zikr] {
        let lang = language ?? self.language
        return try getDatabaseQueue().read { db in
            guard let collectionData = try ZikrCollectionData.fetchOne(
                db,
                sql: """
                SELECT *
                FROM azkar_groups
                WHERE category = ?
                AND source = ?
                """,
                arguments: [category.rawValue, collection.rawValue]
            ) else {
                return []
            }
            
            let azkarIds = collectionData.azkarIds
            let azkarIdsString = azkarIds.map { "\($0)" }.joined(separator: ", ")
            let records = try ZikrOrigin.fetchAll(
                db,
                sql: """
                SELECT *
                FROM azkar
                WHERE id IN (\(azkarIdsString))
                """
            )
            let azkarDict = Dictionary(uniqueKeysWithValues: records.map { ($0.id, $0) })
            let orderedRecords = azkarIds.compactMap { azkarDict[$0] }
            
            let translationTableName = lang.databaseTableName
            let translations = try ZikrTranslation.fetchAll(
                db,
                sql: """
                SELECT \(translationTableName).*
                FROM \(translationTableName)
                WHERE \(translationTableName).id IN (\(azkarIdsString))
                """
            )
            let translationDict = Dictionary(uniqueKeysWithValues: translations.map { ($0.id, $0) })
            
            let audios = try Audio.fetchAll(db)
            let audioTimings = try AudioTiming.fetchAll(db)

            return orderedRecords.compactMap { zikr in
                let translation = translationDict[zikr.id]
                let audio = audios.first(where: { $0.id == zikr.audioId })
                let transliteration = zikr.source == "Quran" ? nil : translation?.transliteration
                
                return Zikr(
                    origin: zikr,
                    language: lang,
                    category: category,
                    translation: lang == .arabic ? nil : translation,
                    transliteration: transliteration,
                    audio: audio,
                    audioTimings: audioTimings.filter { $0.audioId == audio?.id }
                )
            }
        }
    }
    
    func searchAdhkar(
        _ query: String,
        resultsLimit: UInt8,
        category: ZikrCategory,
        languages: [Language]
    ) async throws -> [Zikr] {
        return try await getDatabaseQueue().read { db in
            try self.getSearchResults(
                for: query,
                resultsLimit: resultsLimit,
                category: category,
                languages: languages,
                from: db
            )
        }
    }
    
    private func normalizeSearchQuery(_ query: String) -> String {
        query
            .trimmingArabicVowels
            .replacingOccurrences(of: "Ё|ё|Е|е", with: "*", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        + "*"
    }

    private func getSearchResults(
        for query: String,
        resultsLimit: UInt8,
        category: ZikrCategory,
        languages: [Language],
        from db: Database
    ) throws -> [Zikr] {
        let normalizedQuery = normalizeSearchQuery(query)
        var azkar: [Zikr] = []
        
        let currentLanguage = self.language
                
        for language in languages {
            
            var tableName = language.databaseTableName
            if language == .arabic, currentLanguage != .arabic {
                tableName = currentLanguage.databaseTableName
            }
            
            let translations = try ZikrTranslation.fetchAll(
                db,
                sql: """
                SELECT \(tableName).*
                FROM \(tableName)
                JOIN "azkar+azkar_group" ON \(tableName).id = "azkar+azkar_group"."azkar_id"
                WHERE "azkar+azkar_group"."group" = ?
                AND \(tableName).id IN (
                    SELECT rowid FROM azkar_search
                    WHERE text_\(language.id) MATCH ?
                    ORDER BY rank
                    LIMIT ?
                )
                """,
                arguments: [category.rawValue, normalizedQuery, resultsLimit]
            )
            
            for translation in translations {
                let zikrId = translation.id
                guard let origin = try ZikrOrigin.fetchOne(
                    db,
                    sql: "SELECT * FROM azkar WHERE id = ?",
                    arguments: [zikrId]
                ) else {
                    continue
                }
                
                let audio = try origin.audioId.flatMap { id in
                    try getAudio(id, database: db)
                }
                let audioTimings = try origin.audioId.flatMap { id in
                    try getAudioTimings(id, database: db)
                }
                let zikr = Zikr(
                    origin: origin,
                    language: language,
                    category: category,
                    translation: currentLanguage == .arabic ? nil : translation,
                    transliteration: translation.transliteration,
                    audio: audio,
                    audioTimings: audioTimings ?? []
                )
                azkar.append(zikr)
            }
        }
        
        return azkar
    }
    
    func getAdhkarCount(_ category: ZikrCategory) throws -> Int {
        return try getDatabaseQueue().read { db in
            guard let row = try Row
                .fetchOne(
                    db,
                    sql: """
                    SELECT COUNT(*) AS count FROM "azkar+azkar_group"
                    WHERE "group" = ?
                    """,
                    arguments: [category.rawValue]
                )
            else {
                return 0
            }
            return row["count"]
        }
    }
    
    func getAudio(audioId: Int) async throws -> Audio? {
        return try await getDatabaseQueue().read { db in
            try self.getAudio(audioId, database: db)
        }
    }

    func getAudioTimings(audioId: Int) async throws -> [AudioTiming] {
        return try await getDatabaseQueue().read { db in
            try self.getAudioTimings(audioId, database: db)
        }
    }

    /// Returns all adhkar in a given category for a specified language.
    func getAdhkar(
        in category: ZikrCategory,
        language: Language? = nil
    ) throws -> [Zikr] {
        let lang = language ?? self.language
        return try getDatabaseQueue().read { db in
            // Fetch azkar IDs from azkar+azkar_group where group = category.rawValue
            let azkarIdRows = try Row.fetchAll(
                db,
                sql: """
                SELECT azkar_id FROM "azkar+azkar_group"
                WHERE "group" = ?
                """,
                arguments: [category.rawValue]
            )
            let azkarIds = azkarIdRows.compactMap { $0["azkar_id"] as Int? }
            if azkarIds.isEmpty { return [] }
            let azkarIdsString = azkarIds.map { "\($0)" }.joined(separator: ", ")

            // Fetch origins
            let origins = try ZikrOrigin.fetchAll(
                db,
                sql: "SELECT * FROM azkar WHERE id IN (\(azkarIdsString))"
            )
            let originDict = Dictionary(uniqueKeysWithValues: origins.map { ($0.id, $0) })
            let orderedOrigins = azkarIds.compactMap { originDict[$0] }

            // Fetch translations
            let translationTable = lang.databaseTableName
            let translations = try ZikrTranslation.fetchAll(
                db,
                sql: "SELECT * FROM \(translationTable) WHERE id IN (\(azkarIdsString))"
            )
            let translationDict = Dictionary(uniqueKeysWithValues: translations.map { ($0.id, $0) })

            // Fetch audios and timings
            let audios = try Audio.fetchAll(db)
            let audioTimings = try AudioTiming.fetchAll(db)

            // Build Zikr objects
            return orderedOrigins.compactMap { origin in
                let translation = translationDict[origin.id]
                let audio = audios.first(where: { $0.id == origin.audioId })
                let transliteration = lang == .arabic ? nil : translation?.transliteration
                return Zikr(
                    origin: origin,
                    language: lang,
                    category: category,
                    translation: lang == .arabic ? nil : translation,
                    transliteration: transliteration,
                    audio: audio,
                    audioTimings: audioTimings.filter { $0.audioId == audio?.id }
                )
            }
        }
    }

}
