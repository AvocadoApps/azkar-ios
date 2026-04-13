import SwiftUI
import WidgetKit
import Entities

@available(iOS 18, *)
struct AzkarControlCenterWidget: ControlWidget {

    let kind = "AzkarControlCenter"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: kind) {
            let category = contextualCategory(for: Date())
            let imageName = WidgetCategoryMetadata.controlCenterImageName(for: category)

            ControlWidgetButton(action: OpenAzkarCategoryIntent()) {
                Label(
                    WidgetCategoryMetadata.localizedTitle(for: category),
                    image: imageName
                )
            }
        }
        .displayName(LocalizedStringResource("widget.control.azkar.title", bundle: .atURL(Bundle.main.bundleURL)))
        .description(LocalizedStringResource("widget.control.azkar.description", bundle: .atURL(Bundle.main.bundleURL)))
    }
}
