import SwiftUI
import SwiftUIX
import Entities
import Library
import Extensions

struct SearchSuggestionsView: View {
    
    @Environment(\.appTheme) var appTheme
    @ObservedObject var viewModel: SearchSuggestionsViewModel
    
    let onSearchSuggestionSelection: (String) -> Void
        
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                content
            }
        }
        .customScrollContentBackground()
        .background(.background, ignoreSafeArea: .all)
        .task {
            await viewModel.loadSuggestions()
        }
        .onAppear {
            AnalyticsReporter.reportScreen("Azkar Search", className: viewName)
        }
    }
    
    @ViewBuilder
    var content: some View {
        if viewModel.suggestedQueries.isEmpty == false {
            suggestedSearchQueriesSection
        }
        
        if viewModel.suggestedAzkar.isEmpty == false {
            suggestedAzkarSection
        }
    }
    
    var suggestedSearchQueriesSection: some View {
        Section {
            VStack(spacing: 0) {
                ForEachIndexed(viewModel.suggestedQueries) { _, position, query in
                    HStack(spacing: 0) {
                        Button {
                            onSearchSuggestionSelection(query)
                        } label: {
                            HStack {
                                Image(systemName: .magnifyingglass)
                                    .foregroundStyle(Color.secondary)
                                Text(query)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading)
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(query)
                        .accessibilityHint(Text("accessibility.search.search-hint"))

                        Button {
                            viewModel.removeRecentQuery(query)
                        } label: {
                            Image(systemName: "xmark")
                                .systemFont(.footnote)
                                .foregroundStyle(.secondaryText)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text("common.delete"))
                        .padding(.trailing, 4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if position != .last {
                        Divider()
                    }
                }
            }
            .foregroundStyle(.text)
            .background(.contentBackground)
            .applyTheme(isInteractive: false)
            .padding(.horizontal)
            .padding(.bottom, 8)
        } header: {
            headerView("search.suggested-queries")
        }
    }

    var suggestedAzkarSection: some View {
        Section {
            VStack(spacing: 0) {
                ForEachIndexed(viewModel.suggestedAzkar) { _, position, zikr in
                    let text = zikr.title ?? zikr.translation ?? zikr.text
                    Button {
                        viewModel.navigateToZikr(zikr.id)
                    } label: {
                        NavigationLabel(
                            title: LocalizedStringKey(text.prefix(50) + "..."),
                            applyVerticalPadding: false
                        )
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(text)
                    .accessibilityHint(Text("accessibility.common.open-dhikr"))
                    .applyAccessibilityLanguage(zikr.language.id)

                    if position != .last {
                        Divider()
                    }
                }
            }
            .foregroundStyle(.text)
            .background(.contentBackground)
            .applyTheme(isInteractive: false)
            .padding(.horizontal)
            .padding(.bottom, 8)
        } header: {
            headerView("search.suggested-adhkar")
        }
    }

    func headerView(_ label: LocalizedStringKey) -> some View {
        Text(label)
            .foregroundStyle(.secondaryText)
            .systemFont(.title3, modification: .smallCaps)
            .accessibilityAddTraits(.isHeader)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 4)
    }
    
}

#Preview("Search Suggestions") {
    List {
        SearchSuggestionsView(
            viewModel: .placeholder,
            onSearchSuggestionSelection: { _ in }
        )
    }
}
