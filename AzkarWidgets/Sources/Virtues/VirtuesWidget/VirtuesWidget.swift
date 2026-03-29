import SwiftUI
import WidgetKit
import Entities
import AzkarServices
import DatabaseInteractors

struct VirtuesWidget: Widget {
    let kind = "AzkarVirtuesWidgets"

    @Preference(
        "kContentLanguage",
        defaultValue: Language.getSystemLanguage(),
        userDefaults: WIDGET_APP_GROUP_USER_DEFAULTS
    )
    var language: Language

    var body: some WidgetConfiguration {
        if #available(iOS 16, *) {
            configuration
                .supportedFamilies([.systemMedium, .accessoryRectangular])
        } else {
            configuration
                .supportedFamilies([.systemMedium])
        }
    }

    private var configuration: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: VirtuesWidgetProvider(
                databaseService: AdhkarSQLiteDatabaseService(language: language)
            )
        ) { entry in
            VirtuesWidgetView(fadl: entry.fadl)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .configurationDisplayName("widget.virtues.title")
        .description("widget.virtues.description")
    }
}
