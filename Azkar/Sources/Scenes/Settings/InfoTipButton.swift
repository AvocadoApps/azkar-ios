import SwiftUI
import Library

/// A small info button that shows a short explanation of a setting.
///
/// The tip is a system popover anchored by UIKit. The Popovers library menu used
/// before did not open when tapped on the pushed settings screens.
struct InfoTipButton: View {

    private let text: LocalizedStringKey
    @State private var isPresented = false

    init(_ text: LocalizedStringKey) {
        self.text = text
    }

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Image(systemName: "info.circle")
                .foregroundStyle(.accent, opacity: 0.75)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("accessibility.common.more-info"))
        .modifier(InfoTipPresentation(text: text, isPresented: $isPresented))
    }
}

private struct InfoTipPresentation: ViewModifier {

    let text: LocalizedStringKey
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content.popover(isPresented: $isPresented) {
                Text(text)
                    .systemFont(.callout)
                    .foregroundStyle(.text)
                    .padding()
                    .frame(width: 300)
                    .fixedSize(horizontal: false, vertical: true)
                    .presentationCompactAdaptation(.popover)
            }
        } else {
            // Before iOS 16.4 a popover on iPhone becomes a full sheet.
            content.alert(Text(text), isPresented: $isPresented) {}
        }
    }
}
