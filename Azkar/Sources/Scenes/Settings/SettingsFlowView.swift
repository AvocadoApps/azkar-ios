import SwiftUI
import UserNotifications
import AboutApp
import FactoryKit
import Library
import ZikrCollectionsOnboarding
import SwiftNEW

struct SettingsFlowView: View {

    @Injected(\.preferences) private var preferences: Preferences
    private let embedInNavigation: Bool

    @StateObject private var navigator: SettingsNavigator

    init(
        initialDestination: SettingsDestination? = nil,
        embedInNavigation: Bool = false
    ) {
        self.embedInNavigation = embedInNavigation
        _navigator = StateObject(
            wrappedValue: SettingsNavigator(initialDestination: initialDestination)
        )
    }

    var body: some View {
        let content = FlowNavigationStack(
            stack: Binding(
                get: { navigator.stack },
                set: { navigator.stack = $0 }
            ),
            resetToken: .constant(UUID()),
            root: {
                SettingsRootSceneView(navigator: navigator)
            },
            destination: { destination in
                AnyView(destinationView(destination))
            }
        )
        .sheet(item: Binding(
            get: { navigator.sheet },
            set: { navigator.sheet = $0 }
        )) { sheet in
            sheetView(sheet)
        }

        if embedInNavigation {
            NavigationView { content }
#if os(iOS)
                .navigationViewStyle(.stack)
#endif
        } else {
            content
        }
    }

    @ViewBuilder
    private func destinationView(_ destination: SettingsDestination) -> some View {
        switch destination {
        case .notificationsList:
            NotificationsListView(
                viewModel: NotificationsListViewModel(
                    notifications: UNUserNotificationCenter.current().pendingNotificationRequests
                )
            )

        case .appearance:
            AppearanceSettingsDestinationView(navigator: navigator)

        case .text:
            TextSettingsDestinationView(navigator: navigator)

        case .counter:
            CounterSettingsDestinationView(navigator: navigator)

        case .reminders:
            RemindersSettingsDestinationView(navigator: navigator)

        case .soundPicker(let info):
            ReminderSoundPickerDestinationView(info: info, navigator: navigator)

        case .aboutApp:
            AboutAppDestinationView()
        }
    }

    @ViewBuilder
    private func sheetView(_ sheet: SettingsSheet) -> some View {
        switch sheet.destination {
        case .zikrCollectionsOnboarding(let preselectedCollection):
            ZikrCollectionsOnboardingFlowView(
                preselectedCollection: preselectedCollection,
                onZikrCollectionSelect: { newSource in
                    preferences.zikrCollectionSource = newSource
                }
            )
        }
    }
}

private struct SettingsRootSceneView: View {

    @StateObject private var viewModel: SettingsViewModel

    init(navigator: any SettingsNavigationRouting) {
        _viewModel = StateObject(
            wrappedValue: SettingsViewModel(navigator: navigator)
        )
    }

    var body: some View {
        SettingsView(viewModel: viewModel)
    }
}

private struct AppearanceSettingsDestinationView: View {

    @StateObject private var viewModel: AppearanceViewModel

    init(navigator: any SettingsNavigationRouting) {
        _viewModel = StateObject(
            wrappedValue: AppearanceViewModel(navigator: navigator)
        )
    }

    var body: some View {
        AppearanceScreen(viewModel: viewModel)
    }
}

private struct TextSettingsDestinationView: View {

    @StateObject private var viewModel: TextSettingsViewModel

    init(navigator: any SettingsNavigationRouting) {
        _viewModel = StateObject(
            wrappedValue: TextSettingsViewModel(navigator: navigator)
        )
    }

    var body: some View {
        TextSettingsScreen(viewModel: viewModel)
    }
}

private struct CounterSettingsDestinationView: View {

    @StateObject private var viewModel: CounterViewModel

    init(navigator: any SettingsNavigationRouting) {
        _viewModel = StateObject(
            wrappedValue: CounterViewModel(navigator: navigator)
        )
    }

    var body: some View {
        CounterView(viewModel: viewModel)
    }
}

private struct RemindersSettingsDestinationView: View {

    @StateObject private var viewModel: RemindersViewModel

    init(navigator: any SettingsNavigationRouting) {
        _viewModel = StateObject(
            wrappedValue: RemindersViewModel(navigator: navigator)
        )
    }

    var body: some View {
        RemindersScreen(viewModel: viewModel)
    }
}

private struct ReminderSoundPickerDestinationView: View {

    @StateObject private var viewModel: ReminderSoundPickerViewModel

    init(info: SoundPickerInfo, navigator: any SettingsNavigationRouting) {
        _viewModel = StateObject(
            wrappedValue: ReminderSoundPickerViewModel(
                type: info.type,
                preferredSound: info.sound,
                subscribeScreenTrigger: {
                    navigator.presentSubscription(sourceScreen: ReminderSoundPickerView.viewName)
                }
            )
        )
    }

    var body: some View {
        ReminderSoundPickerView(viewModel: viewModel)
    }
}

private struct AboutAppDestinationView: View {

    @Injected(\.subscriptionManager) private var subscriptionManager: SubscriptionManagerType
    @State private var showWhatsNew = false
    @AppStorage("lastSeenVersion") private var lastSeenVersion: String = ""

    var body: some View {
        AppInfoView(
            viewModel: AppInfoViewModel(
                appVersion: {
                    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")!
                    let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")!
                    return "\(String(localized: "common.version")) \(version) (\(build))"
                }(),
                isProUser: subscriptionManager.isProUser(),
                onVersionTap: {
                    showWhatsNew = true
                }
            )
        )
        .sheet(isPresented: $showWhatsNew) {
            let notes = AppFlowView.loadReleaseNotes(lastSeenVersion: AppFlowView.appVersion)
            SwiftNEW(
                color: .white,
                background: .solidColor(Color(.systemBackground)),
                triggerStyle: .hidden,
                currentItems: notes.current,
                historyItems: notes.history,
                strings: AppFlowView.releaseNotesStrings,
                history: true,
                presentation: .embed,
                onContinue: {
                    showWhatsNew = false
                    lastSeenVersion = AppFlowView.appVersion
                }
            )
        }
    }
}
