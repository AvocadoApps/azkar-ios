// Copyright © 2022 Al Jawziyya. All rights reserved.

import SwiftUI
import AudioPlayer
import FactoryKit
import Library
import Popovers
import Entities
import AzkarResources
import Extensions

enum ShareBackgroundTypes: Hashable, Identifiable, CaseIterable {
    static var allCases: [ShareBackgroundTypes] {
        [.any] + ShareBackgroundType.allCases.map { .type($0) }
    }
    
    var id: Self { self }
    
    case any
    case type(ShareBackgroundType)
    
    var title: String {
        switch self {
        case .any: return String(localized: "share.background-type.all")
        case .type(let type): return type.title
        }
    }
}

struct ZikrShareOptionsView: View {
    
    let zikr: Zikr

    struct ShareOptions {
        enum ShareActionType {
            case sheet, saveImage, copyText
            
            var message: String? {
                switch self {
                case .saveImage:
                    return String(localized: "share.image_saved")
                case .copyText:
                    return String(localized: "share.text_copied")
                case .sheet:
                    return nil
                }
            }
            
            var imageName: String? {
                switch self {
                case .saveImage:
                    return "square.and.arrow.down"
                case .copyText:
                    return "doc.on.doc"
                case .sheet:
                    return nil
                }
            }
        }
        
        let actionType: ShareActionType
        let includeTitle: Bool
        let includeBenefits: Bool
        let includeLogo: Bool
        let includeTranslation: Bool
        let includeOriginalText: Bool
        let includeTransliteration: Bool
        var textAlignment: ZikrShareTextAlignment = .start
        let shareType: ZikrShareType
        var selectedBackground: ZikrShareBackgroundItem
        let enableLineBreaks: Bool
        let arabicFont: ArabicFont
        let translationFont: TranslationFont
        
        var containsProItem: Bool {
            if shareType == .image {
                let usesArabicFont = includeOriginalText
                let usesTranslationFont = includeTranslation || includeTransliteration || includeBenefits
                return includeLogo == false
                || selectedBackground.isProItem
                || (usesArabicFont && arabicFont.isStandartPackFont != true)
                || (usesTranslationFont && translationFont.isStandartPackFont != true)
            } else {
                return false
            }
        }
    }

    let callback: (ShareOptions) -> Void

    @EnvironmentObject var backgroundsService: ShareBackgroundsServiceType
    @Environment(\.dismiss) var dismiss
    @Environment(\.appTheme) var appTheme
    @Environment(\.colorTheme) var colorTheme
    @Injected(\.subscriptionManager) var subscriptionManager: SubscriptionManagerType
    @Injected(\.preferences) var preferences: Preferences
    @Injected(\.fontsService) var fontsService: FontsServiceType
    
    @AppStorage("kShareShowExtraOptions")
    var showExtraOptions = false

    @AppStorage("kShareIncludeTitle")
    var includeTitle: Bool = true

    @AppStorage("kShareIncludeBenefits")
    var includeBenefits = true

    @AppStorage("kShareIncludeLogo")
    var includeLogo = true

    @AppStorage("kShareIncludeTranslation")
    var includeTranslation = true

    @AppStorage("kShareIncludeOriginalText")
    var includeOriginalText = true

    @AppStorage("kShareIncludeTransliteration")
    var includeTransliteration = true

    @AppStorage("kShareShareType")
    var selectedShareType = ZikrShareType.image

    @AppStorage("kShareTextAlignment")
    var textAlignment = ZikrShareTextAlignment.start

    @AppStorage("kShareSmartLineBreaks")
    var enableLineBreaks = true

    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    @State var backgrounds = ZikrShareBackgroundItem.preset

    var visibleBackgrounds: [ZikrShareBackgroundItem] {
        switch selectedBackgroundType {
        case .any:
            return backgrounds
        case .type(let shareBackgroundType):
            return backgrounds.filter { $0.type == shareBackgroundType }
        }
    }

    @AppStorage("kShareBackground")
    var selectedBackgroundId: String?

    @State var selectedBackground: ZikrShareBackgroundItem = .defaultBackground

    @State var shareViewSize: CGSize = .zero

    @State var scrollToSelectedBackground = false

    @State var processingQuickShareAction: ShareOptions.ShareActionType?

    @State var selectedBackgroundType: ShareBackgroundTypes = .any

    @AppStorage("kShareSelectedDynamicTypeSizeIndex")
    var selectedDynamicTypeSizeIndex: Int = DynamicTypeSize.allCases.firstIndex(of: .large) ?? 0

    @State var selectedDynamicTypeSize: DynamicTypeSize = .large

    func loadSelectedDynamicTypeSize() {
        let index = max(0, min(selectedDynamicTypeSizeIndex, DynamicTypeSize.allCases.count - 1))
        selectedDynamicTypeSize = DynamicTypeSize.allCases[index]
    }

    func saveSelectedDynamicTypeSize(_ newSize: DynamicTypeSize) {
        if let index = DynamicTypeSize.allCases.firstIndex(of: newSize) {
            selectedDynamicTypeSizeIndex = index
            selectedDynamicTypeSize = newSize
        }
    }
    let alignments: [ZikrShareTextAlignment] = [.center, .start]
    @AppStorage("kShareArabicFont")
    var selectedArabicFontId: String = ""

    @AppStorage("kShareTranslationFont")
    var selectedTranslationFontId: String = ""

    @State var selectedArabicFont: ArabicFont
    @State var selectedTranslationFont: TranslationFont

    @State var appliedArabicFont: ArabicFont
    @State var appliedTranslationFont: TranslationFont

    @State var availableArabicFonts: [ArabicFont] = ZikrShareOptionsView.defaultArabicFonts
    @State var availableTranslationFonts: [TranslationFont] = ZikrShareOptionsView.defaultTranslationFonts

    @State var fontsLoadingState: FontsLoadingState = .idle
    @State var downloadingFonts: Set<String> = []
    @State var fontRefreshToken = UUID()

    enum FontsLoadingState {
        case idle, loading, loaded, failed
    }

    init(zikr: Zikr, callback: @escaping (ShareOptions) -> Void) {
        self.zikr = zikr
        self.callback = callback

        let preferences = Container.shared.preferences()
        _selectedArabicFont = State(initialValue: preferences.preferredArabicFont)
        _selectedTranslationFont = State(initialValue: preferences.preferredTranslationFont)
        _appliedArabicFont = State(initialValue: preferences.preferredArabicFont)
        _appliedTranslationFont = State(initialValue: preferences.preferredTranslationFont)
    }
            
    var body: some View {
        if #available(iOS 26, *) {
            contentWithNavigationToolbar
        } else {
            contentWithCustomToolbar
        }
    }
    
    @available(iOS 26, *)
    private var contentWithNavigationToolbar: some View {
        mainContent
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedStringKey("common.done")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    toolbarButtons
                }
            }
    }
    
    private var contentWithCustomToolbar: some View {
        VStack(spacing: 0) {
            toolbar
                .padding()
                    
            mainContent
        }
    }
    
    private var mainContent: some View {
        scrollView
            .customScrollContentBackground()
            .applyThemedToggleStyle()
            .background(.background, ignoreSafeArea: .all)
            .ignoresSafeArea(edges: selectedShareType == .image ? .bottom : [])
            .task {
                if zikr.translation == nil {
                    includeOriginalText = true
                }
                await loadAvailableFontsIfNeeded()
                loadSelectedDynamicTypeSize()
                do {
                    for try await remoteImageBackgrounds in backgroundsService.loadBackgrounds() {
                        backgrounds = ZikrShareBackgroundItem.preset + remoteImageBackgrounds
                        
                        if let selectedBackgroundId = selectedBackgroundId,
                           let foundBackground = backgrounds.first(where: { $0.id == selectedBackgroundId }) {
                            selectedBackground = foundBackground
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            scrollToSelectedBackground = true
                        }
                    }
                } catch {
                    print(error)
                }
            }
    }
    
    var toolbarButtons: some View {
        HStack(spacing: 16) {
            Button(action: {
                Task {
                    await performAction(actionType: selectedShareType == .image ? .saveImage : .copyText)
                }
            }, label: {
                Image(systemName: selectedShareType == .image ? "square.and.arrow.down" : "doc.on.doc")
            })
            .disabled(processingQuickShareAction != nil)
            .opacity(processingQuickShareAction != nil ? 0.5 : 1)
            
            Button(action: {
                Task {
                    share(actionType: .sheet)
                }
            }, label: {
                Text("common.share")
            })
        }
    }

    private var isUnavailableOptionSelected: Bool {
        isProShareOptionsSelected && !subscriptionManager.isProUser()
    }
    
    private var usesTranslationFont: Bool {
        (includeTranslation && zikr.translation != nil)
        || (includeTransliteration && zikr.transliteration != nil)
        || (includeBenefits && zikr.benefits != nil)
    }
    
    private var isProShareOptionsSelected: Bool {
        guard selectedShareType == .image else { return false }
        return selectedBackground.isProItem
        || !includeLogo
        || (includeOriginalText && isFontPro(selectedArabicFont))
        || (usesTranslationFont && isFontPro(selectedTranslationFont))
    }
    
    @MainActor
    private func share(actionType: ShareOptions.ShareActionType = .sheet) {
        callback(ShareOptions(
            actionType: actionType,
            includeTitle: includeTitle,
            includeBenefits: includeBenefits,
            includeLogo: includeLogo,
            includeTranslation: includeTranslation,
            includeOriginalText: includeOriginalText,
            includeTransliteration: includeTransliteration,
            textAlignment: textAlignment,
            shareType: selectedShareType,
            selectedBackground: selectedBackground,
            enableLineBreaks: enableLineBreaks,
            arabicFont: appliedArabicFont,
            translationFont: appliedTranslationFont
        ))
    }
    
    @MainActor
    private func performAction(actionType: ShareOptions.ShareActionType) async {
        // Perform the share action
        share(actionType: actionType)
        
        guard subscriptionManager.isProUser() || !isProShareOptionsSelected else {
            return
        }
        
        // Show feedback
        withAnimation {
            processingQuickShareAction = actionType
        }
        
        // Wait 3 seconds before enabling the button again
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        
        withAnimation {
            processingQuickShareAction = nil
        }
    }

}

#Preview("Share Options") {
    ZikrShareOptionsView(zikr: .placeholder(), callback: { _ in })
        .tint(Color.accentColor)
        .environmentObject(MockShareBackgroundsService())
}
