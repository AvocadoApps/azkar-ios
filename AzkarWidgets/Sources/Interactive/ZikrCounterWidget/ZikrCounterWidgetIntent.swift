import AppIntents
import WidgetKit
import Entities

@available(iOS 17, *)
enum ZikrCounterWidgetPreferenceKey {
    static let contentLanguage = "kContentLanguage"
    static let zikrCollectionSource = "kZikrCollectionSource"
}

@available(iOS 17, *)
enum ZikrCounterTextMode: String, AppEnum {
    case original
    case translation

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "widget.next.config.displayedText")
    static var caseDisplayRepresentations: [ZikrCounterTextMode: DisplayRepresentation] = [
        .original: "widget.next.config.original",
        .translation: "widget.next.config.translation",
    ]
}

@available(iOS 17, *)
struct ZikrCounterWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "widget.next.title"
    static var description = IntentDescription("widget.next.description")

    @Parameter(title: "widget.next.config.displayedText", default: .original)
    var textMode: ZikrCounterTextMode
}

@available(iOS 17, *)
struct IncrementZikrCounterIntent: AppIntent {
    static var title: LocalizedStringResource = "widget.next.increment"
    static var description = IntentDescription("widget.next.increment.description")
    static var openAppWhenRun = false
    static var isDiscoverable = false

    @Parameter(title: "widget.next.intent.zikrID")
    var zikrID: Int

    @Parameter(title: "widget.next.intent.category")
    var categoryRawValue: String

    init() {}

    init(zikrID: Int, categoryRawValue: String) {
        self.zikrID = zikrID
        self.categoryRawValue = categoryRawValue
    }

    func perform() async throws -> some IntentResult {
        let dataSource = ZikrCounterWidgetDataSource()

        guard
            let category = ZikrCategory(rawValue: categoryRawValue),
            let counter = dataSource.counterService,
            let zikr = await dataSource.resolveZikr(id: zikrID, category: category)
        else {
            return .result()
        }

        try await counter.incrementCounter(for: zikr)

        if await dataSource.firstUncompletedZikr(in: category) == nil {
            try? await counter.markCategoryAsCompleted(category)
            dataSource.showCategorySuggestions()
        } else {
            dataSource.activateCategory(category)
        }

        ZikrCounterWidgetReloader.reloadAll()
        return .result()
    }
}

@available(iOS 17, *)
struct SelectZikrCounterCategoryIntent: AppIntent {
    static var title: LocalizedStringResource = "widget.next.title"
    static var description = IntentDescription("widget.next.description")
    static var openAppWhenRun = false
    static var isDiscoverable = false

    @Parameter(title: "widget.next.intent.category")
    var categoryRawValue: String

    init() {}

    init(categoryRawValue: String) {
        self.categoryRawValue = categoryRawValue
    }

    func perform() async throws -> some IntentResult {
        let dataSource = ZikrCounterWidgetDataSource()

        guard
            let category = ZikrCategory(rawValue: categoryRawValue),
            await dataSource.firstUncompletedZikr(in: category) != nil
        else {
            return .result()
        }

        dataSource.activateCategory(category)
        ZikrCounterWidgetReloader.reloadAll()
        return .result()
    }
}
