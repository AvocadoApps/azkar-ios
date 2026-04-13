import Foundation
import Entities

enum AppAnalyticsSource: String {
    case appLaunch = "app_launch"
    case foreground
    case notification
    case quickAction = "quick_action"
    case controlCenter = "control_center"
    case deeplink
    case spotlight
    case mainMenu = "main_menu"
    case categoryReader = "category_reader"
    case recent
    case search
    case recentQuery = "recent_query"
    case push
    case sheet
}

enum AppAnalyticsEntrypointTarget {
    case home
    case settings
    case category(ZikrCategory)
    case categoryZikr(ZikrCategory)
    case zikr
    case article
    case hadith
    case raw(String)

    var analyticsValue: String {
        switch self {
        case .home:
            return "home"
        case .settings:
            return "settings"
        case .category(let category):
            return "category_\(category.rawValue)"
        case .categoryZikr(let category):
            return "category_zikr_\(category.rawValue)"
        case .zikr:
            return "zikr"
        case .article:
            return "article"
        case .hadith:
            return "hadith"
        case .raw(let value):
            return value
        }
    }
}

enum AppAnalyticsSetting: String {
    case contentLanguage = "content_language"
    case zikrCollectionSource = "zikr_collection_source"
    case colorTheme = "color_theme"
    case appTheme = "app_theme"
    case zikrReadingMode = "zikr_reading_mode"
    case counterType = "counter_type"
    case counterPosition = "counter_position"
    case enableAdhkarReminder = "enable_adhkar_reminder"
    case enableJumuaReminder = "enable_jumua_reminder"
    case transliterationType = "transliteration_type"
    case appIcon = "app_icon"
}

enum AppAnalyticsSettingsDestination: String {
    case root
    case notificationsList = "notifications_list"
    case appearance
    case text
    case counter
    case reminders
    case soundPicker = "sound_picker"
    case aboutApp = "about_app"
}

enum AppAnalyticsShareType: String {
    case text
    case image
}

enum AppAnalyticsShareAction: String {
    case copy
    case sheet
    case save
}

enum AppAnalyticsArticleShareFormat: String {
    case pdf
}

enum AppAnalyticsNotificationPermissionState: String {
    case notDetermined = "not_determined"
    case denied
    case grantedNoSound = "granted_no_sound"
    case granted
}

enum AppAnalyticsEvent {
    case sessionStarted(source: AppAnalyticsSource, isFirstLaunch: Bool)
    case appFirstOpened
    case appEntrypointUsed(source: AppAnalyticsSource, target: AppAnalyticsEntrypointTarget)
    case notificationPermissionChanged(state: AppAnalyticsNotificationPermissionState)
    case settingChanged(setting: AppAnalyticsSetting, oldValue: String, newValue: String)
    case categoryOpened(category: ZikrCategory, source: AppAnalyticsSource, initialPage: Int?)
    case zikrOpened(id: Zikr.ID, language: Language, source: AppAnalyticsSource)
    case searchResultOpened(id: Zikr.ID, language: Language, queryLength: Int)
    case searchPerformed(
        queryLength: Int,
        selectedTokenCount: Int,
        sectionCount: Int,
        resultCount: Int
    )
    case searchSuggestionSelected(queryLength: Int, source: AppAnalyticsSource)
    case articleOpened(id: Article.ID, source: AppAnalyticsSource)
    case articleShared(id: Article.ID, format: AppAnalyticsArticleShareFormat)
    case zikrShared(id: Zikr.ID, shareType: AppAnalyticsShareType, action: AppAnalyticsShareAction)
    case settingsOpened(source: AppAnalyticsSource, destination: AppAnalyticsSettingsDestination)
    case settingsDetailOpened(destination: AppAnalyticsSettingsDestination)
    case categoryCompleted(category: ZikrCategory, totalRepeats: Int)

    var name: String {
        switch self {
        case .sessionStarted:
            return "session_started"
        case .appFirstOpened:
            return "app_first_opened"
        case .appEntrypointUsed:
            return "app_entrypoint_used"
        case .notificationPermissionChanged:
            return "notification_permission_changed"
        case .settingChanged:
            return "setting_changed"
        case .categoryOpened:
            return "category_opened"
        case .zikrOpened:
            return "zikr_opened"
        case .searchResultOpened:
            return "search_result_opened"
        case .searchPerformed:
            return "search_performed"
        case .searchSuggestionSelected:
            return "search_suggestion_selected"
        case .articleOpened:
            return "article_opened"
        case .articleShared:
            return "article_shared"
        case .zikrShared:
            return "zikr_shared"
        case .settingsOpened:
            return "settings_opened"
        case .settingsDetailOpened:
            return "settings_detail_opened"
        case .categoryCompleted:
            return "category_completed"
        }
    }

    var metadata: [String: Any] {
        switch self {
        case .sessionStarted(let source, let isFirstLaunch):
            return ["source": source.rawValue, "first_launch": isFirstLaunch]
        case .appFirstOpened:
            return [:]
        case .appEntrypointUsed(let source, let target):
            return ["source": source.rawValue, "target": target.analyticsValue]
        case .notificationPermissionChanged(let state):
            return ["state": state.rawValue]
        case .settingChanged(let setting, let oldValue, let newValue):
            return [
                "setting_name": setting.rawValue,
                "old_value": oldValue,
                "new_value": newValue
            ]
        case .categoryOpened(let category, let source, let initialPage):
            var metadata: [String: Any] = [
                "category": category.rawValue,
                "source": source.rawValue
            ]
            if let initialPage {
                metadata["initial_page"] = initialPage
            }
            return metadata
        case .zikrOpened(let id, let language, let source):
            return [
                "zikr_id": id,
                "language": language.rawValue,
                "source": source.rawValue
            ]
        case .searchResultOpened(let id, let language, let queryLength):
            return [
                "zikr_id": id,
                "language": language.rawValue,
                "query_length": queryLength
            ]
        case .searchPerformed(let queryLength, let selectedTokenCount, let sectionCount, let resultCount):
            return [
                "query_length": queryLength,
                "selected_token_count": selectedTokenCount,
                "section_count": sectionCount,
                "result_count": resultCount,
                "has_results": resultCount > 0
            ]
        case .searchSuggestionSelected(let queryLength, let source):
            return ["query_length": queryLength, "source": source.rawValue]
        case .articleOpened(let id, let source):
            return ["article_id": id, "source": source.rawValue]
        case .articleShared(let id, let format):
            return ["article_id": id, "format": format.rawValue]
        case .zikrShared(let id, let shareType, let action):
            return [
                "zikr_id": id,
                "share_type": shareType.rawValue,
                "action": action.rawValue
            ]
        case .settingsOpened(let source, let destination):
            return ["source": source.rawValue, "destination": destination.rawValue]
        case .settingsDetailOpened(let destination):
            return ["destination": destination.rawValue]
        case .categoryCompleted(let category, let totalRepeats):
            return ["category": category.rawValue, "total_repeats": totalRepeats]
        }
    }
}
