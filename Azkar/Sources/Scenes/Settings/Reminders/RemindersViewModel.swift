import SwiftUI
import Combine
import FactoryKit
import Library

@MainActor
final class RemindersViewModel: ObservableObject {
    
    // MARK: - Common properties
    let navigator: any SettingsNavigationRouting
    @Injected(\.preferences) var preferences: Preferences
    lazy var notificationsDisabledViewModel: NotificationsDisabledViewModel = .init(observationType: .soundAccess, didChangeCallback: objectWillChange.send)
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Adhkar Reminders properties
    @Published var morningTime: String = ""
    @Published var eveningTime: String = ""
    @Published var jumuaReminderTime: String = ""
    private let formatter: DateFormatter
    
    // MARK: - Initialization
    
    init(navigator: any SettingsNavigationRouting) {
        self.navigator = navigator
        
        // Adhkar reminders initialization
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        self.formatter = formatter
        
        morningTime = formatter.string(from: preferences.morningNotificationTime)
        eveningTime = formatter.string(from: preferences.eveningNotificationTime)
        jumuaReminderTime = formatter.string(from: preferences.jumuaReminderTime)
        
        Publishers.Merge4(
            preferences.$enableAdhkarReminder.toVoid(),
            preferences.$enableJumuaReminder.toVoid(),
            preferences.$adhkarReminderSound.toVoid(),
            preferences.$jumuahDuaReminderSound.toVoid()
        )
        .eraseToAnyPublisher()
        .receive(on: RunLoop.main)
        .sink(receiveValue: { [unowned self] _ in
            withAnimationIfAllowed(.smooth) {
                objectWillChange.send()
            }
        })
        .store(in: &cancellables)
    }
    
    // MARK: - Common methods
    
    func navigateToNotificationsList() {
        navigator.show(.notificationsList)
    }
    
    // MARK: - Adhkar Reminders methods
    
    func presentAdhkarSoundPicker() {
        navigator.show(.soundPicker(.init(sound: preferences.adhkarReminderSound, type: .adhkar)))
    }
    
    var morningNotificationDateRange: ClosedRange<Date> {
        let minDate = DateComponents(calendar: Calendar.current, hour: 2, minute: 0).date ?? Date()
        let maxDate = DateComponents(calendar: Calendar.current, hour: 12, minute: 0).date ?? Date()
        return minDate ... maxDate
    }
    
    var eveningNotificationDateRange: ClosedRange<Date> {
        let minDate = DateComponents(calendar: Calendar.current, hour: 13, minute: 0).date ?? Date()
        let maxDate = DateComponents(calendar: Calendar.current, hour: 18, minute: 0).date ?? Date()
        return minDate ... maxDate
    }

    func getDatesRange(fromHour hour: Int, hours: Int) -> [Date] {
        let now = DateComponents(calendar: Calendar.current, hour: hour, minute: 0).date ?? Date()
        return (1...(hours * 2)).reduce(into: [now]) { (dates, multiplier) in
            let duration = DateComponents(calendar: Calendar.current, minute: multiplier * 30)
            let newDate = Calendar.current.date(byAdding: duration, to: now) ?? now
            dates.append(newDate)
        }
    }

    var morningDateItems: [String] {
        return getDatesRange(fromHour: 2, hours: 11).compactMap(formatter.string)
    }

    var eveningDateItems: [String] {
        return getDatesRange(fromHour: 12, hours: 16).compactMap(formatter.string)
    }
    
    func setMorningTime(_ time: String) {
        preferences.morningNotificationTime = formatter.date(from: morningTime) ?? defaultMorningNotificationTime
        morningTime = formatter.string(from: preferences.morningNotificationTime)
    }

    func setEveningTime(_ time: String) {
        preferences.eveningNotificationTime = formatter.date(from: eveningTime) ?? defaultEveningNotificationTime
        eveningTime = formatter.string(from: preferences.eveningNotificationTime)
    }
    
    // MARK: - Jumua Reminders methods
    
    var jumuaDateItems: [String] {
        return getDatesRange(fromHour: 12, hours: 18).compactMap(formatter.string)
    }
    
    func setJumuaReminderTime(_ time: String) {
        preferences.jumuaReminderTime = formatter.date(from: jumuaReminderTime) ?? defaultJumuaReminderTime
        jumuaReminderTime = formatter.string(from: preferences.jumuaReminderTime)
    }
    
    func presentJumuaSoundPicker() {
        navigator.show(.soundPicker(.init(sound: preferences.jumuahDuaReminderSound, type: .jumua)))
    }
    
    var jumuaNotificationDateRange: ClosedRange<Date> {
        let minDate = DateComponents(calendar: Calendar.current, hour: 10, minute: 0).date ?? Date()
        let maxDate = DateComponents(calendar: Calendar.current, hour: 18, minute: 0).date ?? Date()
        return minDate ... maxDate
    }
    
}
