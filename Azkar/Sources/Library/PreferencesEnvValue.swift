import SwiftUI
import FactoryKit

private struct PreferencesEnvKey: EnvironmentKey {
    static let defaultValue: Preferences = Container.shared.preferences()
}

extension EnvironmentValues {
    var preferences: Preferences {
        get { self[PreferencesEnvKey.self] }
        set { self[PreferencesEnvKey.self] = newValue }
    }
}
