import WidgetKit
import Entities
import AzkarServices

struct VirtuesWidgetProvider: TimelineProvider {
    private var fadail: [Fadl]

    init(databaseService: AdhkarDatabaseService) {
        fadail = (try? databaseService.getFadail(language: nil)) ?? []
        if fadail.isEmpty {
            fadail = (try? databaseService.getFadail(language: databaseService.language.fallbackLanguage)) ?? []
        }
    }

    func placeholder(in context: Context) -> VirtuesWidgetEntry {
        VirtuesWidgetEntry(date: Date(), fadl: getRandomVirtue())
    }

    func getSnapshot(in context: Context, completion: @escaping (VirtuesWidgetEntry) -> Void) {
        completion(VirtuesWidgetEntry(date: Date(), fadl: getRandomVirtue()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VirtuesWidgetEntry>) -> Void) {
        var entries: [VirtuesWidgetEntry] = []
        let currentDate = Date()

        for (index, fadl) in fadail.shuffled().enumerated() {
            let entryDate = Calendar.current.date(byAdding: .minute, value: (index + 1) * 15, to: currentDate)!
            entries.append(VirtuesWidgetEntry(date: entryDate, fadl: fadl))
        }

        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func getRandomVirtue() -> Fadl {
        fadail.randomElement() ?? Fadl.placeholder
    }
}
