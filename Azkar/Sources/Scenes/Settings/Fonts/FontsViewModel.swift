// Copyright © 2021 Al Jawziyya. All rights reserved. 

import SwiftUI
import Combine
import Entities
import Library

final class FontsViewModel: ObservableObject {
    
    let sampleText: String
    @Published var didLoadData = false
    @Published var fonts: [FontsSection] = [
        FontsSection(
            type: .appFont(TranslationFont.FontType.serif),
            fonts: [TranslationFont.placeholder, TranslationFont.placeholder, TranslationFont.placeholder].map { AppFontViewModel(font: $0, language: Language.getSystemLanguage()) }
        ),
        FontsSection(
            type: .appFont(TranslationFont.FontType.sansSerif),
            fonts: [TranslationFont.placeholder, TranslationFont.placeholder].map { AppFontViewModel(font: $0, language: Language.getSystemLanguage()) }
        ),
        FontsSection(
            type: .appFont(TranslationFont.FontType.handwritten),
            fonts: [TranslationFont.placeholder, TranslationFont.placeholder, TranslationFont.placeholder].map { AppFontViewModel(font: $0, language: Language.getSystemLanguage()) }
        ),
        FontsSection(
            type: .appFont(TranslationFont.FontType.decorative),
            fonts: [TranslationFont.placeholder].map { AppFontViewModel(font: $0, language: Language.getSystemLanguage()) }
        ),
    ]
    @Published var preferredFont: AppFont
    @Published var loadingFonts = Set<UUID>()
    
    struct FontsSection: Equatable, Identifiable {
        
        enum FontsSectionType: Equatable {
            
            static func == (lhs: FontsViewModel.FontsSection.FontsSectionType, rhs: FontsViewModel.FontsSection.FontsSectionType) -> Bool {
                switch (lhs, rhs) {
                case (.stantard, .stantard):
                    return true
                case (.appFont(let lhsStyle), .appFont(let rhsStyle)):
                    return lhsStyle.key == rhsStyle.key
                default:
                    return false
                }
            }
            
            case stantard
            case appFont(AppFontStyle)
            
            var id: String {
                switch self {
                case .stantard:
                    return "standard"
                case .appFont(let style):
                    return style.key
                }
            }
            
            init(from fontStyle: AppFontStyle) {
                self = .appFont(fontStyle)
            }
            
            var title: String {
                return NSLocalizedString("fonts.type.\(id)", comment: "")
            }
        }
        
        var id: String { type.id }
        let type: FontsSectionType
        let fonts: [AppFontViewModel]
    }
    
    private let service: FontsServiceType
    private let preferences: Preferences
    private let subscriptionManager: SubscriptionManagerType
    private let subscribeScreenTrigger: () -> Void
    private var cancellables = Set<AnyCancellable>()
    let fontsType: FontsType
    
    init(
        sampleText: String,
        fontsType: FontsType,
        service: FontsServiceType,
        preferences: Preferences = Preferences.shared,
        subscriptionManager: SubscriptionManagerType = SubscriptionManagerFactory.create(),
        subscribeScreenTrigger: @escaping () -> Void
    ) {
        self.sampleText = sampleText
        self.fontsType = fontsType
        self.service = service
        self.preferences = preferences
        self.subscriptionManager = subscriptionManager
        self.subscribeScreenTrigger = subscribeScreenTrigger
        preferences
            .storageChangesPublisher()
            .receive(on: RunLoop.main)
            .sink(receiveValue: objectWillChange.send)
            .store(in: &cancellables)
        if fontsType == .arabic {
            preferredFont = preferences.preferredArabicFont
        } else {
            preferredFont = preferences.preferredTranslationFont
        }
    }
    
    @MainActor func changeSelectedFont(_ font: AppFontViewModel) async {
        @Sendable func setFont() {
            preferredFont = font.font
            if fontsType == .arabic {
                preferences.setPreferredArabicFont(font: font.font)
            } else {
                preferences.setPreferredTranslationFont(font: font.font)
            }
        }
        
        if font.zipFileURL != nil, subscriptionManager.isProUser() == false {
            subscribeScreenTrigger()
            return
        }
        
        if let url = font.zipFileURL, isFontInstalled(font) == false {
            loadingFonts.insert(font.id)
            do {
                let fileURLs = try await service.loadFont(url: url)
                FontsHelper.registerFonts(fileURLs)
                loadingFonts.remove(font.id)
                setFont()
            } catch {
                loadingFonts.remove(font.id)
            }
        } else {
            setFont()
        }
    }
    
    func hasAccessToFont(_ font: AppFont) -> Bool {
        return font.isStandartPackFont == true || subscriptionManager.isProUser()
    }
    
    private func isFontInstalled(_ font: AppFontViewModel) -> Bool {
        guard let url = font.zipFileURL else {
            return true
        }
        let folderURL = FileManager.default.fontsDirectoryURL.appendingPathComponent(url.deletingPathExtension().lastPathComponent)
        return FileManager.default.fileExists(atPath: folderURL.path)
    }
    
    func loadData() {
        Task(priority: TaskPriority.userInitiated) {
            do {
                try await loadFonts()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    private func loadFonts() async throws {
        let showNonCyrillicFonts = preferences.contentLanguage != .russian
        let isArabicFonts = fontsType == .arabic
        let fonts: [AppFont]
        if isArabicFonts {
            let arabicFonts: [ArabicFont] = try await service.loadFonts(of: .arabic)
            fonts = arabicFonts
        } else {
            let translationFonts: [TranslationFont] = try await service.loadFonts(of: .translation)
            fonts = translationFonts
        }
        DispatchQueue.main.async {
            let standardFonts = self.fontsType == .arabic ? ArabicFont.standardFonts : TranslationFont.standardFonts
            let grouped = Dictionary(grouping: fonts, by: \.style.key)
            var sections = grouped.keys.sorted(by: { $0 < $1 })
                .compactMap { style -> FontsSection? in
                    let fonts = grouped[style] ?? []
                    guard let style = fonts.first?.style else {
                        return nil
                    }
                    let fontViewModels = fonts
                        .filter { font in
                            if !isArabicFonts && !showNonCyrillicFonts, let translationFont = font as? TranslationFont {
                                return translationFont.supportsCyryllicCharacters
                            }
                            return true
                        }
                        .map { font in
                            AppFontViewModel(font: font, language: self.preferences.contentLanguage)
                        }
                    return FontsSection(type: FontsSection.FontsSectionType(from: style), fonts: fontViewModels)
                }
            sections.insert(FontsSection(
                type: .stantard,
                fonts: standardFonts.map { font in
                    AppFontViewModel(font: font, language: self.preferences.contentLanguage)
                }
            ), at: 0)
            self.fonts = sections
            self.didLoadData = true
        }
    }
    
    static var placeholder: FontsViewModel {
        FontsViewModel(
            sampleText: "С именем Аллаха",
            fontsType: .translation,
            service: DemoFontsService(),
            subscribeScreenTrigger: {}
        )
    }
    
}
