// Copyright © 2023 Azkar
// All Rights Reserved.

import SwiftUI
import Popovers
import Entities
import Library

extension ZikrCollectionSource: PickableItem {}

struct TextSettingsScreen: View {
    
    @ObservedObject var viewModel: TextSettingsViewModel
    @Environment(\.appTheme) var appTheme

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Color.clear.frame(height: 20)
                
                collectionSection
                textContentSettings
                fonts
                extraSettings
            }
        }
        .applyThemedToggleStyle()
        .scrollContentBackground(.hidden)
        .background(.background, ignoreSafeArea: .all)
        .navigationTitle("settings.text.title")
        .onAppear {
            AnalyticsReporter.reportScreen("Settings", className: viewName)
        }
    }
    
    var collectionSection: some View {
        VStack(spacing: 0) {
            HStack {
                HeaderView(text: "settings.text.adhkar_collections_source.header")
                Spacer()
                Button(
                    action: {
                        viewModel.presentZikrCollectionsOnboarding()
                    },
                    label: {
                        Image(systemName: "info.circle")
                    }
                )
                .accessibilityLabel(Text("accessibility.common.more-info"))
                .padding(.trailing)
            }
            
            PickerMenu(
                title: "settings.text.adhkar_collections_source.title",
                selection: $viewModel.preferences.zikrCollectionSource,
                items: ZikrCollectionSource.allCases,
                itemTitle: { item in
                    item.shortTitle ?? item.title
                }
            )
            .pickerStyle(.menu)
            .applyContainerStyle()
            
            FooterView(text: viewModel.preferences.zikrCollectionSource == .azkarRU
                ? "adhkar-collections.azkar-ru.description"
                : "adhkar-collections.hisn.description")
        }
    }
    
    var textContentSettings: some View {
        VStack(spacing: 0) {
            HeaderView(text: "settings.text.content.header")
            
            VStack {
                PickerMenu(
                    title: "settings.text.language",
                    selection: .init(get: {
                        viewModel.preferences.contentLanguage
                    }, set: viewModel.setContentLanguage),
                    items: viewModel.getAvailableLanguages(),
                    itemTitle: \.title
                )
                .pickerStyle(.menu)
                
                Divider()
                
                PickerMenu(
                    title: "settings.text.transliteration",
                    selection: $viewModel.preferences.transliterationType,
                    items: viewModel.availableTransliterationTypes,
                    itemTitle: { $0.title ?? String(localized: "common.default") }
                )
                .pickerStyle(.menu)
            }
            .applyContainerStyle()
        }
    }
    
    var fonts: some View {
        VStack(spacing: 0) {
            HeaderView(text: "settings.text.fonts.header")
            
            VStack {
                NavigationLink {
                    arabicFontsPicker
                } label: {
                    NavigationLabel(
                        title: "settings.text.arabic-text-font",
                        label: viewModel.preferences.preferredArabicFont.name
                    )
                }
                
                Divider()
                
                NavigationLink {
                    translationFontsPicker
                } label: {
                    NavigationLabel(
                        title: "settings.text.translation_text_font",
                        label: viewModel.preferences.preferredTranslationFont.name
                    )
                }
            }
            .applyContainerStyle()
        }
    }
    
    var extraSettings: some View {
        NavigationLink {
            ExtraTextSettingsScreen(viewModel: viewModel)
        } label: {
            NavigationLabel(title: "settings.text.extra")
        }
        .applyContainerStyle()
    }
    
    var arabicFontsPicker: some View {
        FontsView(viewModel: viewModel.getFontsViewModel(fontsType: .arabic))
    }
    
    var translationFontsPicker: some View {
        FontsView(viewModel: viewModel.getFontsViewModel(fontsType: .translation))
    }
    
}

#Preview {
    NavigationView {
        TextSettingsScreen(
            viewModel: TextSettingsViewModel(
                navigator: EmptySettingsNavigator()
            )
        )
    }
}
