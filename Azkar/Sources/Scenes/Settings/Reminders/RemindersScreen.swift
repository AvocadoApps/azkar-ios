import SwiftUI
import Library

struct RemindersScreen: View {
    
    @ObservedObject var viewModel: RemindersViewModel
    
    var showDebugNotifications = false
    
    var body: some View {
        ScrollView {
            VStack {
                content
            }
        }
        .foregroundStyle(.text)
        .applyThemedToggleStyle()
        .customScrollContentBackground()
        .background(.background, ignoreSafeArea: .all)
        .navigationTitle("settings.reminders.title")
        .onAppear {
            AnalyticsReporter.reportScreen("Settings", className: viewName)
        }
    }
    
    var content: some View {
        Group {
            if viewModel.notificationsDisabledViewModel.isAccessGranted {
                adhkarReminderSection
                
                jumuaReminderSection
            } else {
                notificationsDisabledView
            }
            
            if showDebugNotifications && UIApplication.shared.inDebugMode {
                Divider()
                Button(action: viewModel.navigateToNotificationsList) {
                    Text("[DEBUG] Scheduled notifications")
                        .padding(.vertical, 8)
                }
            }
        }
    }
    
    // MARK: - Adhkar Reminders Section
    
    var adhkarReminderSection: some View {
        VStack(spacing: 0) {
            HeaderView(text: "settings.reminders.morning-evening.label")
            
            VStack {
                Toggle(
                    "settings.reminders.morning-evening.switch-label",
                    isOn: $viewModel.preferences.enableAdhkarReminder
                )
                
                if viewModel.preferences.enableAdhkarReminder {
                    Divider()
                    
                    adhkarTimePicker
                    
                    Divider()
                    
                    if viewModel.notificationsDisabledViewModel.isAccessGranted {
                        NavigationButton(
                            title: "settings.reminders.sounds.sound",
                            label: viewModel.preferences.adhkarReminderSound.title,
                            action: viewModel.presentAdhkarSoundPicker
                        )
                    }
                }
            }
            .applyContainerStyle()
        }
    }
    
    @ViewBuilder
    var adhkarTimePicker: some View {
        if UIDevice.current.isMac {
            adhkarMacTimePicker
        } else {
            adhkarIosTimePicker
        }
    }
    
    var adhkarIosTimePicker: some View {
        Group {
            HStack {
                Text("settings.reminders.morning-evening.morning-label")
                    .fixedSize(horizontal: false, vertical: true)
                    .systemFont(.body)
                    .foregroundStyle(.text)
                
                Spacer()
                
                DatePicker(
                    "settings.reminders.morning-evening.morning-label",
                    selection: $viewModel.preferences.morningNotificationTime,
                    in: viewModel.morningNotificationDateRange,
                    displayedComponents: [.hourAndMinute]
                )
                .labelsHidden()
            }
            
            Divider()
            
            HStack {
                Text("settings.reminders.morning-evening.evening-label")
                    .fixedSize(horizontal: false, vertical: true)
                    .systemFont(.body)
                    .foregroundStyle(.text)
                
                Spacer()
                
                DatePicker(
                    "settings.reminders.morning-evening.evening-label",
                    selection: $viewModel.preferences.eveningNotificationTime,
                    in: viewModel.eveningNotificationDateRange,
                    displayedComponents: [.hourAndMinute]
                )
                .labelsHidden()
            }
        }
    }
    
    var adhkarMacTimePicker: some View {
        Group {
            PickerView(label: "settings.reminders.morning-evening.morning-label", titleDisplayMode: .inline, subtitle: viewModel.morningTime, destination: adhkarMacMorningTimePicker)
            
            PickerView(label: "settings.reminders.morning-evening.evening-label", titleDisplayMode: .inline, subtitle: viewModel.eveningTime, destination: adhkarMacEveningTimePicker)
        }
    }
        
    var adhkarMacMorningTimePicker: some View {
        ItemPickerView(
            selection: .init(get: {
                return viewModel.morningTime
            }, set: viewModel.setMorningTime),
            items: viewModel.morningDateItems,
            dismissOnSelect: true
        )
    }

    var adhkarMacEveningTimePicker: some View {
        ItemPickerView(
            selection: .init(get: {
                return viewModel.eveningTime
            }, set: viewModel.setEveningTime),
            items: viewModel.eveningDateItems,
            dismissOnSelect: true
        )
    }
    
    // MARK: - Jumua Reminders Section
    var jumuaReminderSection: some View {
        VStack(spacing: 0) {
            HeaderView(text: "settings.reminders.jumua.label")
            
            VStack {
                Toggle(
                    "settings.reminders.jumua.switch-label",
                    isOn: $viewModel.preferences.enableJumuaReminder
                )
                
                if viewModel.preferences.enableJumuaReminder {
                    Divider()
                    
                    jumuaTimePicker
                    
                    Divider()
                    
                    if viewModel.notificationsDisabledViewModel.isAccessGranted {
                        NavigationButton(
                            title: "settings.reminders.sounds.sound",
                            label: viewModel.preferences.jumuahDuaReminderSound.title,
                            action: viewModel.presentJumuaSoundPicker
                        )
                    }
                }
            }
            .applyContainerStyle()
        }
    }
    
    @ViewBuilder
    var jumuaTimePicker: some View {
        if UIDevice.current.isMac {
            jumuaMacTimePicker
        } else {
            jumuaIosTimePicker
        }
    }
    
    var jumuaMacTimePicker: some View {
        PickerView(
            label: "settings.reminders.jumua.label",
            titleDisplayMode: .inline,
            subtitle: viewModel.jumuaReminderTime,
            destination: jumuaMacEveningTimePicker
        )
    }
    
    var jumuaMacEveningTimePicker: some View {
        ItemPickerView(
            selection: .init(get: {
                return viewModel.jumuaReminderTime
            }, set: viewModel.setJumuaReminderTime(_:)),
            items: viewModel.jumuaDateItems,
            dismissOnSelect: true
        )
    }
    
    var jumuaIosTimePicker: some View {
        HStack {
            Text("settings.reminders.time")
                .fixedSize(horizontal: false, vertical: true)
                .systemFont(.body)
                .foregroundStyle(.text)
            
            Spacer()
            
            DatePicker(
                "Time",
                selection: $viewModel.preferences.jumuaReminderTime,
                in: viewModel.jumuaNotificationDateRange,
                displayedComponents: [.hourAndMinute]
            )
            .labelsHidden()
        }
    }
    
    var notificationsDisabledView: some View {
        NotificationsDisabledView(viewModel: viewModel.notificationsDisabledViewModel)
    }
}

#Preview("RemindersScreen") {
    RemindersScreen(
        viewModel: RemindersViewModel(
            navigator: EmptySettingsNavigator()
        )
    )
}
