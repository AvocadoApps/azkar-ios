import SwiftUI
import WidgetKit

@available(iOS 17, *)
#Preview("None", as: .accessoryCircular) {
    CompletionWidget()
} timeline: {
    CompletionWidgetEntry(date: Date(), completionState: .none)
}

@available(iOS 17, *)
#Preview("Morning", as: .accessoryCircular) {
    CompletionWidget()
} timeline: {
    CompletionWidgetEntry(date: Date(), completionState: .morning)
}

@available(iOS 17, *)
#Preview("Evening", as: .accessoryCircular) {
    CompletionWidget()
} timeline: {
    CompletionWidgetEntry(date: Date(), completionState: .evening)
}

@available(iOS 17, *)
#Preview("Night", as: .accessoryCircular) {
    CompletionWidget()
} timeline: {
    CompletionWidgetEntry(date: Date(), completionState: .night)
}

@available(iOS 17, *)
#Preview("Morning & Evening", as: .accessoryCircular) {
    CompletionWidget()
} timeline: {
    CompletionWidgetEntry(date: Date(), completionState: .morningEvening)
}

@available(iOS 17, *)
#Preview("All", as: .accessoryCircular) {
    CompletionWidget()
} timeline: {
    CompletionWidgetEntry(date: Date(), completionState: .all)
}
