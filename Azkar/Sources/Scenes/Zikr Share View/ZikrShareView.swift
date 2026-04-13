// Copyright © 2022 Al Jawziyya. All rights reserved. 

import SwiftUI
import NukeUI
import Nuke
import Library
import Entities

extension TextAlignment {
    var frameAlignment: Alignment {
        switch self {
        case .leading:
            return .leading
        case .trailing:
            return .trailing
        case .center:
            return .center
        }
    }
}

struct ZikrShareView: View {

    let viewModel: ZikrViewModel
    var includeTitle = true
    var includeOriginalText = true
    var includeTranslation = true
    var includeTransliteration = false
    var includeBenefits = true
    var includeLogo = true
    var includeSource = false
    var arabicTextAlignment = TextAlignment.trailing
    var otherTextAlignment = TextAlignment.leading
    var nestIntoScrollView = true
    var useFullScreen = true
    var selectedBackground: ZikrShareBackgroundItem
    var enableLineBreaks = true

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @Environment(\.appTheme) var appTheme
    @Environment(\.colorTheme) var colorTheme
    @Environment(\.arabicFont) var arabicFont
    @State private var dynamicColorScheme: ColorScheme?

    // New computed property to check if background is an image
    private var isBackgroundImage: Bool {
        switch selectedBackground.type {
        case .color:
            return false
        case .pattern, .image:
            return true
        }
    }
    
    var body: some View {
        container
            .ignoresSafeArea()
            .environment(\.colorScheme, customColorScheme)
            .onAppear {
                AnalyticsReporter.reportScreen("Zikr Share", className: viewName)
            }
            .onChange(of: selectedBackground) { _ in
                dynamicColorScheme = nil
            }
    }
    
    @ViewBuilder
    var container: some View {
        if nestIntoScrollView {
            ScrollView {
                content
            }
        } else {
            content
        }
    }
    
    var customColorScheme: ColorScheme {
        dynamicColorScheme ?? colorScheme
    }
    
    var backgroundForContent: some View {
        Group {
            switch selectedBackground.background {
            case .solidColor(let color):
                Color(color)
            case .localImage(let image):
                renderImage(image)
            case .remoteImage(let item):
                if useFullScreen, let cachedImage = getCachedImage(for: item.url) {
                    renderImage(cachedImage)
                } else {
                    LazyImage(url: item.url) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .scaledToFill()
                                .onAppear {
                                    if let color = state.imageContainer?.image.dominantColor() {
                                        dynamicColorScheme = isDarkColor(color) ? .dark : .light
                                    }
                                }
                        } else {
                            ZStack {
                                if state.isLoading {
                                    ProgressView()
                                }
                            }
                        }
                    }
                }
            }
        }
        .id(selectedBackground)
    }
    
    // New method to render image with common logic
    private func renderImage(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .onAppear {
                if let color = image.dominantColor() {
                    dynamicColorScheme = isDarkColor(color) ? .dark : .light
                }
            }
    }
    
    // New method to check for cached images
    private func getCachedImage(for url: URL) -> UIImage? {
        let request = ImageRequest(url: url)
        let cachedContainer = ImagePipeline.shared.cache.cachedImage(for: request)
        return cachedContainer?.image
    }

    // Helper function to determine if a color is dark
    private func isDarkColor(_ color: UIColor) -> Bool {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Calculate luminance (perceived brightness)
        // Using the formula: 0.299*R + 0.587*G + 0.114*B
        let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
        
        // If luminance is less than 0.5, it's considered a dark color
        return luminance < 0.5
    }

    var content: some View {
        VStack(spacing: 16) {
            if #available(iOS 26, *) {
                textContainer
                    .padding(4)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: appTheme.cornerRadius))
            } else {
                textContainer
            }

            if includeLogo {
                VStack {
                    if let image = UIImage(named: "ink-icon", in: resourcesBundle, compatibleWith: nil) {
                        Image(uiImage: image)
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 25, height: 25)
                            .cornerRadius(6)
                    }
                    Text("share.shared-with-azkar")
                        .font(Font.system(size: 8, weight: .regular, design: .rounded).smallCaps())
                }
                .foregroundStyle(.text)
                .opacity(0.5)
                .padding(8)
                .glassEffectCompat(.regular, in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(.horizontal, 25)
        .padding(.vertical, 30)
        .frame(
            maxWidth: .infinity,
            minHeight: useFullScreen ? UIScreen.main.bounds.height : 100
        )
        .background(backgroundForContent)
    }

    var textContainer: some View {
        VStack(spacing: 16) {
            if includeTitle, let title = viewModel.title {
                Text(title)
            }

            VStack(spacing: 0) {
                if includeOriginalText {
                    let baseText = enableLineBreaks
                        ? viewModel.zikr.text
                        : viewModel.zikr.text.replacingOccurrences(of: "\n", with: " ")
                    
                    // Trim tashkeel if the font doesn't support it
                    let processedText = arabicFont.hasTashkeelSupport ? baseText : baseText.trimmingArabicVowels
                    
                    Text(.init(processedText))
                        .customFont(.title1, isArabic: true)
                        .frame(maxWidth: .infinity, alignment: arabicTextAlignment.frameAlignment)
                        .multilineTextAlignment(arabicTextAlignment)
                        .padding()
                }

                if includeTranslation {
                    if includeOriginalText {
                        Divider()
                    }

                    if let translationText = viewModel.zikr.translation {
                        let processedTranslation = enableLineBreaks
                            ? translationText
                            : translationText.replacingOccurrences(of: "\n", with: " ")
                        Text(processedTranslation)
                            .customFont(.body)
                            .multilineTextAlignment(otherTextAlignment)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: otherTextAlignment.frameAlignment)
                    }
                }

                if includeTransliteration, let transliterationText = viewModel.zikr.transliteration {
                    Divider()

                    let processedTransliteration = enableLineBreaks
                        ? transliterationText
                        : transliterationText.replacingOccurrences(of: "\n", with: " ")
                    Text(processedTransliteration)
                        .customFont(.body)
                        .multilineTextAlignment(.leading)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: otherTextAlignment.frameAlignment)
                }

                if includeBenefits, let text = viewModel.zikr.benefits?.textOrNil {
                    Divider()

                    ZikrBenefitsView(text: text)
                        .customFont(.footnote)
                        .frame(maxWidth: .infinity, alignment: otherTextAlignment.frameAlignment)
                }

                if includeSource, let source = viewModel.source?.textOrNil {
                    Text(source)
                        .customFont(.caption1)
                        .frame(maxWidth: .infinity, alignment: otherTextAlignment.frameAlignment)
                        .foregroundStyle(.secondaryText)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                }
            }
            .background {
                if isBackgroundImage {
                    if #unavailable(iOS 26) {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                    }
                } else {
                    colorTheme.getColor(.contentBackground)
                }
            }
            .cornerRadius(appTheme.cornerRadius)
            .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.1), radius: 5, x: 0, y: 1)
        }
    }

}

@available(iOS 17, *)
#Preview("Default background") {
    ZikrShareView(
        viewModel: ZikrViewModel(
            zikr: Zikr.placeholder(),
            isNested: true,
            hadith: Hadith.placeholder,
            preferences: Preferences.shared,
            player: Player.test
        ),
        selectedBackground: .defaultBackground
    )
}

@available(iOS 17, *)
#Preview("Remote image") {
    ZikrShareView(
        viewModel: ZikrViewModel(
            zikr: Zikr.placeholder(),
            isNested: true,
            hadith: Hadith.placeholder,
            preferences: Preferences.shared,
            player: Player.test
        ),
        selectedBackground: .init(
            id: "1",
            background: .remoteImage(ShareBackground(id: 1, type: .image, url: URL(string: "https://images.unsplash.com/photo-1760570317577-fa68f4738373?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=1370")!, previewUrl: nil)),
            type: .image
        )
    )
}
