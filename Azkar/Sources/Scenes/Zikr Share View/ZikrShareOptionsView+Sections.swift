// Copyright © 2022 Al Jawziyya. All rights reserved.

import SwiftUI
import Library
import Entities

extension ZikrShareOptionsView {

    var toolbar: some View {
        HStack(spacing: 16) {
            Button(L10n.Common.done) {
                presentation.dismiss()
            }
            Spacer()

            toolbarButtons
        }
        .systemFont(.title3)
        .animation(.smooth, value: includeLogo.hashValue ^ selectedBackground.hashValue)
        .animation(.smooth, value: processingQuickShareAction)
    }

    var scrollView: some View {
        ScrollView {
            content
        }
        .showToast(
            message: processingQuickShareAction?.message ?? "",
            icon: processingQuickShareAction?.imageName,
            tint: processingQuickShareAction == .saveImage ? .green : colorTheme.getColor(.accent),
            isPresented: processingQuickShareAction != nil
        )
    }

    var content: some View {
        VStack {
            VStack {
                Color.clear.frame(height: 10)

                shareAsSection

                Divider()

                Toggle(L10n.Share.showExtraOptions, isOn: $showExtraOptions)
                    .padding(.horizontal, 16)

                if showExtraOptions {
                    shareOptions
                        .padding(.horizontal, 16)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                if selectedShareType != .text {
                    Divider()

                    HStack {
                        let isLogoOptionLocked = !includeLogo && !subscriptionManager.isProUser()

                        Text(L10n.Share.includeAzkarLogo)
                        Spacer()
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.accent)
                            .scaleEffect(isLogoOptionLocked ? 1 : 0)
                            .opacity(isLogoOptionLocked ? 1 : 0)
                            .animation(.smooth, value: isLogoOptionLocked)
                        Toggle(L10n.Share.includeAzkarLogo, isOn: $includeLogo.animation(.smooth))
                            .labelsHidden()
                    }
                    .padding(.horizontal, 16)

                    Divider()
                } else {
                    Color.clear.frame(height: 10)
                }
            }
            .background(.contentBackground)
            .applyTheme()
            .padding()

            if selectedShareType != .text {
                backgroundPickerSection
                    .padding(.vertical)

                shareViewPreviewContainer
            }
        }
        .systemFont(.body)
        .animation(.smooth, value: showExtraOptions)
        .animation(.smooth, value: selectedBackground)
    }

    var shareViewPreviewContainer: some View {
        ZStack {
            shareViewPreview
                .frame(width: shareViewSize.width, height: shareViewSize.height)
                .screenshotProtected(isProtected: selectedBackground.isProItem && !subscriptionManager.isProUser())
                .background {
                    if selectedBackground.isProItem && !subscriptionManager.isProUser() {
                        VStack(alignment: .center) {
                            Spacer()
                            Image(systemName: "lock.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                                .foregroundStyle(.accent)
                            Spacer()
                        }
                    }
                }
                .animation(.smooth, value: selectedBackground.isProItem)
                .animation(.smooth, value: subscriptionManager.isProUser())

            shareViewPreview
                .opacity(0)
                .getViewBoundsGeometry { proxy in
                    shareViewSize = proxy.size
                }
        }
        .transition(.opacity)
    }

    var shareViewPreview: some View {
        ZikrShareView(
            viewModel: ZikrViewModel(
                zikr: zikr,
                isNested: true,
                hadith: nil,
                preferences: Preferences.shared,
                player: .test
            ),
            includeTitle: includeTitle,
            includeOriginalText: includeOriginalText,
            includeTranslation: includeTranslation,
            includeTransliteration: includeTransliteration,
            includeBenefits: includeBenefits,
            includeLogo: includeLogo,
            includeSource: false,
            arabicTextAlignment: textAlignment.isCentered ? .center : .trailing,
            otherTextAlignment: textAlignment.isCentered ? .center : .leading,
            nestIntoScrollView: false,
            useFullScreen: false,
            selectedBackground: selectedBackground,
            enableLineBreaks: enableLineBreaks
        )
        .environment(\.dynamicTypeSize, selectedDynamicTypeSize)
        .environment(\.arabicFont, appliedArabicFont)
        .environment(\.translationFont, appliedTranslationFont)
        .clipShape(RoundedRectangle(cornerRadius: appTheme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: appTheme.cornerRadius).stroke(Color.accentColor.opacity(0.5), lineWidth: 1)
        )
        .allowsHitTesting(false)
    }

    var backgroundTypePicker: some View {
        Picker(selection: $selectedBackgroundType.animation(.smooth)) {
            ForEach(ShareBackgroundTypes.allCases) { item in
                Text(item.title)
                    .tag(item)
            }
        } label: {
            EmptyView()
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    var backgroundPickerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.Share.backgroundHeader)
                    .foregroundStyle(.secondaryText)
                    .systemFont(.subheadline, modification: .smallCaps)
                    .padding(.horizontal, 16)

                backgroundTypePicker
                    .padding(.horizontal, 16)

                ZikrShareBackgroundPickerView(
                    backgrounds: visibleBackgrounds,
                    selectedBackground: Binding(
                        get: { self.selectedBackground },
                        set: { newValue in
                            self.selectedBackground = newValue
                            if !newValue.isProItem || subscriptionManager.isProUser() {
                                self.selectedBackgroundId = newValue.id
                            }
                        }
                    ),
                    scrollToSelection: $scrollToSelectedBackground
                )
                .frame(height: 80)
            }
        }
    }

    var shareAsSection: some View {
        Section {
            Picker(L10n.Share.shareAs, selection: $selectedShareType.animation(.smooth)) {
                ForEach(ZikrShareType.allCases) { type in
                    Label(type.title, systemImage: type.imageName)
                        .tag(type)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 16)
        }
    }

    var shareOptions: some View {
        Section {
            if zikr.title != nil {
                Toggle(L10n.Share.includeTitle, isOn: $includeTitle)
            }
            if zikr.translation != nil {
                Toggle(L10n.Share.includeOriginalText, isOn: $includeOriginalText.onChange { newValue in
                    if !newValue && !includeTranslation {
                        includeTranslation = true
                    }
                })
            }
            if zikr.translation != nil {
                Toggle(L10n.Share.includeTranslation, isOn: $includeTranslation.onChange { newValue in
                    if !newValue && !includeOriginalText {
                        includeOriginalText = true
                    }
                })
            }
            if zikr.transliteration != nil {
                Toggle(L10n.Share.includeTransliteration, isOn: $includeTransliteration)
            }
            if zikr.benefits != nil {
                Toggle(L10n.Share.includeBenefit, isOn: $includeBenefits)
            }

            Toggle(L10n.Settings.Breaks.title, isOn: $enableLineBreaks)

            if selectedShareType != .text {
                Divider()

                HStack(spacing: 16) {
                    Text(L10n.Share.textAlignment)
                    Spacer()
                    Picker(L10n.Share.textAlignment, selection: $textAlignment) {
                        ForEach(alignments) { alignment in
                            Image(systemName: alignment.imageName)
                                .tag(alignment)
                        }
                    }
                }

                Divider()

                HStack(spacing: 12) {
                    Text(L10n.Share.fontSize)
                    Spacer()
                    fontSizeButton(false, isDisabled: selectedDynamicTypeSize == DynamicTypeSize.allCases.first)
                    fontSizeButton(true, isDisabled: selectedDynamicTypeSize == DynamicTypeSize.allCases.last)
                }

                fontPickers
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    func fontSizeButton(_ increasing: Bool, isDisabled: Bool) -> some View {
        Button(action: {
            let direction = increasing ? 1 : -1
            if let current = DynamicTypeSize.allCases.firstIndex(of: selectedDynamicTypeSize) {
                let newIndex = current + direction
                if newIndex >= 0 && newIndex < DynamicTypeSize.allCases.count {
                    saveSelectedDynamicTypeSize(DynamicTypeSize.allCases[newIndex])
                }
            }
        }, label: {
            ZStack {
                // Placeholder for sizing.
                Image(systemName: "plus")
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                    .opacity(0)

                Image(systemName: increasing ? "plus" : "minus")
            }
            .font(.title3)
            .foregroundStyle(.white)
            .background(.accent)
            .clipShape(Capsule())
            .grayscale(isDisabled ? 1 : 0)
            .glassEffectCompat(.regular.interactive(), in: Capsule())
        })
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}
