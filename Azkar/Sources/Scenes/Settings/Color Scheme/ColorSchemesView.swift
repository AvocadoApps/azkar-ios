// Copyright © 2021 Al Jawziyya. All rights reserved. 

import SwiftUI
import Combine
import FactoryKit
import Library

final class ColorSchemesViewModel: ObservableObject {

    @Injected(\.preferences) var preferences: Preferences
    @Injected(\.subscriptionManager) var subscriptionManager: SubscriptionManagerType

    private var cancellables = Set<AnyCancellable>()
    private let subscribeScreenTrigger: Action
    
    init(subscribeScreenTrigger: @escaping Action) {
        self.subscribeScreenTrigger = subscribeScreenTrigger
        preferences
            .storageChangesPublisher()
            .receive(on: RunLoop.main)
            .sink(receiveValue: objectWillChange.send)
            .store(in: &cancellables)
    }
    
    func setAppTheme(_ theme: AppTheme) {
        if subscriptionManager.isProUser() || theme == .default {
            preferences.appTheme = theme
        } else {
            subscribeScreenTrigger()
        }
    }
    
    func setColorTheme(_ theme: ColorTheme) {
        if subscriptionManager.isProUser() || theme == .default {
            preferences.colorTheme = theme
        } else {
            subscribeScreenTrigger()
        }
    }
    
    func setThemes(appTheme: AppTheme, colorTheme: ColorTheme) {
        guard subscriptionManager.isProUser() || (isThemeProtected(appTheme) == false && isColorThemeProtected(colorTheme) == false) else {
            subscribeScreenTrigger()
            return
        }
        preferences.appTheme = appTheme
        preferences.colorTheme = colorTheme
    }
    
    static var placeholder: ColorSchemesViewModel {
        ColorSchemesViewModel(subscribeScreenTrigger: {})
    }
    
    func isThemeProtected(_ theme: AppTheme) -> Bool {
        switch theme {
        case .default:
            return false
        default:
            return !subscriptionManager.isProUser()
        }
    }
    
    func isColorThemeProtected(_ theme: ColorTheme) -> Bool {
        switch theme {
        case .default:
            return false
        default:
            return !subscriptionManager.isProUser()
        }
    }
    
}

struct ColorSchemesView: View {
    
    @ObservedObject var viewModel: ColorSchemesViewModel
    
    @State var selectedAppTheme: AppTheme
    @State var selectedColorTheme: ColorTheme
    
    init(
        viewModel: ColorSchemesViewModel
    ) {
        self.viewModel = viewModel
        selectedAppTheme = viewModel.preferences.appTheme
        selectedColorTheme = viewModel.preferences.colorTheme
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Section {
                    ItemPickerView(
                        selection: $viewModel.preferences.theme,
                        items: Theme.allCases,
                        dismissOnSelect: false
                    )
                } footer: {
                    FooterView(text: LocalizedStringKey(viewModel.preferences.theme.description))
                }
                
                Section {
                    ItemPickerView(
                        selection: .init(get: {
                            selectedAppTheme
                        }, set: { newValue in
                            if viewModel.isThemeProtected(newValue) == false {
                                viewModel.setAppTheme(newValue)
                            }
                            selectedAppTheme = newValue
                        }),
                        items: AppTheme.enabledThemes,
                        dismissOnSelect: false,
                        isItemProtected: { _ in false }
                    )
                } header: {
                    HeaderView(text: "settings.appearance.color-theme.header")
                }
                 
                Section {
                    ItemPickerView(
                        selection: .init(get: {
                            selectedColorTheme
                        }, set: { newValue in
                            if viewModel.isColorThemeProtected(newValue) == false {
                                viewModel.setColorTheme(newValue)
                            }
                            selectedColorTheme = newValue
                        }),
                        items: ColorTheme.allCases,
                        dismissOnSelect: false,
                        isItemProtected: { _ in false }
                    )
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if themeChanged && viewModel.subscriptionManager.isProUser() == false {
                    Button(action: {
                        viewModel.setThemes(appTheme: selectedAppTheme, colorTheme: selectedColorTheme)
                    }, label: {
                        HStack {
                            if viewModel.subscriptionManager.isProUser() == false && isProItemSelected {
                                Image(systemName: "lock.fill")
                            }
                            Text("common.done")
                        }
                    })
                    .transition(.opacity)
                    .buttonStyle(.borderedProminent)
                    .animation(.smooth, value: selectedAppTheme.hashValue ^ selectedColorTheme.hashValue)
                }
            }
        }
        .customScrollContentBackground()
        .background(.background, ignoreSafeArea: .all)
        .onAppear {
            AnalyticsReporter.reportScreen("Settings", className: viewName)
        }
        .environment(\.appTheme, selectedAppTheme)
        .environment(\.colorTheme, selectedColorTheme)
    }
    
    private var isProItemSelected: Bool {
        selectedAppTheme != .default || selectedColorTheme != .default
    }
    
    private var themeChanged: Bool {
        selectedAppTheme != viewModel.preferences.appTheme || selectedColorTheme != viewModel.preferences.colorTheme
    }
        
}

#Preview("Color Schemes") {
    ColorSchemesView(viewModel: .placeholder)
}
