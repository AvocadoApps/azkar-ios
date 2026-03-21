import SwiftUI

struct FooterView: View {
    let text: String
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
