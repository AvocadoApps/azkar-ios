import SwiftUI
import WidgetKit

@available(iOS 16, *)
struct CompletionCircleView: View {
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
    
    var strokeWidth: CGFloat {
        var width: CGFloat = 10
        if widgetFamily == .accessoryCircular {
            width = 5
        }
        if progressValue == 0 {
            width /= 2
        }
        return width
    }
    
    var imagePadding: CGFloat {
        switch widgetFamily {
        case .accessoryCircular: return 15
        case .systemSmall: return 25
        default: return 30
        }
    }
    
    var completionCircle: some View {
        ZStack {
            // Background circle that shows progress
            Circle()
                .stroke(lineWidth: strokeWidth)
                .opacity(0.3)
                .foregroundColor(.gray)
            
            // Progress circle based on completion state
            Circle()
                .trim(from: 0, to: progressValue)
                .stroke(style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                .foregroundColor(circleColor)
                .rotationEffect(.degrees(-90))
            
            // Icon that changes based on completion state
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
            return 1.0 // Full completion when both morning and evening are done
        } else if completionState.contains(.morning) || completionState.contains(.evening) {
            return 0.5 // Half completion when either morning or evening is done
        } else {
            return 0.0
        }
    }
    
    private var circleColor: Color {
        if (completionState.contains(.morning) && completionState.contains(.evening)) || completionState == .all {
            return .blue
        } else if completionState.contains(.morning) || completionState.contains(.evening) || completionState.contains(.night) {
            return .green // Either morning or evening
        } else {
            return .gray // No completion
        }
    }
    
    private var iconColor: Color {
        if widgetFamily == .accessoryCircular {
            return Color.primary
        }
        if (completionState.contains(.morning) && completionState.contains(.evening)) || completionState == .all {
            return .blue
        } else if completionState.contains(.morning) || completionState.contains(.evening) {
            return .green // Both morning and evening
        } else {
            return .primary // Default color
        }
    }
}
