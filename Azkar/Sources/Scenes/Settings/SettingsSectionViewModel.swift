import Foundation
import Library

/// Base view model for settings child sections.
@MainActor
class SettingsSectionViewModel: PreferencesDependantViewModel {
    let navigator: any SettingsNavigationRouting

    init(
        preferences: Preferences = .shared,
        navigator: any SettingsNavigationRouting
    ) {
        self.navigator = navigator
        super.init(preferences: preferences)
    }
}
