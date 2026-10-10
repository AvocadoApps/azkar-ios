import SwiftUI
import Library

struct CounterView: View {
    
    @ObservedObject var viewModel: CounterViewModel
    
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
        .navigationTitle("settings.counter.title")
        .animation(.smooth, value: viewModel.preferences.counterType)
    }
    
    var content: some View {
        Group {
            typePicker
            
            Divider()
            
            if viewModel.preferences.counterType == .floatingButton {
                HStack {
                    Text("settings.counter.counter-size.title")
                    Spacer()
                    Picker(
                        CounterSize.allCases,
                        id: \.self,
                        selection: $viewModel.preferences.counterSize,
                        content: { size in
                            Text(size.title)
                        }
                    )
                    .pickerStyle(.segmented)
                }
                
                Divider()
                
                HStack {
                    Text("settings.counter.counter-position.title")
                    Spacer()
                    Picker(
                        CounterPosition.allCases,
                        id: \.self,
                        selection: $viewModel.preferences.counterPosition,
                        content: { size in
                            Text(size.title)
                        }
                    )
                    .pickerStyle(.segmented)
                }
                
                Divider()
            }

            Toggle("settings.counter.counter-ticker", isOn: $viewModel.preferences.enableCounterTicker)
                .padding(.vertical, 3)

            Divider()
            
            Toggle("settings.counter.counter-haptics", isOn: $viewModel.preferences.enableCounterHapticFeedback)
                .padding(.vertical, 3)

            Divider()

            HStack(spacing: 12) {
                HStack {
                    Text("settings.counter.go-to-next-dhikr")

                    InfoTipButton("settings.counter.go-to-next-dhikr-tip")
                }
                Spacer()

                Toggle("", isOn: $viewModel.preferences.enableGoToNextZikrOnCounterFinished)
                    .labelsHidden()
                    .accessibilityLabel(Text("settings.counter.go-to-next-dhikr"))
            }
            .padding(.vertical, 3)
        }
        .systemFont(.body)
        .foregroundStyle(.text)
        .onAppear {
            AnalyticsReporter.reportScreen("Settings", className: viewName)
        }
    }
    
    private var typePicker: some View {
        HStack {
            Text("settings.counter.counter-type.title")
            Spacer()

            InfoTipButton("settings.counter.counter-type.info")

            Picker(
                CounterType.allCases,
                id: \.self,
                selection: $viewModel.preferences.counterType,
                content: { type in
                    Text(type.title)
                }
            )
            .pickerStyle(.segmented)
        }
        .padding(.vertical, 3)
    }

}

#Preview {
    CounterView(
        viewModel: CounterViewModel(
            navigator: EmptySettingsNavigator()
        )
    )
}
