import SwiftUI
import Library

public struct CreditsScreen: View {
    
    let viewModel: CreditsViewModel
    @Environment(\.openURL) private var openURL
    @Environment(\.colorTheme) var colorTheme
    
    public init(viewModel: CreditsViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        List {
            ForEach(viewModel.sections) { section in
                Section {
                    ForEach(section.items) { item in
                        viewForItem(item)
                            .listRowBackground(colorTheme.getColor(.contentBackground))
                    }
                } header: {
                    sectionHeader(section)
                }
            }
        }
        .customScrollContentBackground()
        .background(.background, ignoreSafeArea: .all)
        .listStyle(.grouped)
        .navigationTitle("credits.title")
        .removeSaturationIfNeeded()
    }
    
    private func sectionHeader(_ section: SourceInfo.Section) -> some View {
        Text(section.title)
            .foregroundStyle(.text)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func viewForItem(_ item: SourceInfo.Item) -> some View {
        Button(action: {
            if let url = URL(string: item.link) {
                openURL(url)
            }
        }, label: {
            HStack {
                Text(item.title)
                    .foregroundStyle(.text)
                Spacer()
                Image(systemName: "arrow.up.forward")
                    .foregroundStyle(.tertiaryText)
            }
            .background(.contentBackground)
            .clipShape(Rectangle())
        })
        .buttonStyle(.plain)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
    
}

#Preview {
    CreditsScreen(
        viewModel: CreditsViewModel()
    )
}
