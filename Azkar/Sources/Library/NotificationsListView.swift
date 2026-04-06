import SwiftUI

protocol UserNotification {
    var title: String { get }
    var body: String? { get }
    var date: Date { get }
    var details: String { get }
}

extension UNNotificationRequest: UserNotification {
    
    var title: String {
        return content.title
    }
    
    var body: String? {
        return content.body.isEmpty ? nil : content.body
    }
    
    var date: Date {
        return (trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate()
            ?? Date()
    }
    
    var soundInfo: String? {
        return content.sound?.description
    }
    
    var details: String {
        return """
        Body: \(body ?? "n/a")
        Sound: \(soundInfo ?? "n/a")
        """
    }
    
}

struct DummyUserNotification: UserNotification {
    var title: String
    var body: String?
    var date: Date
    var details: String = UUID().uuidString
}

final class NotificationsListViewModel: ObservableObject {
    @Published var notifications: [NotificationsRowViewModel] = []
    
    var numberOfNotifications: String {
        "Total scheduled notifications: \(notifications.count)"
    }
    
    init(notifications: @escaping (() async -> [UserNotification])) {
        Task(priority: .userInitiated) {
            let notifications = await notifications()
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .medium
            let notificationViewModels = notifications.enumerated().map { index, notification in
                let time = dateFormatter.string(from: notification.date)
                return NotificationsRowViewModel(
                    row: index,
                    title: notification.title,
                    body: notification.body,
                    date: time,
                    details: notification.details
                )
            }
            await MainActor.run {
                self.notifications = notificationViewModels
            }
        }
    }
    
    func removeScheduledNotifications() {
        notifications = []
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
}

struct NotificationsRowViewModel {
    let row: Int
    let title: String
    let body: String?
    let date: String
    let details: String

    var accessibilitySummary: String {
        [
            String(
                format: String(localized: "accessibility.notifications.item-number"),
                locale: Locale.current,
                row + 1
            ),
            title,
            body,
            date,
            details
        ]
        .compactMap { $0 }
        .joined(separator: ", ")
    }
}

private struct NotificationsRowView: View {
    let vm: NotificationsRowViewModel
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text("Notification #\(vm.row + 1)")
                    .foregroundStyle(.secondary)
                    .font(.callout.smallCaps())
                
                Spacer()
                
                Text(vm.date)
                    .foregroundStyle(Color.primary)
                    .font(.footnote)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(vm.title)
                        .foregroundStyle(.primary)
                        .font(.callout)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                
                Text(vm.details)
                    .foregroundStyle(.primary)
                    .font(.caption)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(16)
        .cornerRadius(15)
        .padding(.horizontal, 16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(vm.accessibilitySummary)
    }
}

struct NotificationsListView: View {
    
    @ObservedObject var viewModel: NotificationsListViewModel
    
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [.init(.flexible(minimum: 100))],
                alignment: .center,
                spacing: 0,
                pinnedViews: [],
                content: {
                    VStack {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Notifications")
                                    .font(.largeTitle.bold())
                                Text(viewModel.numberOfNotifications)
                                    .foregroundStyle(.secondary)
                                    .font(.callout)
                            }
                            .multilineTextAlignment(.leading)
                            Spacer()
                            Button(action: viewModel.removeScheduledNotifications, label: {
                                Image(systemName: "trash")
                            })
                            .accessibilityLabel(Text("accessibility.notifications.remove-scheduled"))
                            .disabled(viewModel.notifications.isEmpty)
                        }
                        .padding()
                        
                        if viewModel.notifications.isEmpty {
                            Text("No scheduled notifications")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(viewModel.notifications, id: \.row) { vm in
                                NotificationsRowView(vm: vm)
                                    .background(.contentBackground)
                            }
                        }
                    }
                }
            )
        }
        .background(.background, ignoreSafeArea: .all)
        .background(
            Text("This view is only visible in test builds")
                .ignoresSafeArea(edges: .bottom)
                .foregroundStyle(.secondary)
            ,
            alignment: .bottom
        )
    }
    
}

struct NotificationsListView_Previews: PreviewProvider {

    static var previews: some View {
        let notifications: [DummyUserNotification] = (1...10).map { _ in
            DummyUserNotification(title: UUID().uuidString, body: nil, date: Date())
        }
        let viewModel = NotificationsListViewModel(
            notifications: { notifications }
        )
        return NotificationsListView(viewModel: viewModel)
    }

}
