import SwiftUI
import WidgetKit
import Entities
import AzkarServices
import DatabaseInteractors

@available(iOS 16, *)
struct AzkarVirtuesWidgetPreview: PreviewProvider {
    static var previews: some View {
        let databaseService = AdhkarSQLiteDatabaseService(language: Language.getSystemLanguage())
        let fadail = try! databaseService.getFadail()

        Group {
            VirtuesWidgetView(fadl: fadail.randomElement() ?? .placeholder)
                .previewContext(WidgetPreviewContext(family: .systemMedium))

            VirtuesWidgetView(fadl: fadail.randomElement() ?? .placeholder)
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
        }
    }
}
