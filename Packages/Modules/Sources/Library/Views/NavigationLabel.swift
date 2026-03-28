import SwiftUI

public struct NavigationLabel: View {
    let title: LocalizedStringKey
    let label: String?
    let applyVerticalPadding: Bool
    
    public init(
        title: LocalizedStringKey,
        label: String? = nil,
        applyVerticalPadding: Bool = true
    ) {
        self.title = title
        self.label = label
        self.applyVerticalPadding = applyVerticalPadding
    }
    
    public var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.text)
                .multilineTextAlignment(.leading)
            Spacer()
            if let label {
                Text(label)
                    .foregroundStyle(.secondaryText)
                    .multilineTextAlignment(.trailing)
                    .systemFont(.callout)
            }
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondaryText)
                .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
        .systemFont(.body)
        .padding(.vertical, applyVerticalPadding ? 8 : 0)
        .accessibilityElement(children: .combine)
    }
    
}

#Preview {
    NavigationLabel(title: "Arabic Font", label: "Adobe")
}
