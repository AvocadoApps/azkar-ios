import Foundation

public enum LocalAnalyticsEventKind: String, Codable, Sendable {
    case event
    case screen
    case userAttribute
}

public struct LocalAnalyticsSummary: Sendable, Equatable {
    public let totalEvents: Int
    public let totalSessions: Int
    public let uniqueEventNames: Int
    public let uniqueScreens: Int
    public let lastRecordedAt: Date?

    public init(
        totalEvents: Int,
        totalSessions: Int,
        uniqueEventNames: Int,
        uniqueScreens: Int,
        lastRecordedAt: Date?
    ) {
        self.totalEvents = totalEvents
        self.totalSessions = totalSessions
        self.uniqueEventNames = uniqueEventNames
        self.uniqueScreens = uniqueScreens
        self.lastRecordedAt = lastRecordedAt
    }
}

public struct LocalAnalyticsEventCount: Sendable, Equatable {
    public let name: String
    public let count: Int

    public init(name: String, count: Int) {
        self.name = name
        self.count = count
    }
}

public protocol LocalAnalyticsStore {

    func recordEvent(
        name: String,
        kind: LocalAnalyticsEventKind,
        metadata: [String: String],
        sessionId: String?,
        recordedAt: Date
    ) async throws

    func fetchSummary(since date: Date?) async throws -> LocalAnalyticsSummary

    func fetchTopEvents(
        kind: LocalAnalyticsEventKind?,
        limit: Int,
        since date: Date?
    ) async throws -> [LocalAnalyticsEventCount]

    func cleanupEvents(olderThan interval: TimeInterval) async throws

}
