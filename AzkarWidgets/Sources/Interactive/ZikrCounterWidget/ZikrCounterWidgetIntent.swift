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

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "widget.counter.config.displayedText")
    static var caseDisplayRepresentations: [ZikrCounterTextMode: DisplayRepresentation] = [
        .original: "widget.counter.config.original",
        .translation: "widget.counter.config.translation",
    ]
}

@available(iOS 17, *)
struct ZikrCounterWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "widget.counter.title"
    static var description = IntentDescription("widget.counter.description")

    @Parameter(title: "widget.counter.config.displayedText", default: .original)
    var textMode: ZikrCounterTextMode
}

@available(iOS 17, *)
struct IncrementZikrCounterIntent: AppIntent {
    static var title: LocalizedStringResource = "widget.counter.increment"
    static var description = IntentDescription("widget.counter.increment.description")
    static var openAppWhenRun = false
    static var isDiscoverable = false

    @Parameter(title: "widget.counter.intent.zikrID")
    var zikrID: Int

    @Parameter(title: "widget.counter.intent.category")
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
    static var title: LocalizedStringResource = "widget.counter.title"
    static var description = IntentDescription("widget.counter.description")
    static var openAppWhenRun = false
    static var isDiscoverable = false

    @Parameter(title: "widget.counter.intent.category")
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
