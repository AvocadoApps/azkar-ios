// Copyright © 2022 Al Jawziyya. All rights reserved.

import SwiftUI
import Library
import Entities

extension ZikrShareOptionsView {

    var toolbar: some View {
        HStack(spacing: 16) {
            Button(LocalizedStringKey("common.done")) {
                dismiss()
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

                Toggle("share.show-extra-options", isOn: $showExtraOptions)
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

                        Text("share.include-azkar-logo")
                        Spacer()
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.accent)
                            .scaleEffect(isLogoOptionLocked ? 1 : 0)
                            .opacity(isLogoOptionLocked ? 1 : 0)
                            .animation(.smooth, value: isLogoOptionLocked)
                        Toggle("share.include-azkar-logo", isOn: $includeLogo)
                            .animation(.smooth, value: includeLogo)
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
                preferences: preferences,
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
        Picker(selection: $selectedBackgroundType) {
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
                Text("share.background-header")
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
            Picker("share.share-as", selection: $selectedShareType) {
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
                Toggle("share.include-title", isOn: $includeTitle)
            }
            if zikr.translation != nil {
                Toggle("share.include-original-text", isOn: $includeOriginalText.onChange { newValue in
                    if !newValue && !includeTranslation {
                        includeTranslation = true
                    }
                })
            }
            if zikr.translation != nil {
                Toggle("share.include-translation", isOn: $includeTranslation.onChange { newValue in
                    if !newValue && !includeOriginalText {
                        includeOriginalText = true
                    }
                })
            }
            if zikr.transliteration != nil {
                Toggle("share.include-transliteration", isOn: $includeTransliteration)
            }
            if zikr.benefits != nil {
                Toggle("share.include-benefit", isOn: $includeBenefits)
            }

            Toggle("settings.breaks.title", isOn: $enableLineBreaks)

            if selectedShareType != .text {
                Divider()

                HStack(spacing: 16) {
                    Text("share.text-alignment")
                    Spacer()
                    Picker("share.text-alignment", selection: $textAlignment) {
                        ForEach(alignments) { alignment in
                            Image(systemName: alignment.imageName)
                                .tag(alignment)
                        }
                    }
                }

                Divider()

                HStack(spacing: 12) {
                    Text("share.font-size")
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
