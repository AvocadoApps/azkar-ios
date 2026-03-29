import WidgetKit

struct CompletionWidgetProvider: TimelineProvider {
    typealias Entry = CompletionWidgetEntry

    private let zikrCounterService = WidgetCounterDataSource.makeCounterService()

    func placeholder(in context: Context) -> Entry {
        Entry(date: Date(), completionState: .morning)
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        Task {
            let completionState = await getCompletionState()
            completion(Entry(date: Date(), completionState: completionState))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        Task {
            let completionState = await getCompletionState()
            let entry = Entry(date: Date(), completionState: completionState)
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
        }
    }

    private func getCompletionState() async -> CompletionState {
        guard let zikrCounterService else {
            return .none
        }

        let isMorningCompleted = await zikrCounterService.isCategoryCompleted(.morning)
        let isEveningCompleted = await zikrCounterService.isCategoryCompleted(.evening)
        let isNightCompleted = await zikrCounterService.isCategoryCompleted(.night)

        var completionState: CompletionState = []
        if isMorningCompleted { completionState.insert(.morning) }
        if isEveningCompleted { completionState.insert(.evening) }
        if isNightCompleted { completionState.insert(.night) }
        return completionState
    }
}
