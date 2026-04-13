import WidgetKit

@available(iOS 16, *)
struct CategoryQuickAccessWidgetProvider: TimelineProvider {
    typealias Entry = CategoryQuickAccessWidgetEntry

    private let zikrCounterService = WidgetCounterDataSource.makeCounterService()

    func placeholder(in context: Context) -> Entry {
        Entry(date: Date(), completionState: .none)
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        Task {
            let state = await getCompletionState()
            completion(Entry(date: Date(), completionState: state))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        Task {
            let state = await getCompletionState()
            let now = Date()
            let entry = Entry(date: now, completionState: state)
            let tomorrow = Calendar.current.startOfDay(for: now.addingTimeInterval(86400))
            completion(Timeline(entries: [entry], policy: .after(tomorrow)))
        }
    }

    private func getCompletionState() async -> CompletionState {
        guard let zikrCounterService else {
            return .none
        }

        let isMorningCompleted = await zikrCounterService.isCategoryCompleted(.morning)
        let isEveningCompleted = await zikrCounterService.isCategoryCompleted(.evening)
        let isNightCompleted = await zikrCounterService.isCategoryCompleted(.night)

        var state: CompletionState = []
        if isMorningCompleted { state.insert(.morning) }
        if isEveningCompleted { state.insert(.evening) }
        if isNightCompleted { state.insert(.night) }
        return state
    }
}
