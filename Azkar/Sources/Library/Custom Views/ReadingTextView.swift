import SwiftUI
import Library
import Fakery
import Extensions

struct ReadingTextView: View {

    let text: String
    let highlightPattern: String?
    let isArabicText: Bool
    let font: AppFont
    var lineSpacing: CGFloat
    var accessibilityLanguage: String?

    var body: some View {
        Group {
            if isArabicText {
                Text(attributedString(text, highlighting: highlightPattern))
                    .customFont(.title1, isArabic: true)
                    .lineSpacing(lineSpacing)
            } else {
                Text(attributedString(text, highlighting: highlightPattern))
                    .customFont(.body)
                    .lineSpacing(lineSpacing)
            }
        }
        .multilineTextAlignment(isArabicText ? .trailing : .leading)
        .buttonStyle(.plain)
        .applyAccessibilityLanguage(accessibilityLanguage)
    }
    
}

#Preview("Reading Text View") {
    let faker = Faker()
    let words = faker.lorem.paragraphs(amount: 3)
    
    return ReadingTextView(
        text: words,
        highlightPattern: words.components(separatedBy: " ").randomElement(),
        isArabicText: false,
        font: TranslationFont.baskerville,
        lineSpacing: 1,
        accessibilityLanguage: nil
    )
}
