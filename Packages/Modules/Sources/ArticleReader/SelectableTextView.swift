import SwiftUI
import Entities
import Library

struct SelectableTextView: UIViewRepresentable {

    let text: String
    var textFormat: Article.TextFormat = .plain
    var fontOverride: UIFont?
    var foregroundColor: UIColor = .label

    @Environment(\.translationFont) private var translationFont
    @Environment(\.fontSizeCategory) private var fontSizeCategory
    @Environment(\.sizeCategory) private var sizeCategory

    func makeUIView(context: Context) -> SelfSizingTextView {
        let textView = SelfSizingTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.defaultLow, for: .vertical)
        textView.adjustsFontForContentSizeCategory = true
        return textView
    }

    func updateUIView(_ textView: SelfSizingTextView, context: Context) {
        let uiFont: UIFont
        if let fontOverride {
            uiFont = fontOverride
        } else {
            let effectiveSizeCategory = fontSizeCategory?.uiContentSizeCategory ?? sizeCategory.uiContentSizeCategory
            let fontSize = textSize(forTextStyle: .title3, contentSizeCategory: effectiveSizeCategory)
            let adjustment = CGFloat(translationFont.sizeAdjustment ?? 0)
            if let customFont = UIFont(name: translationFont.postscriptName, size: fontSize + adjustment) {
                uiFont = customFont
            } else {
                uiFont = UIFont.preferredFont(forTextStyle: .title3)
            }
        }

        if textFormat == .markdown, let attributed = markdownAttributedString(font: uiFont) {
            textView.attributedText = attributed
        } else {
            textView.font = uiFont
            textView.text = text
        }
        textView.textColor = foregroundColor
        textView.invalidateIntrinsicContentSize()
    }

    @available(iOS 16.0, *)
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: SelfSizingTextView, context: Context) -> CGSize? {
        guard let width = proposal.width, width > 0, width < CGFloat.infinity else { return nil }
        let size = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: size.height)
    }

    private func markdownAttributedString(font: UIFont) -> NSAttributedString? {
        guard let attributed = try? NSMutableAttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) else {
            return nil
        }
        let range = NSRange(location: 0, length: attributed.length)
        attributed.addAttribute(.font, value: font, range: range)
        attributed.addAttribute(.foregroundColor, value: foregroundColor, range: range)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        attributed.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
        return attributed
    }
}

final class SelfSizingTextView: UITextView {
    override var intrinsicContentSize: CGSize {
        let width = bounds.width > 0 ? bounds.width : UIScreen.main.bounds.width
        let size = sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: UIView.noIntrinsicMetric, height: size.height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size != intrinsicContentSize {
            invalidateIntrinsicContentSize()
        }
    }
}
