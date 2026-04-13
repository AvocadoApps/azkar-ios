import SwiftUI

struct FooterView: View {
    let text: LocalizedStringKey
    var body: some View {
        Text(text)
            .systemFont(.caption)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(.secondaryText)
            .padding(.horizontal)
            .background(.background)
            .padding(.horizontal)
            .padding(.bottom)
    }
}
