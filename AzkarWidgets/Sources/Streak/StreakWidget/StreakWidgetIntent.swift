import AppIntents

@available(iOS 17, *)
struct StreakWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "widget.streak.title"
    static var description: IntentDescription = "widget.streak.description"

    @Parameter(title: "widget.streak.config.includeBedtime", default: false)
    var includeBedtime: Bool

    init() {}

    var requiredCategories: Set<String> {
        includeBedtime ? ["morning", "evening", "night"] : ["morning", "evening"]
    }

    var requiredCompletionState: CompletionState {
        includeBedtime ? [.morning, .evening, .night] : [.morning, .evening]
    }
}
