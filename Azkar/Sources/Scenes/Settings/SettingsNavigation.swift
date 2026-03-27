import Foundation
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

    private let preferences: Preferences
    private let subscriptionManager: SubscriptionManagerType

    init(
        preferences: Preferences = .shared,
        initialDestination: SettingsDestination? = nil,
        subscriptionManager: SubscriptionManagerType = SubscriptionManagerFactory.create()
    ) {
        self.preferences = preferences
        self.subscriptionManager = subscriptionManager
        if let initialDestination {
            stack = [initialDestination]
        }
    }

    func show(_ destination: SettingsDestination) {
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
