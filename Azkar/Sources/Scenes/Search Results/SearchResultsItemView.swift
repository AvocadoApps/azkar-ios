import SwiftUI
import Extensions

struct SearchResultsItemView: View {
    
    let result: SearchResultZikr
    @Environment(\.colorTheme) var colorTheme

    var accessibilitySummary: String {
        [
            result.title,
            result.text,
            result.translation,
            result.caption,
            result.caption2,
            result.footnote,
            result.language.title
        ]
        .compactMap { summaryPart($0) }
        .joined(separator: ", ")
    }
    
    var body: some View {
        HStack(alignment: .top) {
            content
            Spacer()
            Text(result.language.id)
                .textCase(.uppercase)
                .font(Font.system(size: 12, design: .monospaced))
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(.secondaryBackground)
                .foregroundStyle(.secondaryText)
                .cornerRadius(3)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .applyAccessibilityLanguage(result.language.id)
    }
    
    var content: some View {
        VStack(spacing: 10) {
            if let title = result.title {
                Text(getText(title))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let text = result.text {
                Text(getText(text))
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            if let translation = result.translation {
                Text(getText(translation))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let caption = result.caption {
                Text(getText(caption))
                    .systemFont(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let caption2 = result.caption2 {
                Text(getText(caption2))
                    .systemFont(.caption2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let footnote = result.footnote {
                Text(getText(footnote))
                    .systemFont(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .systemFont(.body)
        .foregroundStyle(.text)
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.leading)
    }
    
    private func getText(
        _ text: String
    ) -> AttributedString {
        var attributedString = AttributedString(text)
        var currentSearchRange = attributedString.startIndex..<attributedString.endIndex

        while let range = attributedString[currentSearchRange].range(of: result.highlightText, options: [.caseInsensitive, .diacriticInsensitive]) {
            let globalRange = range.lowerBound..<range.upperBound
            attributedString[globalRange].underlineStyle = .single
            attributedString[globalRange].underlineColor = UIColor(colorTheme.getColor(.accent))
            
            if globalRange.upperBound < attributedString.endIndex {
                currentSearchRange = globalRange.upperBound..<attributedString.endIndex
            } else {
                break
            }
        }

        return attributedString
    }

    private func summaryPart(_ text: String?) -> String? {
        guard let text else {
            return nil
        }

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedText.isEmpty ? nil : trimmedText
    }
    
}

@available(iOS 17, *)
#Preview("Search Results Item View", traits: .fixedLayout(width: 300, height: 300)) {
    SearchResultsItemView(
        result: SearchResultZikr(
            zikr: .placeholder(),
            query: "Title"
        )
    )
}
