import SwiftUI

struct CollapsableView<Header: View, Content: View>: View {

    @Binding var isExpanded: Bool
    @ViewBuilder let header: () -> Header
    @ViewBuilder let content: () -> Content
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: isExpanded ? 10 : 0) {
            Button(action: {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                isExpanded.toggle()
            }, label: {
                header()
            })
            .buttonStyle(BorderlessButtonStyle())
            .zIndex(1)

            ZStack {
                if isExpanded {
                    Group {
                        content()
                    }
                    .clipped()
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .zIndex(0)
        }
        .clipped()
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: isExpanded)
    }

}

@available(iOS 17, *)
#Preview {
    @Previewable @State var isExpanded = false
    
    CollapsableView(
        isExpanded: $isExpanded,
        header: {
            Text("Test")
        },
        content: {
            Text(Zikr.placeholder().text)
        }
    )
}
