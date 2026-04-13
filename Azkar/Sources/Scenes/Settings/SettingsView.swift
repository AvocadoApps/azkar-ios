//  Copyright © 2020 Al Jawziyya. All rights reserved.

import SwiftUI
import Popovers
import Entities
import Library
import Components

extension Language: PickableItem {}

struct SettingsView: View {
    
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.appTheme) var appTheme

    private let animationViewHeight: CGFloat = 200
        
    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack {
                    VStack {
                        VStack {
                            content
                        }
                        .applyContainerStyle()

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height)
                    .overlay(alignment: .bottom) {
                        animationView
                            .offset(y: animationViewHeight + 50)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: viewModel.navigateToAboutAppScreen) {
                    Image(systemName: "info.circle")
                }
                .accessibilityLabel(Text("about.title"))
            }
        }
        .scrollContentBackground(.hidden)
        .background(.background, ignoreSafeArea: .all)
        .navigationTitle("settings.title")
        .onAppear {
            AnalyticsReporter.reportScreen("Settings", className: viewName)
        }
    }
        
    var content: some View {
        Group {
            appearanceSection
            Divider()
            counterSection
            Divider()
            textSettingsSection
            Divider()
            remindersSection
        }
    }
        
    func getSectionButton(
        _ title: LocalizedStringKey,
        subtitle: LocalizedStringKey?,
        image: String,
        imageBackground: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 21, height: 21)
                    .font(.body)
                    .padding(7)
                    .foregroundStyle(Color.white)
                    .background(imageBackground)
                    .cornerRadius(appTheme.cornerRadius > 0 ? 8 : 0)
                    .removeSaturationIfNeeded()
                
                VStack(alignment: .leading) {
                    Text(title)
                        .foregroundStyle(.text)
                        .systemFont(.body)
                    if let subtitle {
                        Text(subtitle)
                            .foregroundStyle(.secondaryText)
                            .systemFont(.caption)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
            }
            .contentShape(Rectangle())
            .padding(4)
            .multilineTextAlignment(.leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("common.open"))
    }
    
    // MARK: - Appearance
    var appearanceSection: some View {
        getSectionButton(
            "settings.appearance.title",
            subtitle: "settings.appearance.subtitle",
            image: "paintbrush.fill",
            imageBackground: Color(.systemTeal),
            action: viewModel.navigateToAppearanceSettings
        )
    }
    
    var counterSection: some View {
        getSectionButton(
            "settings.counter.title",
            subtitle: "settings.counter.subtitle",
            image: "arrow.counterclockwise",
            imageBackground: Color(.systemIndigo),
            action: viewModel.navigateToCounterSettings
        )
    }
    
    // MARK: - Content Size
    var textSettingsSection: some View {
        getSectionButton(
            "settings.text.title",
            subtitle: "settings.text.subtitle",
            image: "bold.italic.underline",
            imageBackground: Color(.systemBlue),
            action: viewModel.navigateToTextSettings
        )
    }
    
    var remindersSection: some View {
        getSectionButton(
            "settings.reminders.title",
            subtitle: "settings.reminders.subtitle",
            image: "bell.fill",
            imageBackground: Color(.systemGreen),
            action: viewModel.navigateToRemindersSettings
        )
    }

    var animationView: some View {
        LottieView(
            name: "preferences-animation",
            loopMode: .loop,
            contentMode: .scaleAspectFit,
            speed: 0.75
        )
        .frame(height: animationViewHeight)
    }

}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView(
                viewModel: SettingsViewModel(
                    navigator: EmptySettingsNavigator()
                )
            )
        }
    }
    
}
