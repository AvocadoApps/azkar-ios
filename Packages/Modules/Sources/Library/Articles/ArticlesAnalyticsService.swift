import Foundation
import Supabase
import Entities
import AzkarServices

final class ArticlesAnalyticsService {
    
    private let supabaseClient: SupabaseClient
    private let analyticsService: AnalyticsService
    private var observationChannels: [Article.ID: Supabase.RealtimeChannelV2] = [:]
    private var observationStreams: [Article.ID: AsyncStream<AnyAction>] = [:]
    
    init(
        supabaseClient: SupabaseClient,
        analyticsDatabase: AnalyticsDatabaseService?
    ) {
        self.supabaseClient = supabaseClient
        self.analyticsService = AnalyticsService(
            supabaseClient: supabaseClient,
            analyticsDatabase: analyticsDatabase
        )
    }

    func sendAnalyticsEvent(
        _ type: AnalyticsRecord.ActionType,
        articleId: Article.ID
    ) {
        Task {
            await analyticsService.sendAnalyticsEvent(
                objectId: articleId,
                recordType: .article,
                actionType: type
            )
        }
    }
    
    func getArticleAnalyticsCount(_ articleId: Article.ID) async -> ArticleAnalytics? {
        do {
            return try await supabaseClient
                .from("article_analytics")
                .select("*")
                .eq("article_id", value: articleId)
                .limit(1)
                .single()
                .execute()
                .value
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    private func getAnalyticsStream(for articleId: Article.ID) async -> AsyncStream<AnyAction> {
        let channel: RealtimeChannelV2
        if let existingChannel = observationStreams[articleId] {
            return existingChannel
        } else {
            channel = supabaseClient.realtimeV2.channel("analytics-\(articleId)")
            observationChannels[articleId] = channel
        }
        let anyChange = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "article_analytics",
            filter: String(format: "article_id=eq.%d", articleId)
        )
        observationStreams[articleId] = anyChange
        await channel.subscribe()
        return anyChange
    }
    
    @MainActor
    public func observeAnalyticsNumbers(
        articleId: Article.ID
    ) async -> AsyncStream<ArticleAnalytics> {
        let initialAnalytics = await getArticleAnalyticsCount(articleId)
        let stream = await getAnalyticsStream(for: articleId)
            .compactMap { action -> ArticleAnalytics? in
                let record: [String: AnyJSON]
                switch action {
                case .update(let update):
                    record = update.record
                case .insert(let insert):
                    record = insert.record
                default:
                    return nil
                }
                let sharesNumber = record["shares_count"]?.intValue ?? 0
                let viewsNumber = record["views_count"]?.intValue ?? 0
                return ArticleAnalytics(views: viewsNumber, shares: sharesNumber)
            }
            .eraseToStream()
        return AsyncStream { continuation in
            if let initialAnalytics {
                continuation.yield(initialAnalytics)
            }
            Task {
                for await value in stream {
                    continuation.yield(value)
                }
                continuation.finish()                
            }
        }
    }
    
}

