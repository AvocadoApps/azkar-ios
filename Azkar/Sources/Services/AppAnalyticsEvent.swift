import Foundation
import Entities

enum AppAnalyticsEvent {
    case sessionStarted(source: String, isFirstLaunch: Bool)
    case appFirstOpened
    case appEntrypointUsed(source: String, target: String)
    case notificationPermissionChanged(state: String)
    case settingChanged(name: String, oldValue: String, newValue: String)
    case categoryOpened(category: ZikrCategory, source: String, initialPage: Int?)
    case zikrOpened(id: Zikr.ID, language: Language, source: String)
    case searchResultOpened(id: Zikr.ID, language: Language, queryLength: Int)
    case searchPerformed(
        queryLength: Int,
        selectedTokenCount: Int,
        sectionCount: Int,
        resultCount: Int
    )
    case searchSuggestionSelected(queryLength: Int, source: String)
    case articleOpened(id: Article.ID, source: String)
    case articleShared(id: Article.ID, format: String)
    case zikrShared(id: Zikr.ID, shareType: String, action: String)
    case settingsOpened(source: String, destination: String)
    case settingsDetailOpened(destination: String)
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
            return [
                "source": source,
                "first_launch": isFirstLaunch
            ]
        case .appFirstOpened:
            return [:]
        case .appEntrypointUsed(let source, let target):
            return [
                "source": source,
                "target": target
            ]
        case .notificationPermissionChanged(let state):
            return [
                "state": state
            ]
        case .settingChanged(let name, let oldValue, let newValue):
            return [
                "setting_name": name,
                "old_value": oldValue,
                "new_value": newValue
            ]
        case .categoryOpened(let category, let source, let initialPage):
            var metadata: [String: Any] = [
                "category": category.rawValue,
                "source": source
            ]
            if let initialPage {
                metadata["initial_page"] = initialPage
            }
            return metadata
        case .zikrOpened(let id, let language, let source):
            return [
                "zikr_id": id,
                "language": language.rawValue,
                "source": source
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
            return [
                "query_length": queryLength,
                "source": source
            ]
        case .articleOpened(let id, let source):
            return [
                "article_id": id,
                "source": source
            ]
        case .articleShared(let id, let format):
            return [
                "article_id": id,
                "format": format
            ]
        case .zikrShared(let id, let shareType, let action):
            return [
                "zikr_id": id,
                "share_type": shareType,
                "action": action
            ]
        case .settingsOpened(let source, let destination):
            return [
                "source": source,
                "destination": destination
            ]
        case .settingsDetailOpened(let destination):
            return [
                "destination": destination
            ]
        case .categoryCompleted(let category, let totalRepeats):
            return [
                "category": category.rawValue,
                "total_repeats": totalRepeats
            ]
        }
    }
}
