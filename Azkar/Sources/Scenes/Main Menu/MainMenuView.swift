import SwiftUI
import AudioPlayer
import UserNotifications
import Entities
import ArticleReader
import Library
import AzkarResources

private extension View {
    func applyMenuPadding() -> some View {
        self.padding(.horizontal, 20)
    }
}

struct MainMenuView: View {

    @ObservedObject var viewModel: MainMenuViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appTheme) var appTheme
    @Environment(\.colorTheme) var colorTheme
    @Environment(\.isSearching) var isSearching
    @Environment(\.dismissSearch) var dismissSearch
    @EnvironmentObject var counter: ZikrCounter

    @State private var showAd = true
    @State private var didShowBottomSheetAdThisSession = false
    @State private var showAdBottomSheet = false
    @State private var adBottomSheetHeight: CGFloat = 0
    
    private let articleCellHeight: CGFloat = 230
    private let borderWidth: CGFloat = 2
    private var borderColor: Color {
        Color.accentColor.opacity(0.5)
    }

    var body: some View {
        displayContent
            .textInputAutocapitalization(.never)
            .onAppear {
                AnalyticsReporter.reportScreen("Main Menu", className: viewName)
                if let ad = viewModel.ad, ad.presentationType == .bottomSheet, didShowBottomSheetAdThisSession == false {
                    showAdBottomSheet = true
                    didShowBottomSheetAdThisSession = true
                }
            }
            .onChange(of: viewModel.ad) { newAd in
                if let newAd, newAd.presentationType == .bottomSheet, didShowBottomSheetAdThisSession == false {
                    showAdBottomSheet = true
                    didShowBottomSheetAdThisSession = true
                }
            }
            .sheet(isPresented: $showAdBottomSheet) {
                if let ad = viewModel.ad {
                    AdBottomSheetView(
                        item: AdButtonItem(ad: ad),
                        onAction: {
                            viewModel.handleAdSelection(ad)
                            showAdBottomSheet = false
                        },
                        onDismiss: {
                            showAdBottomSheet = false
                        },
                        onDontShowAgain: {
                            viewModel.hideAd(ad, permanently: true)
                            showAdBottomSheet = false
                        }
                    )
                    .onPreferenceChange(HeightPreferenceKey.self) { height in
                        adBottomSheetHeight = height
                    }
                    .applyPresentationDetents(height: adBottomSheetHeight)
                }
            }
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            Constants.windowSafeAreaInsets = proxy.safeAreaInsets
                        }
                }
            )
    }
    
    @ViewBuilder
    var displayContent: some View {
        if isSearching {
            searchView
        } else {
            content
        }
    }
    
    var content: some View {
        ScrollView {
            VStack(spacing: 20) {
                menuContent
            }
            .padding(.vertical, 20)
        }
        .overlay(alignment: .bottom) {
            ZStack {
                if let ad = viewModel.ad, ad.presentationType != .bottomSheet {
                    adView(ad)
                }
            }
        }
        .customScrollContentBackground()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: viewModel.navigateToSettings) {
                    Image(systemName: "gear")
                }
            }
        }
        .background(
            colorTheme.getColor(.background)
                .ignoresSafeArea()
                .overlay(
                    ZStack {
                        if viewModel.enableEidBackground {
                            Image("eid_background")
                                .resizable()
                                .aspectRatio(contentMode: ContentMode.fill)
                                .edgesIgnoringSafeArea(.all)
                                .blendMode(.overlay)
                        }
                    }
                )
        )
    }
    
    @ViewBuilder private var searchView: some View {
        if viewModel.searchQuery.isEmpty {
            SearchSuggestionsView(
                viewModel: viewModel.searchSuggestionsViewModel,
                onSearchSuggestionSelection: { query in
                    viewModel.searchQuery = query
                }
            )
        } else {
            SearchResultsView(
                viewModel: viewModel.searchViewModel,
                onSelect: viewModel.naviateToSearchResult(_:)
            )
        }
    }

    @ViewBuilder
    private var menuContent: some View {
        dayNightAzkar

        otherAzkar
        
        additionalAdhkar

        if viewModel.articles.isEmpty == false {
            articlesView
        }
        
        if let ad = viewModel.ad, ad.presentationType != .bottomSheet {
            // Placeholder for proper scroll insets.
            adView(ad)
                .opacity(0)
        }
    }
    
    // MARK: - Day & Night Azkar
    private var dayNightAzkar: some View {
        Section {
            HStack(spacing: 8) {
                getMainMenuSectionView(.morning)
                
                Spacer()
                
                getMainMenuSectionView(.evening)
            }
        }
        .frame(maxWidth: .infinity)
        .applyMenuPadding()
    }
    
    private func getMainMenuSectionView(_ category: ZikrCategory) -> some View {
        getMenuButton {
            MainCategoryView(
                category: category
            )
            .frame(maxWidth: .infinity)
            .removeSaturationIfNeeded()
            .background(.contentBackground)
            .applyTheme()
        } action: {
            self.viewModel.navigateToCategory(category)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
    }
    
    // MARK: - Other Azkar
    private var otherAzkar: some View {
        VStack {
            ForEachIndexed(viewModel.otherAzkarModels) { _, position, item in
                getMenuItem(
                    item: item,
                    action: {
                        viewModel.navigateToCategory(item.category)
                    }
                )
                
                if position != .last {
                    Divider()
                }
            }
        }
        .padding()
        .removeSaturationIfNeeded()
        .background(.contentBackground)
        .applyTheme()
        .applyMenuPadding()
    }
    
    @ViewBuilder
    private var additionalAdhkar: some View {
        if let dua = viewModel.additionalAdhkar {
            VStack {
                ForEachIndexed(dua) { _, position, item in
                    getMenuItem(
                        item: item,
                        action: {
                            viewModel.navigateToZikr(item.zikr)
                        }
                    )
                    
                    if position != .last {
                        Divider()
                    }
                }
            }
            .padding()
            .removeSaturationIfNeeded()
            .background(.contentBackground)
            .applyTheme()
            .applyMenuPadding()
        }
    }
    
    private func getMenuItem(
        item: AzkarMenuType,
        flipContents: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        getMenuButton(label: {
            HStack {
                MainMenuSmallGroup(item: item, flip: flipContents)
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiaryText)
            }
        }, action: action)
    }
    
    private func getMenuButton<V: View>(
        label: () -> V,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action, label: {
            label().contentShape(Rectangle())
        })
        .buttonStyle(.plain)
    }

    private var articlesView: some View {
        TabView {
            ForEach(viewModel.articles) { article in
                Button(action: {
                    viewModel.navigateToArticle(article)
                }, label: {
                    ArticleCellView(
                        article: article,
                        imageMaxHeight: articleCellHeight
                    )
                })
                .applyTheme()
                .padding(.horizontal, 20)
            }
        }
        .frame(height: articleCellHeight + 3)
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .removeSaturationIfNeeded()
    }
    
    func adView(_ ad: Ad) -> some View {
        Group {
            if appTheme == .flat || appTheme == .reader {
                adButton(ad).applyTheme()
            } else {
                adButton(ad)
                    .clipShape(RoundedRectangle(cornerRadius: appTheme.cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: appTheme.cornerRadius)
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
            }
        }
        .applyMenuPadding()
        .removeSaturationIfNeeded()
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        ))
    }
    
    func adButton(_ ad: Ad) -> some View {
        AdButton(
            item: AdButtonItem(ad: ad),
            cornerRadius: appTheme.cornerRadius,
            onClose: {
                withAnimation(.spring) {
                    viewModel.hideAd(ad)
                }
            },
            action: {
                viewModel.handleAdSelection(ad)
            }
        )
        .onAppear {
            viewModel.sendAdImpressionEvent(ad)
        }
        .frame(maxWidth: .infinity)
    }
    
}

#Preview("Menu Default") {
    MainMenuView(
        viewModel: MainMenuViewModel.placeholder
    )
}
