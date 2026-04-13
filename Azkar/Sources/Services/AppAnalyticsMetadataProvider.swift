import Foundation
import UIKit

struct AppAnalyticsMetadataProvider {

    private let preferences: Preferences
    private let subscriptionManager: SubscriptionManagerType
    private let defaults: UserDefaults

    init(
        preferences: Preferences,
        subscriptionManager: SubscriptionManagerType = SubscriptionManagerFactory.create(),
        defaults: UserDefaults = .standard
    ) {
        self.preferences = preferences
        self.subscriptionManager = subscriptionManager
        self.defaults = defaults
    }

    func metadata() -> [String: Any] {
        [
            "app_version": appVersion,
            "build_number": buildNumber,
            "os_version": UIDevice.current.systemVersion,
            "device_idiom": deviceIdiom,
            "content_language": preferences.contentLanguage.rawValue,
            "interface_language": Locale.preferredLanguages.first ?? Locale.current.identifier,
            "is_pro_user": subscriptionManager.isProUser(),
            "days_since_first_open": daysSinceFirstOpen
        ]
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
    }

    private var deviceIdiom: String {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return "iphone"
        case .pad:
            return "ipad"
        case .mac:
            return "mac"
        case .tv:
            return "tv"
        case .carPlay:
            return "carplay"
        case .unspecified:
            return "unspecified"
        @unknown default:
            return "unknown"
        }
    }

    private var daysSinceFirstOpen: Int {
        let firstOpenDate = ensureFirstOpenDate()
        return Calendar.current.dateComponents([.day], from: firstOpenDate, to: Date()).day ?? 0
    }

    private func ensureFirstOpenDate() -> Date {
        if let date = defaults.object(forKey: Keys.firstOpenDate) as? Date {
            return date
        }

        let date = Date()
        defaults.set(date, forKey: Keys.firstOpenDate)
        return date
    }

}
