import UIKit
import SwiftUI
import Stinsen
import AboutApp
import Library
import ZikrCollectionsOnboarding

struct SoundPickerInfo: Hashable {
    let sound: ReminderSound
    let type: ReminderSoundPickerViewModel.ReminderType
}

enum SettingsRoute: Hashable, RouteKind {
    case subscribe(sourceScreen: String), notificationsList
    case appearance, text, counter
    case reminders, soundPicker(SoundPickerInfo)
    case aboutApp
}

final class SettingsCoordinator: RouteTrigger, Identifiable, NavigationCoordinatable {
    var stack = Stinsen.NavigationStack<SettingsCoordinator>(initial: \.root)
    
    @Root var root = makeRootView
    @Route(.push) var appearance = makeAppearanceView
    @Route(.push) var notificationsList = makeNotificationsListView
    @Route(.push) var text = makeTextView
    @Route(.push) var counter = makeCounterView
    @Route(.push) var reminders = makeRemindersView
    @Route(.push) var soundPicker = makeSoundPickerView
    @Route(.push) var aboutApp = makeAboutAppView
    @Route(.modal) var zikrCollectionsOnboarding = makeZikrCollectionsOnboardingCoordinator
        
    private let databaseService: AzkarDatabase
    private let preferences: Preferences
    private let subscriptionManager: SubscriptionManagerType = SubscriptionManagerFactory.create()
    
    init(
        databaseService: AzkarDatabase,
        preferences: Preferences = Preferences.shared,
        initialRoute: SettingsRoute?
    ) {
        self.databaseService = databaseService
        self.preferences = preferences
        if let initialRoute {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.trigger(initialRoute)
            }
        }
    }
    
    private func createRouter() -> UnownedRouteTrigger<SettingsRoute> {
        UnownedRouteTrigger(router: self)
    }
    
    func trigger(_ route: SettingsRoute) {
        switch route {
            
        case .notificationsList:
            self.route(to: \.notificationsList)
            
        case .subscribe(let sourceScreen):
            subscriptionManager.presentPaywall(presentationType: .screen(sourceScreen), completion: nil)
            
        case .appearance:
            self.route(to: \.appearance)
            
        case .text:
            self.route(to: \.text)
            
        case .counter:
            self.route(to: \.counter)

        case .reminders:
            self.route(to: \.reminders)
            
        case .soundPicker(let info):
            self.route(to: \.soundPicker, info)
            
        case .aboutApp:
            self.route(to: \.aboutApp)

        }
    }
    
}

extension SettingsCoordinator {
    
    func makeRootView() -> some View {
        let viewModel = SettingsViewModel(
            databaseService: databaseService,
            preferences: preferences,
            router: createRouter()
        )
        return SettingsView(viewModel: viewModel)
    }
    
    func makeAppearanceView() -> some View {
        AppearanceScreen(viewModel: AppearanceViewModel(
            router: createRouter()
        ))
    }
    
    func makeNotificationsListView() -> some View {
        let viewModel = NotificationsListViewModel(notifications: UNUserNotificationCenter.current().pendingNotificationRequests)
        return NotificationsListView(viewModel: viewModel)
    }
    
    func makeTextView() -> some View {
        let viewModel = TextSettingsViewModel(router: createRouter())
        return TextSettingsScreen(viewModel: viewModel)
    }
    
    func makeCounterView() -> some View {
        let viewModel = CounterViewModel(router: createRouter())
        return CounterView(viewModel: viewModel)
    }
    
    func makeRemindersView() -> some View {
        RemindersScreen(viewModel: RemindersViewModel(router: createRouter()))
    }
    
    func makeSoundPickerView(_ info: SoundPickerInfo) -> some View {
        ReminderSoundPickerView(viewModel: ReminderSoundPickerViewModel(
            type: info.type,
            preferredSound: info.sound,
            subscribeScreenTrigger: {
                self.trigger(.subscribe(sourceScreen: ReminderSoundPickerView.viewName))
            }
        ))
    }

    func makeAboutAppView() -> some View {
        AppInfoView(viewModel: AppInfoViewModel(
            appVersion: {
                let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")!
                let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")!
                return "\(String(localized: "common.version")) \(version) (\(build))"
            }(),
            isProUser: subscriptionManager.isProUser()
        ))
    }
    
    func makeZikrCollectionsOnboardingCoordinator() -> NavigationViewCoordinator<ZikrCollectionsOnboardingCoordinator> {
        NavigationViewCoordinator(
            ZikrCollectionsOnboardingCoordinator(
                preselectedCollection: .azkarRU,
                onZikrCollectionSelect: { [weak self] newSource in
                    self?.preferences.zikrCollectionSource = newSource
                }
            )
        )
    }
    
}
