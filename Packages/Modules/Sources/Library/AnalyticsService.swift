import Foundation
import Supabase
import Entities
import AzkarServices
import UIKit

public actor AnalyticsService {

    private let supabaseClient: SupabaseClient
    private let analyticsDatabase: AnalyticsDatabaseService?

    // In-memory LRU cache to prevent sending the same event within 1 minute
    private var lastSentEvents: [String: Date] = [:]
    private var accessOrder: [String] = []
    private let maxCacheSize = 1000
    private let deduplicationWindow: TimeInterval = 60
    private let cacheCleanupAge: TimeInterval = 300 // 5 minutes

    public init(
        supabaseClient: SupabaseClient,
        analyticsDatabase: AnalyticsDatabaseService?
    ) {
        self.supabaseClient = supabaseClient
        self.analyticsDatabase = analyticsDatabase
    }

    public func sendAnalyticsEvent(
        objectId: Int,
        recordType: AnalyticsRecord.RecordType,
        actionType: AnalyticsRecord.ActionType
    ) {
        if !UIApplication.shared.shouldSendAnalytics {
            print("[ANALYTICS] Supabase Event: objectId=\(objectId), recordType=\(recordType), actionType=\(actionType)")
            return
        }
        
        // Check in-memory tracker to prevent sending the same event within 1 minute
        let key = "\(objectId)-\(recordType)-\(actionType)"
        if let lastDate = lastSentEvents[key], Date().timeIntervalSince(lastDate) < deduplicationWindow {
            return
        }

        updateCache(key: key)

        Task {
            let occurrenceKind: AnalyticsEvent.OccurrenceKind?
            if let database = analyticsDatabase {
                do {
                    occurrenceKind = try await database.checkAndMarkEventAsProcessed(
                        objectId: objectId,
                        recordType: recordType,
                        actionType: actionType
                    )
                } catch {
                    print("Failed to check/mark event: \(error.localizedDescription)")
                    occurrenceKind = .repeat
                }
            } else {
                occurrenceKind = nil
            }

            let event = AnalyticsEvent(
                objectId: objectId,
                recordType: recordType,
                actionType: actionType,
                occurrenceKind: occurrenceKind
            )

            do {
                try await supabaseClient
                    .from("analytics")
                    .insert(event)
                    .execute()
                    .value
            } catch {
                print("Failed to send analytics event: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - LRU Cache Management
    private func updateCache(key: String) {
        lastSentEvents[key] = Date()

        if let existingIndex = accessOrder.firstIndex(of: key) {
            accessOrder.remove(at: existingIndex)
        }
        accessOrder.append(key)

        // Enforce size limit
        while accessOrder.count > maxCacheSize {
            if let oldestKey = accessOrder.first {
                accessOrder.removeFirst()
                lastSentEvents.removeValue(forKey: oldestKey)
            }
        }

        // Clean up old entries
        cleanupOldCacheEntries()
    }

    private func cleanupOldCacheEntries() {
        let now = Date()
        let keysToRemove = lastSentEvents.compactMap { (key, date) -> String? in
            if now.timeIntervalSince(date) > cacheCleanupAge {
                return key
            }
            return nil
        }

        for key in keysToRemove {
            lastSentEvents.removeValue(forKey: key)
            if let index = accessOrder.firstIndex(of: key) {
                accessOrder.remove(at: index)
            }
        }
    }

}
