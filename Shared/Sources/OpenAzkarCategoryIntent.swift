import AppIntents

private let appGroupDefaults = UserDefaults(suiteName: "group.io.jawziyya.azkar-app")

@available(iOS 18, *)
struct OpenAzkarCategoryIntent: AppIntent {

    static var title: LocalizedStringResource = "Open Azkar"
    static var openAppWhenRun = true
    static var isDiscoverable = true

    @available(iOS 26.0, *)
    static var supportedModes: IntentModes {
        .foreground
    }

    func perform() async throws -> some IntentResult {
        let hour = Calendar.current.component(.hour, from: Date())
        let categoryRawValue: String
        switch hour {
        case 4..<15: categoryRawValue = "morning"
        case 15..<20: categoryRawValue = "evening"
        default: categoryRawValue = "night"
        }
        appGroupDefaults?.set("azkar://category/\(categoryRawValue)", forKey: "controlCenterDeepLink")
        return .result()
    }
}
