import SwiftUI
import WidgetKit
import Entities

struct VirtuesWidgetView: View {
    let fadl: Fadl

    @Environment(\.widgetFamily) private var family

    var body: some View {
        if #available(iOS 17, *) {
            content
                .containerBackground(for: .widget) {
                    Color("WidgetBackground")
                }
        } else if #available(iOS 16, *) {
            content
        } else {
            content
                .shadow(color: Color.primary.opacity(0.5), radius: 0.5, x: 0, y: 0.05)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryRectangular:
            Text(fadl.text + "\n" + fadl.source)
                .minimumScaleFactor(0.1)
        case .systemMedium:
            VStack(spacing: 8) {
                Text(fadl.text)
                    .font(.title3)
                    .tracking(1.2)
                    .foregroundStyle(Color.primary.opacity(0.7))
                    .minimumScaleFactor(0.5)

                Text(fadl.source)
                    .font(.caption)
                    .foregroundStyle(Color.secondary.opacity(0.5))
            }
            .multilineTextAlignment(.center)
            .padding()
        default:
            Color.red
        }
    }
}
