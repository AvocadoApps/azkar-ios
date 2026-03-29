//  Copyright © 2020 Al Jawziyya. All rights reserved.

import SwiftUI
import Combine
import Extensions
import Library
import Components
import WidgetKit
import Entities

/**
 This view shows contents of Zikr object:
    - title
    - text
    - transliteration and translation
    - source
 */
struct ZikrView: View {
    
    @AppStorage("kDidDisplayCounterOnboardingTip", store: UserDefaults.standard)
    var didDisplayCounterOnboardingTip: Bool?

    @ObservedObject var viewModel: ZikrViewModel
    @Environment(\.zikrReadingMode) var zikrReadingMode
    @Environment(\.appTheme) var appTheme
    @Environment(\.colorTheme) var colorTheme

    var counterFinishedCallback: Action?
    var counterTapCallback: Action?

    @State var counterFeedbackCompleted = false
    @Namespace var counterButtonAnimationNamespace
    private let counterButtonAnimationId = "counter-button"

    var sizeCategory: ContentSizeCategory {
        viewModel.preferences.sizeCategory
    }

    var dividerColor: Color {
        colorTheme.getColor(.accent, opacity: 0.1)
    }
    let dividerHeight: CGFloat = 1

    func incrementZikrCounter() {
        counterTapCallback?()
        Task {
            await viewModel.incrementZikrCount()
            WidgetCenter.reloadAzkarWidgets()
        }
        if let remainingRepeatsNumber = viewModel.remainingRepeatsNumber, remainingRepeatsNumber > 0, viewModel.preferences.enableCounterHapticFeedback {
            HapticGenerator.performFeedback(.impact(flexibility: .soft))
        }
    }
    
    var body: some View {
        if viewModel.isNested {
            scrollView
        } else {
            scrollView
                .navigationBarTitleDisplayMode(.inline)
        }
    }

    var scrollView: some View {
        ScrollView {
            getContent()
        }
        .onAppear {
            AnalyticsReporter.reportScreen("Zikr Reading", className: viewName)
        }
        .environment(\.highlightPattern, viewModel.highlightPattern)
        .onAppear {
            Task {
                await viewModel.updateRemainingRepeats()
            }
        }
        .onDisappear(perform: viewModel.pausePlayer)
        .removeSaturationIfNeeded()
        .background(.background, ignoreSafeArea: .all)
        .simultaneousGesture(
            TapGesture(count: 2)
                .onEnded { _ in
                    if viewModel.preferences.counterType == .tap {
                        incrementZikrCounter()
                    }
                }
        )
        .overlay(alignment: viewModel.preferences.counterPosition.alignment) {
            Group {
                if
                    viewModel.preferences.counterType == .floatingButton,
                    viewModel.showCounterButton,
                    let remainingRepeatNumber = viewModel.remainingRepeatsNumber,
                    remainingRepeatNumber > 0 {
                    counterButton(remainingRepeatNumber.description)
                }
            }
        }
        .onChange(of: viewModel.remainingRepeatsNumber) { number in
            if number == 0, !counterFeedbackCompleted {
                if viewModel.preferences.enableCounterHapticFeedback {
                    HapticGenerator.performFeedback(.success)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    counterFinishedCallback?()
                    counterFeedbackCompleted.toggle()
                }
            }
        }
    }
    
    @ViewBuilder func counterText(_ repeats: String) -> some View {
        if #available(iOS 16, *) {
            Text(repeats).contentTransition(.numericText())
        } else {
            Text(repeats)
        }
    }
    
    func counterButton(_ repeats: String) -> some View {
        Menu {
            Button(action: {
                resetCounter()
            }, label: {
                Label("common.reset-counter", systemImage: "arrow.counterclockwise")
            })

            Button(action: {
                completeCounter()
            }, label: {
                Label("common.complete", systemImage: "checkmark")
            })
        } label: {
            counterText(repeats)
                .font(Font.system(
                    size: viewModel.preferences.counterSize.value / 3,
                    weight: .regular,
                    design: .monospaced).monospacedDigit()
                )
                .minimumScaleFactor(0.25)
                .padding()
                .frame(
                    width: viewModel.preferences.counterSize.value,
                    height: viewModel.preferences.counterSize.value
                )
                .foregroundStyle(Color.white)
                .background(.accent)
                .clipShape(Circle())
                .glassEffectCompat(.regular.interactive(), in: Circle())
                .clipShape(Circle())
                .padding(.horizontal)
        } primaryAction: {
            incrementZikrCounter()
        }
        .frame(
            width: viewModel.preferences.counterSize.value,
            height: viewModel.preferences.counterSize.value
        )
        .matchedGeometryEffect(id: counterButtonAnimationId, in: counterButtonAnimationNamespace)
        .padding(.horizontal)
        .padding(.bottom, Constants.windowSafeAreaInsets.bottom)
        .accessibilityLabel(counterAccessibilityLabel)
        .accessibilityValue(counterAccessibilityValue(repeats))
        .accessibilityHint(Text("accessibility.zikr.counter-increment-hint"))
        .accessibilityAction(named: Text("common.reset-counter")) {
            resetCounter()
        }
        .accessibilityAction(named: Text("common.complete")) {
            completeCounter()
        }
    }

    private func getContent() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear.frame(height: 10)
            
            if let rowNumber = viewModel.rowNumber {
                Text("\(rowNumber)")
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .foregroundStyle(.secondaryText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            textContent

            infoView
            
            // MARK: - Notes
            Group {
                viewModel.zikr.notes.flatMap { _ in
                    self.getDivider()
                }

                viewModel.zikr.notes.flatMap { notes in
                    ZikrNoteView(text: notes)
                        .customFont(.body)
                }

                viewModel.zikr.benefits.flatMap { text in
                    ZikrBenefitsView(text: text)
                        .customFont(.footnote)
                }
            }

            Spacer(minLength: 20)

            ZStack(alignment: .center) {
                if viewModel.remainingRepeatsNumber == 0 {
                    LottieView(
                        name: "checkmark",
                        loopMode: .playOnce,
                        contentMode: .scaleAspectFit,
                        fillColor: colorTheme.getColor(.accent),
                        speed: 2,
                        progress: viewModel.remainingRepeatsNumber == 0 ? 0 : 1
                    )
                }
            }
            .background(
                Group {
                    if viewModel.remainingRepeatsNumber == 0 {
                        Circle()
                            .foregroundStyle(Color.clear)
                            .frame(width: 52, height: 52)
                            .matchedGeometryEffect(id: counterButtonAnimationId, in: counterButtonAnimationNamespace)
                    }
                },
                alignment: .center
            )
            .frame(height: 80, alignment: .center)
            .frame(maxWidth: .infinity)
            .opacity(viewModel.remainingRepeatsNumber == 0 ? 1 : 0)

            Spacer(minLength: 20)
        }
    }
    
    @ViewBuilder
    private var textContent: some View {
        switch zikrReadingMode {
        case .normal:
            textView
            
            if !viewModel.translation.isEmpty {
                getTranslationView(text: viewModel.translation)
                
                getDivider()
            }
            
            if !viewModel.transliteration.isEmpty {
                getTransliterationView(text: viewModel.transliteration)
                
                getDivider()
            }
            
        case .lineByLine:
            VStack(spacing: 0) {
                ForEach(Array(viewModel.text.enumerated()), id: \.0) { idx, text in
                    let translation = viewModel.translation[safe: idx]
                    let transliteration = viewModel.transliteration[safe: idx]
                    let prefs = viewModel.preferences
                    
                    Button {
                        HapticGenerator.performFeedback(.selection)
                        viewModel.playAudio(at: idx)
                    } label: {
                        VStack {
                            getReadingTextLine(
                                text,
                                isArabicText: true,
                                prefs: prefs,
                                spacing: viewModel.preferences.arabicLineAdjustment,
                                idx: idx,
                                backgroundColor: Color.systemGreen.opacity(0.1)
                            )
                            
                            if let translation, viewModel.expandTranslation {
                                getReadingTextLine(
                                    translation,
                                    isArabicText: false,
                                    prefs: prefs,
                                    spacing: viewModel.preferences.translationLineAdjustment,
                                    idx: idx,
                                    backgroundColor: Color.systemBlue.opacity(0.1)
                                )
                            }
                            
                            if let transliteration, viewModel.expandTransliteration {
                                getReadingTextLine(
                                    transliteration,
                                    isArabicText: false,
                                    prefs: prefs,
                                    spacing: viewModel.preferences.translationLineAdjustment,
                                    idx: idx,
                                    backgroundColor: Color.systemRed.opacity(0.1)
                                )
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .padding()
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(lineAccessibilityLabel(
                        index: idx,
                        arabicText: text,
                        translation: translation,
                        transliteration: transliteration
                    ))
                    .accessibilityHint(Text("accessibility.zikr.play-line-hint"))
                    
                    Divider()
                }
                
                viewModel.playerViewModel.flatMap { vm in
                    self.playerView(viewModel: vm)
                        .padding(.vertical)
                }
            }
            
        }
    }

    @ViewBuilder var repeatsNumber: some View {
        if viewModel.zikr.repeats > 0, let remainingRepeatsFormatted = viewModel.remainingRepeatsFormatted {
            getInfoStack(label: String(localized: "read.repeats"), text: remainingRepeatsFormatted)
                .onTapGesture(perform: viewModel.toggleCounterFormat)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .contextMenu {
                    Button(action: {
                        resetCounter()
                    }, label: {
                        Label("common.reset-counter", systemImage: "arrow.counterclockwise")
                    })
                }
                .animation(.smooth, value: remainingRepeatsFormatted)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(counterAccessibilityLabel)
                .accessibilityValue(counterAccessibilityValue(remainingRepeatsFormatted))
                .accessibilityAddTraits(.isButton)
                .accessibilityHint(Text("accessibility.zikr.counter-format-hint"))
                .accessibilityAction {
                    viewModel.toggleCounterFormat()
                }
                .accessibilityAction(named: Text("common.reset-counter")) {
                    resetCounter()
                }
        }
    }

}

private struct ZikrViewPreview: View {
    var theme: AppTheme
    
    var body: some View {
        let prefs = Preferences.shared
        prefs.appTheme = theme
        return ZikrView(
            viewModel: ZikrViewModel(
                zikr: Zikr.placeholder(),
                isNested: false,
                hadith: Hadith.placeholder,
                preferences: prefs,
                player: .test
            )
        )
    }
}

#Preview("Default") {
    ZikrViewPreview(theme: .code)
}

#Preview("Sea") {
    ZikrViewPreview(theme: .flat)
        .environment(\.zikrReadingMode, .lineByLine)
}

#Preview("Ink") {
    ZikrViewPreview(theme: .reader)
        .environment(\.zikrReadingMode, .lineByLine)
}

private extension ZikrView {
    var counterAccessibilityLabel: String {
        String(localized: "read.repeats")
    }

    func resetCounter() {
        Task {
            await viewModel.resetCounter()
            WidgetCenter.reloadAzkarWidgets()
        }
    }

    func completeCounter() {
        Task {
            await viewModel.completeCounter()
            WidgetCenter.reloadAzkarWidgets()
        }
    }

    func counterAccessibilityValue(_ repeats: String) -> String {
        if let remainingRepeatsNumber = viewModel.remainingRepeatsNumber, viewModel.zikr.repeats > 0 {
            return String(
                format: String(localized: "accessibility.zikr.remaining-total"),
                locale: Locale.current,
                remainingRepeatsNumber,
                viewModel.zikr.repeats
            )
        }
        return repeats
    }

    func lineAccessibilityLabel(index: Int, arabicText: String, translation: String?, transliteration: String?) -> String {
        var parts = [
            String(
                format: String(localized: "accessibility.zikr.line-number"),
                locale: Locale.current,
                index + 1
            ),
            String(localized: "accessibility.zikr.arabic-text")
        ]

        if let translation, !translation.isEmpty, viewModel.expandTranslation {
            parts.append(String(localized: "read.translation"))
        }

        if let transliteration, !transliteration.isEmpty, viewModel.expandTransliteration {
            parts.append(String(localized: "read.transcription"))
        }

        return parts.joined(separator: ", ")
    }
}
