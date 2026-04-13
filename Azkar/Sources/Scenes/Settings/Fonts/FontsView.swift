import SwiftUI
import NukeUI
import Nuke
import Popovers
import Library

struct FontsView: View {
    
    @StateObject var viewModel: FontsViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.colorTheme) var colorTheme
    @Environment(\.appTheme) var appTheme
    @State private var previewFont: AppFontViewModel?
    
    var sampleTextView: some View {
        VStack {
            Divider()
            
            Text(viewModel.sampleText)
                .font(Font.custom(viewModel.preferredFont.postscriptName, size: min(30, UIFont.preferredFont(forTextStyle: .title1).pointSize)))
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: appTheme.cornerRadius)
                        .fill(colorTheme.getColor(.contentBackground))
                        .shadow(color: Color.accentColor.opacity(0.25), radius: 10, x: 0, y: 0)
                )
                .padding()
        }
        .background(.background)
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.fonts) { section in
                    Section {
                        ForEachIndexed(section.fonts) { _, position, font in
                            fontView(font)
                                .padding(.horizontal)
                                .background(.contentBackground)
                                .applyTheme(indexPosition: position)
                                .padding(.horizontal)
                                .onTapGesture {
                                    Task {
                                        await viewModel.changeSelectedFont(font)
                                    }
                                    UISelectionFeedbackGenerator().selectionChanged()
                                }
                        }
                    } header: {
                        HeaderView(text: LocalizedStringKey(section.type.title))
                            .padding(.vertical, 15)
                    }
                }
                .redacted(reason: viewModel.didLoadData ? [] : .placeholder)
            }
            
            sampleTextView
                .opacity(0)
                .listRowBackground(Color.clear)
        }
        .overlay(alignment: .bottom) {
            sampleTextView
        }
        .customScrollContentBackground()
        .background(.background, ignoreSafeArea: .all)
        .onAppear(perform: viewModel.loadData)
        .navigationTitle("fonts.title")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.fontsType == .arabic {
                    Templates.Menu {
                        Text("fonts.arabic.info")
                            .foregroundStyle(Color.primary)
                            .padding()
                            .cornerRadius(10)
                    } label: { _ in
                        Image(systemName: "info")
                            .foregroundStyle(.accent)
                            .accessibilityLabel(Text("accessibility.common.more-info"))
                    }
                }
            }
        }
        .sheet(item: $previewFont) { font in
            VStack {
                Text(font.name)
                    .systemFont(.largeTitle)
                Spacer()
                
                if let imageURL = font.imageURL {
                    FontsListItemView.fontImageView(imageURL, isRedacted: false)
                        .foregroundStyle(.text)
                    
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .background(.background)
        }
        .onAppear {
            AnalyticsReporter.reportScreen("Settings", className: viewName)
        }
    }
    
    func fontView(_ vm: AppFontViewModel) -> some View {
        FontsListItemView(
            vm: vm,
            isArabicFontsType: viewModel.fontsType == .arabic,
            isLoadingFont: viewModel.loadingFonts.contains(vm.id),
            isSelectedFont: viewModel.preferredFont.id == vm.font.id,
            hasAccessToFont: viewModel.hasAccessToFont(vm.font),
            selectionCallback: {
                self.previewFont = vm
            },
            isRedacted: !viewModel.didLoadData
        )
        .fontSizeCategory(nil)
    }
    
}

struct FontsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FontsView(viewModel: .placeholder)
        }
        .preferredColorScheme(.light)
    }
}
