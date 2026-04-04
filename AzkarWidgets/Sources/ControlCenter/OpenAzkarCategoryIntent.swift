import AppIntents
import Entities

@available(iOS 18, *)
struct OpenAzkarCategoryIntent: AppIntent {

    static var title: LocalizedStringResource = "Open Azkar"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        let category = contextualCategory(for: Date())
        let url = WidgetCategoryMetadata.deepLinkURL(for: category)
        WidgetAppGroup.userDefaults.set(url.absoluteString, forKey: "controlCenterDeepLink")
        return .result()
    }
}
