import SwiftUI
import WidgetKit

@available(iOS 16, *)
struct CompletionWidgetView: View {
    let completionState: CompletionState

    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        if #available(iOS 17, *) {
            completionCircle
                .containerBackground(for: .widget) {
                    Color.clear
                }
        } else {
            completionCircle
        }
    }

    private var strokeWidth: CGFloat {
        var width: CGFloat = widgetFamily == .accessoryCircular ? 5 : 10
        if progressValue == 0 {
            width /= 2
        }
        return width
    }

    private var imagePadding: CGFloat {
        switch widgetFamily {
        case .accessoryCircular: return 15
        case .systemSmall: return 25
        default: return 30
        }
    }

    private var completionCircle: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: strokeWidth)
                .opacity(0.3)
                .foregroundColor(.gray)

            Circle()
                .trim(from: 0, to: progressValue)
                .stroke(style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                .foregroundColor(circleColor)
                .rotationEffect(.degrees(-90))

            Image("app-icon-minimal")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(imagePadding)
                .widgetAccentable()
                .foregroundStyle(iconColor)
        }
        .background(AccessoryWidgetBackground())
        .clipShape(Circle())
    }

    private var progressValue: CGFloat {
        if completionState.contains(.morning) && completionState.contains(.evening) {
            return 1.0
        }

        if completionState.contains(.morning) || completionState.contains(.evening) {
            return 0.5
        }

        return 0.0
    }

    private var circleColor: Color {
        if (completionState.contains(.morning) && completionState.contains(.evening)) || completionState == .all {
            return .blue
        }

        if completionState.contains(.morning) || completionState.contains(.evening) || completionState.contains(.night) {
            return .green
        }

        return .gray
    }

    private var iconColor: Color {
        if widgetFamily == .accessoryCircular {
            return .primary
        }

        if (completionState.contains(.morning) && completionState.contains(.evening)) || completionState == .all {
            return .blue
        }

        if completionState.contains(.morning) || completionState.contains(.evening) {
            return .green
        }

        return .primary
    }
}
