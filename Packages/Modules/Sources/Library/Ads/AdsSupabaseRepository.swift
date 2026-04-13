import Foundation
import Supabase
import Entities
import AzkarServices

final class AdsSupabaseRepository: AdsRepository {
    
    private let supabaseClient: SupabaseClient
    private let language: Language
    
    init(
        supabaseClient: SupabaseClient,
        language: Language
    ) {
        self.supabaseClient = supabaseClient
        self.language = language
    }
    
    func getAds(
        newerThan: Date?,
        orUpdatedAfter: Date?,
        limit: Int
    ) async throws -> [Ad] {
        var adsQuery = supabaseClient
            .from("ads")
            .select()
            .eq("language", value: language.rawValue)
        
        #if DEBUG
        if CommandLine.arguments.contains("--ads-test") {
            adsQuery = adsQuery.eq("is_published", value: false)
        }
        #else
        adsQuery = adsQuery.eq("is_published", value: true)
        #endif
        
        if let orUpdatedAfter {
            let updateDate = orUpdatedAfter.addingTimeInterval(1).supabaseFormatted
            if let newerThan {
                let createDate = newerThan.addingTimeInterval(1).supabaseFormatted
                adsQuery = adsQuery
                    .or("created_at.gt.\(createDate),updated_at.gt.\(updateDate)")
            } else {
                adsQuery = adsQuery
                    .greaterThan("updated_at", value: updateDate)
            }
        } else if let newerThan {
            let date = newerThan.addingTimeInterval(1).supabaseFormatted
            adsQuery = adsQuery
                .greaterThan("created_at", value: date)
        }
        
        let currentDateFormatted = Date().supabaseFormatted
        let ads: [Ad] = try await adsQuery
            .greaterThan("expire_date", value: currentDateFormatted)
            .lowerThan("begin_date", value: currentDateFormatted)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        return ads
    }
    
    func getAd(_ id: Ad.ID) async throws -> Ad? {
        fatalError("Not supported for remote repository")
    }

    func isAdSeen(_ ad: Ad) async throws -> Bool {
        fatalError("Not supported for remote repository")
    }
    
    func saveAd(_ ad: Ad) async throws {
        fatalError("Not supported for remote repository")
    }
    
    func saveAds(_ ads: [Ad]) async throws {
        fatalError("Not supported for remote repository")
    }

    func markAsSeen(ad: Ad) async throws {
        fatalError("Not supported for remote repository")
    }

}
