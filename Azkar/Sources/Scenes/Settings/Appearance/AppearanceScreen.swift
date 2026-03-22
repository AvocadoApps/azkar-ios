import SwiftUI
import Popovers
import Library

struct AppearanceScreen: View {
    
    @ObservedObject var viewModel: AppearanceViewModel
    
    var body: some View {
        ScrollView {
            VStack {
                content
            }
            .applyContainerStyle()
        }
        .customScrollContentBackground()
        .background(.background, ignoreSafeArea: .all)
        .navigationTitle("settings.appearance.title")
        .onAppear {
            AnalyticsReporter.reportScreen("Settings", className: viewName)
        }
    }
    
    var content: some View {
        Group {
            PickerView(
                label: "settings.appearance.app-theme.title",
                subtitle: viewModel.themeTitle,
                destination: themePicker
            )
            
            Divider()

            if viewModel.canChangeIcon {
                PickerView(
                    label: "settings.icon.title",
                    subtitle: viewModel.preferences.appIcon.title,
                    destination: iconPicker
                )
                
                Divider()
            }

            Toggle(isOn: $viewModel.preferences.enableFunFeatures) {
                HStack {
                    Text("settings.use_fun_features")
                        .systemFont(.body)
                        .foregroundStyle(.text)
                    Spacer()
                    
                    Templates.Menu {
                        Text("settings.use_fun_features_tip")
                            .padding()
                            .cornerRadius(10)
                    } label: { _ in
                        Image(systemName: "info.circle")
                            .foregroundStyle(.accent, opacity: 0.75)
                    }
                }
                .padding(.vertical, 8)
            }
            .applyThemedToggleStyle()
        }
    }
    
    var themePicker: some View {
        ColorSchemesView(viewModel: viewModel.colorSchemeViewModel)
    }

    var iconPicker: some View {
        AppIconPackListView(viewModel: viewModel.appIconPackListViewModel)
    }
    
}

#Preview("Appearance View") {
    NavigationView {
        AppearanceScreen(
            viewModel: AppearanceViewModel(
                router: .empty
            )
        )
    }
}
