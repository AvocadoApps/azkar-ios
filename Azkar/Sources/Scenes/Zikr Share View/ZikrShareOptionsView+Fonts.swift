// Copyright © 2022 Al Jawziyya. All rights reserved.

import SwiftUI
import Library
import Entities

extension ZikrShareOptionsView {

    @ViewBuilder
    var fontPickers: some View {
        Group {
            if includeOriginalText {
                fontMenu(
                    title: "settings.text.arabic-text-font",
                    selection: $selectedArabicFont,
                    availableFonts: availableArabicFonts,
                    onSelect: handleArabicFontSelection
                )
            }
            if zikr.translation != nil || zikr.transliteration != nil || zikr.benefits != nil {
                fontMenu(
                    title: "settings.text.translation_text_font",
                    selection: $selectedTranslationFont,
                    availableFonts: availableTranslationFonts,
                    onSelect: handleTranslationFontSelection
                )
            }
        }
    }

    func fontMenu<T: AppFont & Identifiable & Hashable>(
        title: LocalizedStringKey,
        selection: Binding<T>,
        availableFonts: [T],
        onSelect: @escaping (T, T) -> Void
    ) -> some View {
        let proxiedSelection = Binding(
            get: { selection.wrappedValue },
            set: { newValue in
                let previousValue = selection.wrappedValue
                guard !isFontDownloading(newValue) else {
                    return
                }
                selection.wrappedValue = newValue
                onSelect(newValue, previousValue)
            }
        )

        let labelPrefixAccessory: PickerMenuAccessory? = selection.wrappedValue.isStandartPackFont != true && !subscriptionManager.isProUser() ? .image(systemName: "lock.fill", tint: Color.getColor(.accent)) : nil

        return PickerMenu(
            title: title,
            selection: proxiedSelection,
            items: availableFonts,
            itemTitle: { $0.name },
            isItemEnabled: { font in
                return !isFontDownloading(font)
            },
            labelPrefixAccessory: labelPrefixAccessory,
            labelAccessory: isFontDownloading(selection.wrappedValue) ? .progress() : nil
        )
        .disabled(isFontDownloading(selection.wrappedValue))
    }

    func handleArabicFontSelection(_ newFont: ArabicFont, previousFont: ArabicFont) {
        guard newFont != previousFont else { return }
        Task {
            let success = await ensureFontAvailable(newFont)
            await MainActor.run {
                guard selectedArabicFont == newFont else { return }
                if !success {
                    selectedArabicFont = previousFont
                } else {
                    saveArabicFont(newFont)
                }
                normalizeSelectedFonts()
            }
        }
    }

    func handleTranslationFontSelection(_ newFont: TranslationFont, previousFont: TranslationFont) {
        guard newFont != previousFont else { return }
        Task {
            let success = await ensureFontAvailable(newFont)
            await MainActor.run {
                guard selectedTranslationFont == newFont else { return }
                if !success {
                    selectedTranslationFont = previousFont
                } else {
                    saveTranslationFont(newFont)
                }
                normalizeSelectedFonts()
            }
        }
    }

    func needsDownload<T: AppFont>(_ font: T) -> Bool {
        guard fontDownloadURL(for: font) != nil else { return false }
        return !isFontInstalled(font)
    }

    @MainActor
    func synchronizeAppliedFonts() {
        let resolvedArabic = resolveAppliedFont(
            currentSelection: selectedArabicFont,
            currentApplied: appliedArabicFont,
            availableFonts: availableArabicFonts,
            defaultFont: ZikrShareOptionsView.defaultArabicFonts.first ?? appliedArabicFont
        )
        let resolvedTranslation = resolveAppliedFont(
            currentSelection: selectedTranslationFont,
            currentApplied: appliedTranslationFont,
            availableFonts: availableTranslationFonts,
            defaultFont: ZikrShareOptionsView.defaultTranslationFonts.first ?? appliedTranslationFont
        )
        if resolvedArabic != appliedArabicFont || resolvedTranslation != appliedTranslationFont {
            appliedArabicFont = resolvedArabic
            appliedTranslationFont = resolvedTranslation
        }
    }

    func resolveAppliedFont<T: AppFont & Equatable>(
        currentSelection: T,
        currentApplied: T,
        availableFonts: [T],
        defaultFont: T
    ) -> T {
        if isFontDownloading(currentSelection) {
            return currentApplied
        }
        if !needsDownload(currentSelection) {
            return currentSelection
        }
        if !needsDownload(currentApplied) {
            return currentApplied
        }
        if let installed = availableFonts.first(where: { !needsDownload($0) }) {
            return installed
        }
        return defaultFont
    }

    func mergeFonts<T: Hashable>(
        _ base: [T],
        extras: [T],
        ensuring additional: [T]
    ) -> [T] {
        var seen = Set<T>()
        var result: [T] = []

        // swiftlint:disable for_where
        for font in base {
            if seen.insert(font).inserted {
                result.append(font)
            }
        }

        for font in extras {
            if seen.insert(font).inserted {
                result.append(font)
            }
        }

        for font in additional {
            if seen.insert(font).inserted {
                result.append(font)
            }
        }
        // swiftlint:enable for_where

        return result
    }

    @MainActor
    func normalizeSelectedFonts() {
        availableArabicFonts = mergeFonts(
            availableArabicFonts,
            extras: [],
            ensuring: [selectedArabicFont]
        )

        availableTranslationFonts = mergeFonts(
            availableTranslationFonts,
            extras: [],
            ensuring: [selectedTranslationFont]
        )

        synchronizeAppliedFonts()
    }

    func isFontPro<T: AppFont>(_ font: T) -> Bool {
        font.isStandartPackFont != true
    }

    func isFontLocked<T: AppFont>(_ font: T) -> Bool {
        guard subscriptionManager.isProUser() == false else { return false }
        return isFontPro(font)
    }

    func firstUnlockedFont<T: AppFont & Equatable>(from fonts: [T], excluding target: T? = nil) -> T? {
        fonts.first { font in
            if let target = target, font == target {
                return false
            }
            return !needsDownload(font)
        }
    }

    func isFontDownloading<T: AppFont>(_ font: T) -> Bool {
        downloadingFonts.contains(font.referenceName)
    }

    func isFontInstalled<T: AppFont>(_ font: T) -> Bool {
        guard font.referenceName != STANDARD_FONT_REFERENCE_NAME else {
            return true
        }
        let folderURL = FileManager.default.fontsDirectoryURL.appendingPathComponent(font.referenceName)
        return FileManager.default.fileExists(atPath: folderURL.path)
    }

    func fontDownloadURL<T: AppFont>(for font: T) -> URL? {
        guard font.referenceName != STANDARD_FONT_REFERENCE_NAME else {
            return nil
        }
        return ZikrShareOptionsView.fontDownloadBaseURL
            .appendingPathComponent(font.referenceName)
            .appendingPathComponent("\(font.referenceName).zip")
    }

    func ensureFontAvailable<T: AppFont>(_ font: T) async -> Bool {
        if isFontInstalled(font) {
            return true
        }

        guard let downloadURL = fontDownloadURL(for: font) else {
            return true
        }

        let downloadKey = font.referenceName

        if await MainActor.run(body: { downloadingFonts.contains(downloadKey) }) {
            while await MainActor.run(body: { downloadingFonts.contains(downloadKey) }) {
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
            return isFontInstalled(font)
        }

        downloadingFonts.insert(downloadKey)
        defer {
            Task { @MainActor in
                downloadingFonts.remove(downloadKey)
            }
        }

        do {
            let fileURLs = try await fontsService.loadFont(url: downloadURL)
            await MainActor.run {
                FontsHelper.registerFonts(fileURLs)
            }
            return true
        } catch {
            print("Failed to download font \(font.name): \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Font Persistence
    func loadSavedFonts() {
        if let identifier = StoredFontIdentifier(rawValue: selectedArabicFontId),
           let savedFont: ArabicFont = fontMatching(identifier, in: availableArabicFonts) {
            selectedArabicFont = savedFont
            appliedArabicFont = savedFont
        }

        if let identifier = StoredFontIdentifier(rawValue: selectedTranslationFontId),
           let savedFont: TranslationFont = fontMatching(identifier, in: availableTranslationFonts) {
            selectedTranslationFont = savedFont
            appliedTranslationFont = savedFont
        }
    }

    func saveArabicFont(_ font: ArabicFont) {
        selectedArabicFontId = StoredFontIdentifier(font: font).rawValue
    }

    func saveTranslationFont(_ font: TranslationFont) {
        selectedTranslationFontId = StoredFontIdentifier(font: font).rawValue
    }

    @MainActor
    func loadAvailableFontsIfNeeded() async {
        normalizeSelectedFonts()

        guard fontsLoadingState == .idle else {
            normalizeSelectedFonts()
            return
        }

        fontsLoadingState = .loading

        do {
            async let remoteArabicFonts: [ArabicFont] = fontsService.loadFonts(of: .arabic)
            async let remoteTranslationFonts: [TranslationFont] = fontsService.loadFonts(of: .translation)

            let (arabicFonts, translationFonts) = try await (remoteArabicFonts, remoteTranslationFonts)

            availableArabicFonts = mergeFonts(
                ZikrShareOptionsView.defaultArabicFonts,
                extras: arabicFonts.sorted { $0.name < $1.name },
                ensuring: [selectedArabicFont]
            )

            availableTranslationFonts = mergeFonts(
                ZikrShareOptionsView.defaultTranslationFonts,
                extras: translationFonts.sorted { $0.name < $1.name },
                ensuring: [selectedTranslationFont]
            )

            normalizeSelectedFonts()
            loadSavedFonts()
            if needsDownload(selectedArabicFont) {
                let font = selectedArabicFont
                Task {
                    let success = await ensureFontAvailable(font)
                    await MainActor.run {
                        guard selectedArabicFont == font else { return }
                        if !success,
                           let fallback: ArabicFont = firstUnlockedFont(from: availableArabicFonts, excluding: font) {
                            selectedArabicFont = fallback
                        }
                        normalizeSelectedFonts()
                    }
                }
            }
            if needsDownload(selectedTranslationFont) {
                let font = selectedTranslationFont
                Task {
                    let success = await ensureFontAvailable(font)
                    await MainActor.run {
                        guard selectedTranslationFont == font else { return }
                        if !success,
                           let fallback: TranslationFont = firstUnlockedFont(from: availableTranslationFonts, excluding: font) {
                            selectedTranslationFont = fallback
                        }
                        normalizeSelectedFonts()
                    }
                }
            }

            fontsLoadingState = .loaded
        } catch {
            fontsLoadingState = .failed
            normalizeSelectedFonts()
        }
    }

    func fontMatching<T: AppFont>(_ identifier: StoredFontIdentifier, in fonts: [T]) -> T? {
        if identifier.referenceName != STANDARD_FONT_REFERENCE_NAME,
           let exactReferenceMatch = fonts.first(where: { $0.referenceName == identifier.referenceName }) {
            return exactReferenceMatch
        }

        if !identifier.postscriptName.isEmpty,
           let postscriptMatch = fonts.first(where: { $0.postscriptName == identifier.postscriptName }) {
            return postscriptMatch
        }

        if identifier.isLegacy,
           let legacyMatch = fonts.first(where: { $0.referenceName == identifier.referenceName && $0.postscriptName.isEmpty }) {
            return legacyMatch
        }

        return fonts.first(where: { $0.referenceName == identifier.referenceName })
    }

    struct StoredFontIdentifier: Equatable {
        let referenceName: String
        let postscriptName: String
        let isLegacy: Bool

        init<T: AppFont>(font: T) {
            referenceName = font.referenceName
            postscriptName = font.postscriptName
            isLegacy = false
        }

        init?(rawValue: String) {
            guard rawValue.isEmpty == false else { return nil }
            let components = rawValue.split(separator: "|", omittingEmptySubsequences: false)
            if components.count == 2 {
                referenceName = String(components[0])
                postscriptName = String(components[1])
                isLegacy = false
            } else {
                referenceName = rawValue
                postscriptName = ""
                isLegacy = true
            }
        }

        var rawValue: String {
            "\(referenceName)|\(postscriptName)"
        }
    }

    static var defaultArabicFonts: [ArabicFont] { ArabicFont.standardFonts.compactMap { $0 as? ArabicFont } }
    static var defaultTranslationFonts: [TranslationFont] { TranslationFont.standardFonts }
    static var fontDownloadBaseURL: URL { URL(string: "https://storage.yandexcloud.net/azkar/fonts/files/")! }
}
