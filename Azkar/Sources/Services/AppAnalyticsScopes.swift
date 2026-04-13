import Entities

struct AppSessionAnalytics {
    let track: (AppAnalyticsEvent) -> Void

    func started(source: AppAnalyticsSource, isFirstLaunch: Bool) {
        track(.sessionStarted(source: source, isFirstLaunch: isFirstLaunch))
    }

    func firstOpened() {
        track(.appFirstOpened)
    }
}

struct AppEntrypointAnalytics {
    let track: (AppAnalyticsEvent) -> Void

    func used(source: AppAnalyticsSource, target: AppAnalyticsEntrypointTarget) {
        track(.appEntrypointUsed(source: source, target: target))
    }
}

struct AppNavigationAnalytics {
    let track: (AppAnalyticsEvent) -> Void

    func openedCategory(_ category: ZikrCategory, source: AppAnalyticsSource, initialPage: Int? = nil) {
        track(.categoryOpened(category: category, source: source, initialPage: initialPage))
    }

    func openedZikr(id: Zikr.ID, language: Language, source: AppAnalyticsSource) {
        track(.zikrOpened(id: id, language: language, source: source))
    }

    func openedArticle(id: Article.ID, source: AppAnalyticsSource) {
        track(.articleOpened(id: id, source: source))
    }
}

struct AppSearchAnalytics {
    let track: (AppAnalyticsEvent) -> Void

    func performed(
        queryLength: Int,
        selectedTokenCount: Int,
        sectionCount: Int,
        resultCount: Int
    ) {
        track(.searchPerformed(
            queryLength: queryLength,
            selectedTokenCount: selectedTokenCount,
            sectionCount: sectionCount,
            resultCount: resultCount
        ))
    }

    func openedResult(id: Zikr.ID, language: Language, queryLength: Int) {
        track(.searchResultOpened(id: id, language: language, queryLength: queryLength))
    }

    func selectedSuggestion(queryLength: Int, source: AppAnalyticsSource) {
        track(.searchSuggestionSelected(queryLength: queryLength, source: source))
    }
}

struct AppSharingAnalytics {
    let track: (AppAnalyticsEvent) -> Void

    func sharedArticle(id: Article.ID, format: AppAnalyticsArticleShareFormat) {
        track(.articleShared(id: id, format: format))
    }

    func sharedZikr(id: Zikr.ID, shareType: AppAnalyticsShareType, action: AppAnalyticsShareAction) {
        track(.zikrShared(id: id, shareType: shareType, action: action))
    }
}

struct AppSettingsAnalytics {
    let track: (AppAnalyticsEvent) -> Void

    func opened(source: AppAnalyticsSource, destination: AppAnalyticsSettingsDestination) {
        track(.settingsOpened(source: source, destination: destination))
    }

    func openedDetail(_ destination: AppAnalyticsSettingsDestination) {
        track(.settingsDetailOpened(destination: destination))
    }

    func changed(_ setting: AppAnalyticsSetting, oldValue: String, newValue: String) {
        track(.settingChanged(setting: setting, oldValue: oldValue, newValue: newValue))
    }
}

struct AppPermissionsAnalytics {
    let track: (AppAnalyticsEvent) -> Void

    func changedNotificationPermission(_ state: AppAnalyticsNotificationPermissionState) {
        track(.notificationPermissionChanged(state: state))
    }
}

struct AppCategoryAnalytics {
    let track: (AppAnalyticsEvent) -> Void

    func completed(_ category: ZikrCategory, totalRepeats: Int) {
        track(.categoryCompleted(category: category, totalRepeats: totalRepeats))
    }
}

extension AppAnalyticsTracking {
    var session: AppSessionAnalytics { AppSessionAnalytics(track: track) }
    var entrypoint: AppEntrypointAnalytics { AppEntrypointAnalytics(track: track) }
    var navigation: AppNavigationAnalytics { AppNavigationAnalytics(track: track) }
    var search: AppSearchAnalytics { AppSearchAnalytics(track: track) }
    var sharing: AppSharingAnalytics { AppSharingAnalytics(track: track) }
    var settings: AppSettingsAnalytics { AppSettingsAnalytics(track: track) }
    var permissions: AppPermissionsAnalytics { AppPermissionsAnalytics(track: track) }
    var category: AppCategoryAnalytics { AppCategoryAnalytics(track: track) }
}
