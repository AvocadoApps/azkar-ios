import Foundation
import Entities
import AzkarServices

final class DemoAdsService: AdsServiceType {
    func getAd() -> AsyncStream<Entities.Ad> {
        return AsyncStream<Ad> { continuation in
            continuation.yield(Ad.telegramBotDemo)
            continuation.finish()
        }
    }
    func saveAd(_ ad: Ad) async throws {}
    func sendAnalytics(for ad: Ad, action: AnalyticsRecord.ActionType) {}
    func markAsSeen(ad: Ad) {}
}
