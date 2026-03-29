import SwiftUI
import WidgetKit

@available(iOS 17, *)
#Preview("Small - Morning", as: .systemSmall) {
    CategoryQuickAccessWidget()
} timeline: {
    CategoryQuickAccessWidgetEntry(date: morningDate(), completionState: .none)
    CategoryQuickAccessWidgetEntry(date: morningDate(), completionState: .morning)
}

@available(iOS 17, *)
#Preview("Small - Evening", as: .systemSmall) {
    CategoryQuickAccessWidget()
} timeline: {
    CategoryQuickAccessWidgetEntry(date: eveningDate(), completionState: .none)
    CategoryQuickAccessWidgetEntry(date: eveningDate(), completionState: .evening)
}

@available(iOS 17, *)
#Preview("Medium - None", as: .systemMedium) {
    CategoryQuickAccessWidget()
} timeline: {
    CategoryQuickAccessWidgetEntry(date: morningDate(), completionState: .none)
}

@available(iOS 17, *)
#Preview("Medium - Morning Done", as: .systemMedium) {
    CategoryQuickAccessWidget()
} timeline: {
    CategoryQuickAccessWidgetEntry(date: morningDate(), completionState: .morning)
}

@available(iOS 17, *)
#Preview("Medium - All Done", as: .systemMedium) {
    CategoryQuickAccessWidget()
} timeline: {
    CategoryQuickAccessWidgetEntry(date: morningDate(), completionState: .all)
}

private func morningDate() -> Date {
    Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
}

private func eveningDate() -> Date {
    Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date()
}
