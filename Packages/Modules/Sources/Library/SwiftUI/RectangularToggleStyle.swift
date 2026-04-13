import SwiftUI

public struct RectangularToggleStyle: ToggleStyle {
    let showProBadge: Bool
    
    public init(showProBadge: Bool = false) {
        self.showProBadge = showProBadge
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            Button {
                configuration.isOn.toggle()
            } label: {
                ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                    Rectangle()
                        .fill(configuration.isOn ? Color.accentColor : Color.gray)
                        .frame(width: 45, height: 30)
                    
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 20, height: 20)
                        .padding(5)
                        .overlay(alignment: .center) {
                            if showProBadge {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.accent)
                                    .padding(2)
                            }
                        }
                }
                .animation(.smooth, value: configuration.isOn)
            }
            .buttonStyle(.plain)
        }
        .hapticFeedback(.impact(flexibility: .soft), trigger: configuration.isOn)
    }
}

private struct ApplyRectangularToggleStyle: ViewModifier {
    @Environment(\.appTheme) var appTheme
    let showProBadge: Bool
    
    init(showProBadge: Bool = false) {
        self.showProBadge = showProBadge
    }
    
    func body(content: Content) -> some View {
        if appTheme.cornerRadius == 0 {
            content.toggleStyle(.rectangular(showProBadge: showProBadge))
        } else {
            content.toggleStyle(.switch)
        }
    }
}

extension View {
    public func applyThemedToggleStyle(showProBadge: Bool = false) -> some View {
        modifier(ApplyRectangularToggleStyle(showProBadge: showProBadge))
    }
}

extension ToggleStyle where Self == RectangularToggleStyle {
    public static var rectangular: RectangularToggleStyle {
        RectangularToggleStyle()
    }
    
    public static func rectangular(showProBadge: Bool) -> RectangularToggleStyle {
        RectangularToggleStyle(showProBadge: showProBadge)
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var isOn = true
    VStack {
        Toggle("Regular Toggle", isOn: $isOn)
            .toggleStyle(RectangularToggleStyle())
            .padding()
        
        Toggle("Pro Feature Toggle", isOn: $isOn)
            .toggleStyle(RectangularToggleStyle(showProBadge: true))
            .padding()
    }
}
