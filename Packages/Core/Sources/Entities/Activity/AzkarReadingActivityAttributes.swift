#if canImport(ActivityKit) && !targetEnvironment(macCatalyst)
import ActivityKit
import Foundation

@available(iOS 16.1, *)
public struct AzkarReadingActivityAttributes: ActivityAttributes {

    public struct ContentState: Codable, Hashable, Sendable {
        /// Current page (1-based adhkar index)
        public var currentPage: Int
        /// Total number of adhkar in the category
        public var totalPages: Int
        /// Number of completed repeats across all adhkar in the category
        public var completedRepeats: Int
        /// Total repeats across all adhkar in the category
        public var totalRepeats: Int
        public var currentZikrTitle: String
        /// Remaining repeats for the current zikr
        public var currentZikrRemainingRepeats: Int
        /// Total repeats for the current zikr
        public var currentZikrTotalRepeats: Int
        public var isCompleted: Bool

        public init(
            currentPage: Int,
            totalPages: Int,
            completedRepeats: Int,
            totalRepeats: Int,
            currentZikrTitle: String,
            currentZikrRemainingRepeats: Int,
            currentZikrTotalRepeats: Int,
            isCompleted: Bool
        ) {
            self.currentPage = currentPage
            self.totalPages = totalPages
            self.completedRepeats = completedRepeats
            self.totalRepeats = totalRepeats
            self.currentZikrTitle = currentZikrTitle
            self.currentZikrRemainingRepeats = currentZikrRemainingRepeats
            self.currentZikrTotalRepeats = currentZikrTotalRepeats
            self.isCompleted = isCompleted
        }

        /// Progress based on total repeats across all adhkar
        public var progress: Double {
            guard totalRepeats > 0 else { return 0 }
            return min(1.0, Double(completedRepeats) / Double(totalRepeats))
        }

        /// Label text based on adhkar page count
        public var progressText: String {
            "\(currentPage)/\(totalPages)"
        }

    }

    public var categoryName: String
    public var categoryRawValue: String
    public var categoryIcon: String
    public var categoryImageName: String

    public init(
        categoryName: String,
        categoryRawValue: String,
        categoryIcon: String,
        categoryImageName: String
    ) {
        self.categoryName = categoryName
        self.categoryRawValue = categoryRawValue
        self.categoryIcon = categoryIcon
        self.categoryImageName = categoryImageName
    }
}
#endif // canImport(ActivityKit) && !targetEnvironment(macCatalyst)
