//
//  HadithView.swift
//  Azkar
//
//  Created by Abdurahim Jauzee on 16.05.2020.
//  Copyright © 2020 Al Jawziyya. All rights reserved.
//

import SwiftUI

struct HadithView: View {

    var viewModel: HadithViewModel

    @State private var textHeight: CGFloat = 0
    @State private var translationHeight: CGFloat = 0
    @Environment(\.appTheme) var appTheme
    @Environment(\.colorTheme) var colorTheme
    var sizeCategory: ContentSizeCategory {
        return viewModel.preferences.sizeCategory
    }

    private var dividerColor: Color {
        colorTheme.getColor(.background)
    }
    private let dividerHeight: CGFloat = 1

    var body: some View {
        ScrollView {
            getContent()
                .padding()
        }
        .onAppear {
            AnalyticsReporter.reportScreen("Hadith View", className: viewName)
        }
        .background(colorTheme.getColor(.background).ignoresSafeArea())
    }

    private func getContent() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            textView

            viewModel.translation.flatMap { text in
                translationView(text: text)
            }

            VStack(alignment: .leading, spacing: 0) {
                Text("read.narrated-by", comment: "Hadith narrater name label.")
                    .systemFont(.caption2, modification: .smallCaps)
                    .foregroundStyle(.tertiaryText)
                Text(viewModel.source)
                    .systemFont(.caption, weight: .medium, modification: .smallCaps)
                    .foregroundStyle(.text)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private func getDivider() -> some View {
        dividerColor.frame(height: dividerHeight)
    }

    // MARK: - Text
    private var textView: some View {
        CollapsableSection(
            text: viewModel.text,
            highlightPattern: viewModel.highlightPattern,
            isArabicText: true,
            isExpanded: .constant(true),
            font: viewModel.preferences.preferredArabicFont,
            lineSpacing: viewModel.preferences.arabicLineAdjustment,
            accessibilityLanguage: "ar"
        )
    }

    // MARK: - Translation
    private func translationView(text: String) -> some View {
        CollapsableSection(
            title: nil,
            text: text,
            highlightPattern: viewModel.highlightPattern,
            isArabicText: false,
            isExpanded: .constant(true),
            font: viewModel.preferences.preferredTranslationFont,
            lineSpacing: viewModel.preferences.translationLineAdjustment,
            accessibilityLanguage: viewModel.preferences.contentLanguage.id
        )
    }

}

struct HadithView_Previews: PreviewProvider {
    static var previews: some View {
        HadithView(viewModel: HadithViewModel(
            hadith: Hadith.placeholder,
            highlightPattern: "Text",
            preferences: Preferences.shared
        ))
    }
}
