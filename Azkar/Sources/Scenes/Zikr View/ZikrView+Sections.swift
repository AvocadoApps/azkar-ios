// Copyright © 2020 Al Jawziyya. All rights reserved.

import SwiftUI
import Library
import Components
import Extensions

extension ZikrView {

    // MARK: - Title
    func titleView(_ title: String) -> some View {
        Text(title)
            .equatable()
            .systemFont(.headline)
            .foregroundStyle(.secondaryText)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
    }

    @ViewBuilder
    func getReadingTextView(
        text: [String],
        isArabicText: Bool
    ) -> some View {
        let prefs = viewModel.preferences
        let spacing = isArabicText ? prefs.arabicLineAdjustment : prefs.translationLineAdjustment
        let lines = Array(zip(text.indices, text))
        VStack(spacing: spacing) {
            ForEach(lines, id: \.0) { idx, line in
                let label = getReadingTextLine(
                    line,
                    isArabicText: isArabicText,
                    prefs: prefs,
                    spacing: spacing,
                    idx: idx,
                    backgroundColor: Color.accentColor.opacity(0.15)
                )
                if viewModel.preferences.enableLineBreaks {
                    Button(action: {
                        HapticGenerator.performFeedback(.selection)
                        viewModel.playAudio(at: idx)
                    }, label: {
                        label
                    })
                    .buttonStyle(.plain)
                } else {
                    label
                }
            }
        }
    }

    func getReadingTextLine(
        _ line: String,
        isArabicText: Bool,
        prefs: Preferences,
        spacing: CGFloat,
        idx: Int,
        backgroundColor: Color = Color.clear
    ) -> some View {
        ReadingTextView(
            text: line,
            highlightPattern: viewModel.highlightPattern,
            isArabicText: isArabicText,
            font: isArabicText ? prefs.preferredArabicFont : prefs.preferredTranslationFont,
            lineSpacing: prefs.enableLineBreaks ? spacing : 0
        )
        .background(
            Group {
                if idx == viewModel.indexToHighlight, viewModel.highlightCurrentIndex {
                    backgroundColor
                        .padding(-10)
                        .cornerRadius(6)
                }
            }
        )
        .frame(maxWidth: .infinity, alignment: isArabicText ? .trailing : .leading)
    }

    // MARK: - Text
    var textView: some View {
        VStack(spacing: 10) {
            getReadingTextView(text: viewModel.text, isArabicText: true)
                .id(viewModel.textSettingsToken)
                .padding([.leading, .trailing, .bottom])

            viewModel.playerViewModel.flatMap { vm in
                self.playerView(viewModel: vm)
            }
        }
    }

    // MARK: - Translation
    func getTranslationView(text: [String]) -> some View {
        CollapsableView(
            isExpanded: .init(get: {
                viewModel.expandTranslation
            }, set: { newValue in
                withAnimation(Animation.spring()) {
                    viewModel.preferences.expandTranslation = newValue
                }
            }),
            header: {
                CollapsableSectionHeaderView(
                    title: "read.translation",
                    isExpanded: viewModel.expandTranslation,
                    isExpandable: true
                )
            },
            content: {
                getReadingTextView(text: text, isArabicText: false)
            }
        )
        .id(viewModel.textSettingsToken)
        .padding()
    }

    // MARK: - Transliteration
    func getTransliterationView(text: [String]) -> some View {
        CollapsableView(
            isExpanded: .init(get: {
                viewModel.expandTransliteration
            }, set: { newValue in
                withAnimation(Animation.spring()) {
                    viewModel.preferences.expandTransliteration = newValue
                }
            }),
            header: {
                CollapsableSectionHeaderView(
                    title: "read.transcription",
                    isExpanded: viewModel.expandTransliteration,
                    isExpandable: true
                )
            },
            content: {
                getReadingTextView(text: text, isArabicText: false)
            }
        )
        .id(viewModel.textSettingsToken)
        .padding()
    }

    // MARK: - Info
    var infoView: some View {
        HStack(alignment: .center) {
            if #available(iOS 16, *) {
                repeatsNumber.contentTransition(.numericText())
            } else {
                repeatsNumber
            }

            viewModel.source?.textOrNil.flatMap { text in
                NavigationLink(destination: hadithView, label: {
                    getInfoStack(
                        label: String(localized: "read.source"),
                        text: text,
                        underline: viewModel.hadithViewModel != nil
                    )
                    .hoverEffect(HoverEffect.highlight)
                })
                .accessibilityIdentifier("zikr_source_link")
                .disabled(viewModel.hadithViewModel == nil)
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
        }
        .systemFont(.caption)
        .padding(.vertical, 10)
    }

    var hadithView: some View {
        LazyView(
            ZStack {
                if let vm = viewModel.hadithViewModel {
                    HadithView(viewModel: vm)
                }
            }
        )
    }

    func getInfoStack(label: String, text: String, underline: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            getCaption(label)
            Text(getAttributedString(text))
                .if(underline) { text in
                    text.underline()
                }
                .foregroundStyle(.text)
                .systemFont(.caption, weight: .medium, modification: .smallCaps)
        }
    }

    func getDivider() -> some View {
        dividerColor.frame(height: dividerHeight)
    }

    func getCaption(_ text: String) -> some View {
        Text(getAttributedString(text))
            .systemFont(.caption2, modification: .smallCaps)
            .foregroundStyle(.tertiaryText)
    }

    func getAttributedString(_ text: String) -> AttributedString {
        attributedString(text, highlighting: viewModel.highlightPattern)
    }

    func playerView(viewModel: PlayerViewModel) -> some View {
        PlayerView(
            viewModel: viewModel,
            progressBarHeight: dividerHeight
        )
        .equatable()
    }
}
