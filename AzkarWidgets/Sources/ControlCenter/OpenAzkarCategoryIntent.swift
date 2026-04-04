import AppIntents
import Entities

@available(iOS 18, *)
enum AzkarCategoryAppEnum: String, AppEnum {
    case morning
    case evening
    case night
    case afterSalah
    case other
    case hundredDua

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Azkar Category"

    static var caseDisplayRepresentations: [AzkarCategoryAppEnum: DisplayRepresentation] {
        [
            .morning: "Morning",
            .evening: "Evening",
            .night: "Night",
            .afterSalah: "After Salah",
            .other: "Other",
            .hundredDua: "Hundred Dua",
        ]
    }

    var zikrCategory: ZikrCategory {
        switch self {
        case .morning: .morning
        case .evening: .evening
        case .night: .night
        case .afterSalah: .afterSalah
        case .other: .other
        case .hundredDua: .hundredDua
        }
    }
}

@available(iOS 18, *)
struct OpenAzkarCategoryIntent: OpenIntent {

    static var title: LocalizedStringResource = "Open Azkar"

    @Parameter(title: "Category")
    var target: AzkarCategoryAppEnum

    init() {
        let category = contextualCategory(for: Date())
        switch category {
        case .morning: target = .morning
        case .evening: target = .evening
        case .night: target = .night
        case .afterSalah: target = .afterSalah
        case .other: target = .other
        case .hundredDua: target = .hundredDua
        }
    }

    func perform() async throws -> some IntentResult {
        let url = WidgetCategoryMetadata.deepLinkURL(for: target.zikrCategory)
        WidgetAppGroup.userDefaults.set(url.absoluteString, forKey: "controlCenterDeepLink")
        return .result()
    }
}
