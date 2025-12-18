import Foundation
import Entities

public protocol AdsServiceType {
    func getAd() -> AsyncStream<Ad>
    func saveAd(_ ad: Ad) async throws
    func sendAnalytics(for ad: Ad, action: AnalyticsRecord.ActionType)
}
