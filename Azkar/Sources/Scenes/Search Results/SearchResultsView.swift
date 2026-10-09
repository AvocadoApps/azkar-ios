import SwiftUI
import Extensions
import Components

struct SearchResultsView: View {
    
    @Environment(\.appTheme) var appTheme
    @ObservedObject var viewModel: SearchResultsViewModel
    var onSelect: (SearchResultZikr) -> Void

    var body: some View {
        content
            .customScrollContentBackground()
            .background(.background, ignoreSafeArea: .all)
            .onAppear {
                AnalyticsReporter.reportScreen("AzkarSearch", className: viewName)
            }
    }
    
    @ViewBuilder
    var content: some View {
        if viewModel.isPerformingSearch {
            VStack {
                LottieView(
                    name: "search",
                    loopMode: .loop,
                    contentMode: .scaleAspectFit,
                    speed: 1.0
                )
                .frame(height: 100)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.haveSearchResults == false {
            VStack {
                LottieView(
                    name: "no-search-results",
                    loopMode: .playOnce,
                    contentMode: .scaleAspectFit,
                    speed: 1.0
                )
                .frame(height: 150)
                Text("common.no-search-results")
                    .systemFont(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondaryText)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            searchResultsList
        }
    }
    
    var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.searchResults) { section in
                    searchResultSectionView(section)
                }
            }
            .padding(.vertical)
        }
        .automaticKeyboardDismissing()
    }
    
    func searchResultSectionView(_ section: SearchResultsSection) -> some View {
        Section {
            VStack(spacing: 0) {
                ForEach(Array(section.results.enumerated()), id: \.element.id) { index, result in
                    searchResultView(for: result)
                    if index != section.results.count - 1 {
                        Divider()
                    }
                }
            }
            .foregroundStyle(.text)
            .background(.contentBackground)
            .applyTheme()
            .padding(.horizontal)
            .padding(.bottom, 8)
        } header: {
            HStack {
                if let image = section.image {
                    Image(systemName: image)
                        .accessibilityHidden(true)
                }
                if let title = section.title {
                    Text(title)
                        .systemFont(.title3, modification: .smallCaps)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 4)
            .foregroundStyle(.secondaryText)
        }
    }
 
    func searchResultView(for result: SearchResultZikr) -> some View {
        Button {
            onSelect(result)
        } label: {
            SearchResultsItemView(result: result)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text("accessibility.common.open-dhikr"))
    }
    
}

#Preview("Search Results") {
    NavigationView {
        SearchResultsView(
            viewModel: SearchResultsViewModel.placeholder,
            onSelect: { _ in }
        )
    }
}
