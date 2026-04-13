#if canImport(ActivityKit) && !targetEnvironment(macCatalyst)
import ActivityKit
import WidgetKit
import Entities

@available(iOS 17, *)
#Preview("Live Activity", as: .content, using: AzkarReadingActivityAttributes(
    categoryName: "Morning Adhkar",
    categoryRawValue: "morning",
    categoryIcon: "sun.max.fill",
    categoryImageName: "categories/morning"
)) {
    AzkarReadingLiveActivity()
} contentStates: {
    AzkarReadingActivityAttributes.ContentState(
        currentPage: 3,
        totalPages: 12,
        completedRepeats: 25,
        totalRepeats: 150,
        currentZikrTitle: "سبحان الله وبحمده",
        currentZikrRemainingRepeats: 3,
        currentZikrTotalRepeats: 10,
        isCompleted: false
    )
    AzkarReadingActivityAttributes.ContentState(
        currentPage: 12,
        totalPages: 12,
        completedRepeats: 150,
        totalRepeats: 150,
        currentZikrTitle: "",
        currentZikrRemainingRepeats: 0,
        currentZikrTotalRepeats: 0,
        isCompleted: true
    )
}
#endif
