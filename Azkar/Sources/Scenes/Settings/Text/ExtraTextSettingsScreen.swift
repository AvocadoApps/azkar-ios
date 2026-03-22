// Copyright © 2023 Azkar
// All Rights Reserved.

import SwiftUI
import Popovers
import Entities
import Library

struct ExtraTextSettingsScreen: View {
    
    @ObservedObject var viewModel: TextSettingsViewModel
    @Environment(\.colorTheme) var colorTheme
    
    var body: some View {
        ScrollView {
            VStack {
                content
            }
            .applyContainerStyle()
        }
        .applyThemedToggleStyle()
        .customScrollContentBackground()
        .background(.background, ignoreSafeArea: .all)
    }
    
    var content: some View {
        Group {
            Toggle(isOn: .init(get: {
                return viewModel.selectedArabicFontSupportsVowels ? viewModel.preferences.showTashkeel : false
            }, set: { newValue in
                viewModel.preferences.showTashkeel = newValue
            })) {
                Text("settings.text.show-tashkeel")
                    .padding(.vertical, 8)
                    .systemFont(.body)
            }
            .disabled(!viewModel.selectedArabicFontSupportsVowels)
            
            Divider()

            Toggle(isOn: $viewModel.preferences.enableLineBreaks) {
                HStack {
                    Text("settings.breaks.title")
                        .systemFont(.body)
                    Spacer()
                    Templates.Menu {
                        Text("settings.breaks.info")
                            .padding()
                            .cornerRadius(10)
                    } label: { _ in
                        Image(systemName: "info.circle")
                            .foregroundStyle(.accent, opacity: 0.75)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Divider()
            
            Toggle(isOn: $viewModel.preferences.useSystemFontSize.animation(.smooth)) {
                HStack {
                    Text("settings.text.use-system-font-size")
                        .systemFont(.body)
                    Spacer()
                    Templates.Menu {
                        Text("settings.text.use_system_font_size_tip")
                            .padding()
                            .cornerRadius(10)
                    } label: { _ in
                        Image(systemName: "info.circle")
                            .foregroundStyle(.accent, opacity: 0.75)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Divider()

            if viewModel.preferences.useSystemFontSize == false {
                sizePicker
                    .animation(.smooth, value: viewModel.preferences.useSystemFontSize)
                Divider()
            }
            
            lineSpacingView
            
            Divider()
            
            textDisplayModePicker
        }
    }
    
    var sizePicker: some View {
        Picker(
            selection: $viewModel.preferences.sizeCategory,
            label: Text("settings.text.font-size")
                .systemFont(.body)
                .padding(.vertical, 8)
        ) {
            ForEach(ContentSizeCategory.availableCases, id: \.title) { size in
                Text(size.name)
                    .systemFont(.body)
                    .tag(size)
            }
        }
        .pickerStyle(.segmented)
        .padding(.vertical, 8)
    }
    
    var lineSpacingView: some View {
        NavigationLink {
            List {
                Group {
                    Section("settings.text.arabic-line-spacing") {
                        lineSpacingPicker
                    }
                    Section("settings.text.translation-line-spacing") {
                        translationLineSpacingPicker
                    }
                }
                .listRowBackground(colorTheme.getColor(.contentBackground))
            }
            .customScrollContentBackground()
            .navigationBarTitle("settings.text.line-spacing")
            .background(.background, ignoreSafeArea: .all)
        } label: {
            NavigationLabel(title: "settings.text.line-spacing")
        }
    }

    var lineSpacingPicker: some View {
        Picker(
            selection: $viewModel.preferences.lineSpacing,
            label: EmptyView()
        ) {
            ForEach(LineSpacing.allCases) { height in
                Text(height.title)
                    .systemFont(.body)
                    .tag(height)
            }
        }
        .pickerStyle(.segmented)
    }

    var translationLineSpacingPicker: some View {
        Picker(
            selection: $viewModel.preferences.translationLineSpacing,
            label: EmptyView()
        ) {
            ForEach(LineSpacing.allCases) { height in
                Text(height.title)
                    .systemFont(.body)
                    .tag(height)
            }
        }
        .pickerStyle(.segmented)
    }
    
    var textDisplayModePicker: some View {
        NavigationLink {
            ZikrReadingModeSelectionScreen(
                zikr: viewModel.readingModeSampleZikr ?? Zikr.placeholder(),
                mode: $viewModel.preferences.zikrReadingMode,
                player: .test
            )
            .navigationTitle("settings.text.reading_mode.title")
        } label: {
            NavigationLabel(title: "settings.text.reading_mode.title")
        }
    }
    
}

#Preview {
    NavigationView {
        ExtraTextSettingsScreen(
            viewModel: TextSettingsViewModel(router: .empty)
        )
    }
}
