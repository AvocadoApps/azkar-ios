import Foundation
import FactoryKit
import Entities
import Library

struct SoundPickerInfo: Hashable {
    let sound: ReminderSound
    let type: ReminderSoundPickerViewModel.ReminderType
}

enum SettingsDestination: Hashable {
    case notificationsList
    case appearance
    case text
    case counter
    case reminders
    case soundPicker(SoundPickerInfo)
    case aboutApp
}

struct SettingsSheet: Identifiable {
    enum Destination {
        case zikrCollectionsOnboarding(preselectedCollection: ZikrCollectionSource)
    }

    let id = UUID()
    let destination: Destination
}

@MainActor
protocol SettingsNavigationRouting: AnyObject {
    func show(_ destination: SettingsDestination)
    func presentSubscription(sourceScreen: String)
    func presentZikrCollectionsOnboarding()
}

@MainActor
final class EmptySettingsNavigator: SettingsNavigationRouting {
    func show(_ destination: SettingsDestination) {}
    func presentSubscription(sourceScreen: String) {}
    func presentZikrCollectionsOnboarding() {}
}

@MainActor
final class SettingsNavigator: ObservableObject, SettingsNavigationRouting {

    @Published var stack: [SettingsDestination] = []
    @Published var sheet: SettingsSheet?

    @Injected(\.preferences) private var preferences: Preferences
    @Injected(\.subscriptionManager) private var subscriptionManager: SubscriptionManagerType
    @Injected(\.localAnalytics) private var analytics: AppAnalyticsTracking

    init(initialDestination: SettingsDestination? = nil) {
        if let initialDestination {
            stack = [initialDestination]
        }
    }

    func show(_ destination: SettingsDestination) {
        analytics.track(.settingsDetailOpened(destination: destination.analyticsName))
        stack.append(destination)
    }

    func presentSubscription(sourceScreen: String) {
        subscriptionManager.presentPaywall(
            presentationType: .screen(sourceScreen),
            completion: nil
        )
    }

    func presentZikrCollectionsOnboarding() {
        sheet = .init(destination: .zikrCollectionsOnboarding(
            preselectedCollection: preferences.zikrCollectionSource
        ))
    }
}

extension SettingsDestination {

    var analyticsName: String {
        switch self {
        case .notificationsList:
            return "notifications_list"
        case .appearance:
            return "appearance"
        case .text:
            return "text"
        case .counter:
            return "counter"
        case .reminders:
            return "reminders"
        case .soundPicker:
            return "sound_picker"
        case .aboutApp:
            return "about_app"
        }
    }

}
