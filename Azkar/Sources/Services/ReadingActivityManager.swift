#if canImport(ActivityKit)
import ActivityKit
import Foundation
import Entities

@available(iOS 16.2, *)
actor ReadingActivityManager {

    struct SessionConfig: Sendable {
        let categoryName: String
        let categoryRawValue: String
        let categoryIcon: String
        let categoryImageName: String
        let currentPage: Int
        let totalPages: Int
        let completedRepeats: Int
        let totalRepeats: Int
        let currentZikrTitle: String
        let currentZikrRemainingRepeats: Int
        let currentZikrTotalRepeats: Int
    }

    static let shared = ReadingActivityManager()
    private var currentActivity: Activity<AzkarReadingActivityAttributes>?
    private var currentSessionID: UUID?
    private var latestUpdateSequence = 0

    private init() {}

    /// Starts a Live Activity for the given category.
    /// Ends any existing activity first to ensure only one per category.
    @discardableResult
    func startSession(_ config: SessionConfig) async -> UUID? {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return nil }

        // If already tracking the same category, keep it
        if let existing = currentActivity,
           existing.attributes.categoryRawValue == config.categoryRawValue,
           let currentSessionID {
            return currentSessionID
        }

        // End any existing activity for a different category
        if let existing = currentActivity {
            await existing.end(nil, dismissalPolicy: .immediate)
            currentActivity = nil
        }

        // End all orphaned activities to prevent duplicates
        for activity in Activity<AzkarReadingActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }

        let attributes = AzkarReadingActivityAttributes(
            categoryName: config.categoryName,
            categoryRawValue: config.categoryRawValue,
            categoryIcon: config.categoryIcon,
            categoryImageName: config.categoryImageName
        )

        let state = AzkarReadingActivityAttributes.ContentState(
            currentPage: config.currentPage,
            totalPages: config.totalPages,
            completedRepeats: config.completedRepeats,
            totalRepeats: config.totalRepeats,
            currentZikrTitle: String(config.currentZikrTitle.prefix(80)),
            currentZikrRemainingRepeats: config.currentZikrRemainingRepeats,
            currentZikrTotalRepeats: config.currentZikrTotalRepeats,
            isCompleted: false
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
            latestUpdateSequence = 0
            let sessionID = UUID()
            currentSessionID = sessionID
            return sessionID
        } catch {
            print("Failed to start Live Activity: \(error)")
            return nil
        }
    }

    func updateSession(
        state: AzkarReadingActivityAttributes.ContentState,
        sequence: Int,
        sessionID: UUID
    ) async {
        guard sessionID == currentSessionID,
              sequence >= latestUpdateSequence,
              let activity = currentActivity else {
            return
        }

        latestUpdateSequence = sequence
        await activity.update(.init(state: state, staleDate: nil))
    }

    func endSession(isCompleted: Bool, totalRepeats: Int, sessionID: UUID?) async {
        guard let activity = currentActivity else { return }
        guard sessionID == nil || sessionID == currentSessionID else { return }

        currentActivity = nil
        currentSessionID = nil
        latestUpdateSequence = 0

        let current = activity.content.state
        let finalState = AzkarReadingActivityAttributes.ContentState(
            currentPage: current.totalPages,
            totalPages: current.totalPages,
            completedRepeats: totalRepeats,
            totalRepeats: totalRepeats,
            currentZikrTitle: "",
            currentZikrRemainingRepeats: 0,
            currentZikrTotalRepeats: 0,
            isCompleted: isCompleted
        )

        await activity.end(
            .init(state: finalState, staleDate: nil),
            dismissalPolicy: isCompleted ? .after(.now + 5) : .immediate
        )
    }

    var hasActiveSession: Bool {
        currentActivity != nil
    }

    func hasActiveSession(for categoryRawValue: String) -> Bool {
        currentActivity?.attributes.categoryRawValue == categoryRawValue
    }

    func endAllActivities() async {
        currentActivity = nil
        currentSessionID = nil
        latestUpdateSequence = 0

        for activity in Activity<AzkarReadingActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
#endif
