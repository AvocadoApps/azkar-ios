import Foundation
import WidgetKit

@available(iOS 16, *)
struct CategoryQuickAccessWidgetEntry: TimelineEntry {
    let date: Date
    let completionState: CompletionState
}
