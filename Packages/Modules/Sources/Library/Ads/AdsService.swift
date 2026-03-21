import Foundation
import Entities
import AzkarServices
import DatabaseInteractors

public final class AdsService: AdsServiceType {

    private let remoteAdsFetchLimit = 10
    
    let localStorageRepository: AdsRepository
    let remoteStorageRepository: AdsRepository
    let analyticsService: AnalyticsService
    
    public init(
        databasePath: String,
        language: Language,
        analyticsDatabase: AnalyticsDatabaseService?
    ) throws {
        let supabaseClient = try getSupabaseClient()
        localStorageRepository = try AdsSQLiteRepository(
            language: language,
            databaseFilePath: databasePath
        )
        remoteStorageRepository = AdsSupabaseRepository(
            supabaseClient: supabaseClient,
            language: language
        )
        analyticsService = AnalyticsService(
            supabaseClient: supabaseClient,
            analyticsDatabase: analyticsDatabase
        )
    }
    
    public func getAd() -> AsyncStream<Ad> {
        AsyncStream { continuation in
            Task {
                do {
                    var createdDate: Date?
                    var updatedDate: Date?
                    let localAds = try await localStorageRepository.getAds(
                        newerThan: nil,
                        orUpdatedAfter: nil,
                        limit: 1
                    )
                    if let ad = localAds.first {
                        createdDate = ad.createdAt
                        updatedDate = ad.updatedAt
                        continuation.yield(ad)
                    }
                    
                    let remoteAds = try await remoteStorageRepository.getAds(
                        newerThan: createdDate,
                        orUpdatedAfter: updatedDate,
                        limit: remoteAdsFetchLimit
                    )
                    for ad in remoteAds {
                        if try await localStorageRepository.isAdSeen(ad) == false {
                            try await localStorageRepository.saveAd(ad)
                            continuation.yield(ad)
                            break
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish()
                }
            }
        }
    }
    
    public func saveAd(_ ad: Ad) async throws {
        try await localStorageRepository.saveAd(ad)
    }
    
    public func sendAnalytics(for ad: Ad, action: AnalyticsRecord.ActionType) {
        Task {
            await analyticsService.sendAnalyticsEvent(
                objectId: ad.id,
                recordType: .ad,
                actionType: action
            )
        }
    }

    public func markAsSeen(ad: Ad) {
        Task {
            try await localStorageRepository.markAsSeen(ad: ad)
        }
    }

}
