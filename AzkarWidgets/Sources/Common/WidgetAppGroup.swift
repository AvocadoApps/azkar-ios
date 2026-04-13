import Foundation

let WIDGET_APP_GROUP_IDENTIFIER = "group.io.jawziyya.azkar-app"
let WIDGET_APP_GROUP_USER_DEFAULTS = UserDefaults(suiteName: WIDGET_APP_GROUP_IDENTIFIER) ?? .standard

enum WidgetAppGroup {
    static let identifier = WIDGET_APP_GROUP_IDENTIFIER
    static let userDefaults = WIDGET_APP_GROUP_USER_DEFAULTS
}
