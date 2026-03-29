import Foundation
import AzkarServices
import DatabaseInteractors

enum WidgetCounterDataSource {
    static func makeCounterService() -> DatabaseZikrCounter? {
        guard let databasePath = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: WidgetAppGroup.identifier)?
            .appendingPathComponent("counter.db")
            .path
        else {
            return nil
        }

        return DatabaseZikrCounter(
            databasePath: databasePath,
            getKey: {
                let startOfDay = Calendar.current.startOfDay(for: Date())
                return Int(startOfDay.timeIntervalSince1970)
            }
        )
    }
}
