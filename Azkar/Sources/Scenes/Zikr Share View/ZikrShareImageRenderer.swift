import UIKit
import Library
import Entities
import Nuke
import AzkarResources

final class ZikrShareImageRenderer {

    struct Options {
        let viewModel: ZikrViewModel
        let includeTitle: Bool
        let includeOriginalText: Bool
        let includeTranslation: Bool
        let includeTransliteration: Bool
        let includeBenefits: Bool
        let includeLogo: Bool
        let textAlignment: ZikrShareTextAlignment
        let useFullScreen: Bool
        let selectedBackground: ZikrShareBackgroundItem
        let enableLineBreaks: Bool
        let arabicFont: ArabicFont
        let translationFont: TranslationFont
    }

    struct Style {
        let imageWidth: CGFloat
        let contentWidth: CGFloat
        let cardLabelWidth: CGFloat
        let cornerRadius: CGFloat
        let isDark: Bool
        let textColor: UIColor
        let separatorColor: UIColor
        let cardBgColor: UIColor
    }

    private let labelPadding: CGFloat = 16
    private let outerHPadding: CGFloat = 25
    private let outerVPadding: CGFloat = 30
    private let sectionSpacing: CGFloat = 16
    private let dividerHeight: CGFloat = 1.0 / UIScreen.main.scale

    func render(_ opts: Options) -> UIImage {
        let style = resolveStyle(opts)
        let shadowView = buildCardWithShadow(opts, style: style)
        return assembleImage(opts, cardView: shadowView, style: style)
    }
}

// MARK: - Style Resolution

private extension ZikrShareImageRenderer {

    func resolveStyle(_ opts: Options) -> Style {
        let imageWidth = min(440, UIScreen.main.bounds.width)
        let contentWidth = imageWidth - outerHPadding * 2
        let isDark = detectIsDark(opts.selectedBackground)
        let traits = UITraitCollection(userInterfaceStyle: isDark ? .dark : .light)

        return Style(
            imageWidth: imageWidth,
            contentWidth: contentWidth,
            cardLabelWidth: contentWidth - labelPadding * 2,
            cornerRadius: AppTheme.current.cornerRadius,
            isDark: isDark,
            textColor: UIColor.label.resolvedColor(with: traits),
            separatorColor: UIColor.separator.resolvedColor(with: traits),
            cardBgColor: resolveCardBackground(opts.selectedBackground, traits: traits)
        )
    }
}

// MARK: - Layout Assembly

private extension ZikrShareImageRenderer {

    func buildCardWithShadow(_ opts: Options, style: Style) -> UIView {
        let arabicUIFont = resolveFont(opts.arabicFont, style: .title1)
        let bodyUIFont = resolveFont(opts.translationFont, style: .body)
        let footnoteUIFont = resolveFont(opts.translationFont, style: .footnote)
        let arabicAlign: NSTextAlignment = opts.textAlignment.isCentered ? .center : .right
        let otherAlign: NSTextAlignment = opts.textAlignment.isCentered ? .center : .natural

        var sections: [UIView] = []

        if opts.includeOriginalText {
            var text = opts.viewModel.zikr.text
            if !opts.enableLineBreaks { text = text.replacingOccurrences(of: "\n", with: " ") }
            if !opts.arabicFont.hasTashkeelSupport { text = text.trimmingArabicVowels }
            sections.append(makePaddedLabel(
                text, font: arabicUIFont, color: style.textColor,
                alignment: arabicAlign, maxWidth: style.cardLabelWidth
            ))
        }

        if opts.includeTranslation, let translation = opts.viewModel.zikr.translation {
            if opts.includeOriginalText {
                sections.append(makeDivider(style.separatorColor, width: style.contentWidth))
            }
            let text = opts.enableLineBreaks ? translation : translation.replacingOccurrences(of: "\n", with: " ")
            sections.append(makePaddedLabel(
                text, font: bodyUIFont, color: style.textColor,
                alignment: otherAlign, maxWidth: style.cardLabelWidth
            ))
        }

        if opts.includeTransliteration, let transliteration = opts.viewModel.zikr.transliteration {
            sections.append(makeDivider(style.separatorColor, width: style.contentWidth))
            let text = opts.enableLineBreaks ? transliteration : transliteration.replacingOccurrences(of: "\n", with: " ")
            sections.append(makePaddedLabel(
                text, font: bodyUIFont, color: style.textColor,
                alignment: .natural, maxWidth: style.cardLabelWidth
            ))
        }

        if opts.includeBenefits, let benefits = opts.viewModel.zikr.benefits?.textOrNil {
            sections.append(makeDivider(style.separatorColor, width: style.contentWidth))
            sections.append(makeBenefitsSection(
                benefits, font: footnoteUIFont, color: style.textColor, maxWidth: style.contentWidth
            ))
        }

        var cardHeight: CGFloat = 0
        for section in sections {
            section.frame.origin = CGPoint(x: 0, y: cardHeight)
            cardHeight += section.frame.height
        }

        let cardView = UIView(frame: CGRect(x: 0, y: 0, width: style.contentWidth, height: cardHeight))
        cardView.backgroundColor = style.cardBgColor
        cardView.layer.cornerRadius = style.cornerRadius
        cardView.clipsToBounds = true
        sections.forEach { cardView.addSubview($0) }

        let shadowView = UIView(frame: cardView.frame)
        shadowView.backgroundColor = .clear
        if !style.isDark {
            shadowView.layer.shadowColor = UIColor.black.cgColor
            shadowView.layer.shadowOpacity = 0.1
            shadowView.layer.shadowRadius = 5
            shadowView.layer.shadowOffset = CGSize(width: 0, height: 1)
            shadowView.layer.shadowPath = UIBezierPath(
                roundedRect: cardView.bounds, cornerRadius: style.cornerRadius
            ).cgPath
        }
        shadowView.addSubview(cardView)
        cardView.frame.origin = .zero
        return shadowView
    }

    func assembleImage(_ opts: Options, cardView: UIView, style: Style) -> UIImage {
        var titleView: UILabel?
        if opts.includeTitle, let title = opts.viewModel.title {
            let label = makeLabel(
                title, font: UIFont.preferredFont(forTextStyle: .body),
                color: style.textColor, alignment: .center
            )
            let size = label.sizeThatFits(CGSize(width: style.contentWidth, height: CGFloat.greatestFiniteMagnitude))
            label.frame = CGRect(x: 0, y: 0, width: style.contentWidth, height: size.height)
            titleView = label
        }

        var logoView: UIView?
        if opts.includeLogo {
            logoView = makeLogoView(textColor: style.textColor)
        }

        var totalContentHeight: CGFloat = 0
        if let titleView { totalContentHeight += titleView.frame.height + sectionSpacing }
        totalContentHeight += cardView.frame.height
        if let logoView { totalContentHeight += sectionSpacing + logoView.frame.height }

        let minHeight = opts.useFullScreen ? UIScreen.main.bounds.height : (totalContentHeight + outerVPadding * 2)
        let imageHeight = max(totalContentHeight + outerVPadding * 2, minHeight)
        let contentTopY = (imageHeight - totalContentHeight) / 2

        var currentY = contentTopY
        if let titleView {
            titleView.frame.origin = CGPoint(x: outerHPadding, y: currentY)
            currentY += titleView.frame.height + sectionSpacing
        }
        cardView.frame.origin = CGPoint(x: outerHPadding, y: currentY)
        currentY += cardView.frame.height
        if let logoView {
            currentY += sectionSpacing
            logoView.frame.origin = CGPoint(
                x: (style.imageWidth - logoView.frame.width) / 2, y: currentY
            )
        }

        let container = UIView(frame: CGRect(x: 0, y: 0, width: style.imageWidth, height: imageHeight))
        container.clipsToBounds = true

        let bgView = makeBackgroundView(opts.selectedBackground, frame: container.bounds)
        container.addSubview(bgView)
        if let titleView { container.addSubview(titleView) }
        container.addSubview(cardView)
        if let logoView { container.addSubview(logoView) }

        container.setNeedsLayout()
        container.layoutIfNeeded()

        let renderer = UIGraphicsImageRenderer(size: container.bounds.size)
        return renderer.image { ctx in
            container.layer.render(in: ctx.cgContext)
        }
    }
}

// MARK: - View Factories

private extension ZikrShareImageRenderer {

    func makeLabel(_ text: String, font: UIFont, color: UIColor, alignment: NSTextAlignment) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = color
        label.textAlignment = alignment
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }

    func makePaddedLabel(
        _ text: String,
        font: UIFont,
        color: UIColor,
        alignment: NSTextAlignment,
        maxWidth: CGFloat
    ) -> UIView {
        let label = makeLabel(text, font: font, color: color, alignment: alignment)
        let size = label.sizeThatFits(CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude))
        label.frame = CGRect(x: labelPadding, y: labelPadding, width: maxWidth, height: size.height)
        let wrapper = UIView(frame: CGRect(
            x: 0, y: 0,
            width: maxWidth + labelPadding * 2,
            height: size.height + labelPadding * 2
        ))
        wrapper.addSubview(label)
        return wrapper
    }

    func makeDivider(_ color: UIColor, width: CGFloat) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: width, height: dividerHeight))
        view.backgroundColor = color
        return view
    }

    func makeBenefitsSection(_ text: String, font: UIFont, color: UIColor, maxWidth: CGFloat) -> UIView {
        let iconSize: CGFloat = 15
        let iconLabelSpacing: CGFloat = 8
        let labelX = labelPadding + iconSize + iconLabelSpacing
        let labelMaxWidth = maxWidth - labelX - labelPadding

        let label = makeLabel(text, font: font, color: color, alignment: .natural)
        let labelSize = label.sizeThatFits(CGSize(width: labelMaxWidth, height: CGFloat.greatestFiniteMagnitude))
        label.frame = CGRect(x: labelX, y: labelPadding, width: labelMaxWidth, height: labelSize.height)

        let icon = UIImageView(image: UIImage(named: "gem-stone", in: azkarResourcesBundle, with: nil))
        icon.contentMode = .scaleAspectFit
        icon.frame = CGRect(x: labelPadding, y: labelPadding, width: iconSize, height: iconSize)

        let totalHeight = max(iconSize, labelSize.height) + labelPadding * 2
        let wrapper = UIView(frame: CGRect(x: 0, y: 0, width: maxWidth, height: totalHeight))
        wrapper.addSubview(icon)
        wrapper.addSubview(label)
        return wrapper
    }

    func makeLogoView(textColor: UIColor) -> UIView {
        let iconSize: CGFloat = 25
        let logoPadding: CGFloat = 8
        let logoColor = textColor.withAlphaComponent(0.5)

        let icon = UIImageView(
            image: UIImage(named: "ink-icon", in: resourcesBundle, compatibleWith: nil)?
                .withRenderingMode(.alwaysTemplate)
        )
        icon.tintColor = logoColor
        icon.contentMode = .scaleAspectFit
        icon.layer.cornerRadius = 6
        icon.clipsToBounds = true
        icon.frame = CGRect(x: 0, y: 0, width: iconSize, height: iconSize)

        let logoFont = makeSmallCapsRoundedFont(size: 8)
        let label = UILabel()
        label.text = String(localized: "share.shared-with-azkar")
        label.font = logoFont
        label.textColor = logoColor
        label.textAlignment = .center
        let labelSize = label.sizeThatFits(CGSize(width: 200, height: CGFloat.greatestFiniteMagnitude))
        label.frame = CGRect(x: 0, y: 0, width: labelSize.width, height: labelSize.height)

        let totalWidth = max(iconSize, labelSize.width) + logoPadding * 2
        let spacing: CGFloat = 4
        let totalHeight = iconSize + spacing + labelSize.height + logoPadding * 2
        let container = UIView(frame: CGRect(x: 0, y: 0, width: totalWidth, height: totalHeight))

        icon.frame.origin = CGPoint(x: (totalWidth - iconSize) / 2, y: logoPadding)
        label.frame.origin = CGPoint(
            x: (totalWidth - labelSize.width) / 2, y: logoPadding + iconSize + spacing
        )
        container.addSubview(icon)
        container.addSubview(label)
        return container
    }

    func makeBackgroundView(_ background: ZikrShareBackgroundItem, frame: CGRect) -> UIView {
        switch background.background {
        case .solidColor(let color):
            let view = UIView(frame: frame)
            view.backgroundColor = color
            return view
        case .localImage(let image):
            return makeImageBackgroundView(image, frame: frame)
        case .remoteImage(let item):
            let request = ImageRequest(url: item.url)
            if let cached = ImagePipeline.shared.cache.cachedImage(for: request) {
                return makeImageBackgroundView(cached.image, frame: frame)
            }
            let view = UIView(frame: frame)
            view.backgroundColor = .systemBackground
            return view
        }
    }

    func makeImageBackgroundView(_ image: UIImage, frame: CGRect) -> UIView {
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.frame = frame
        return imageView
    }
}

// MARK: - Font Helpers

private extension ZikrShareImageRenderer {

    func resolveFont(_ appFont: AppFont, style: UIFont.TextStyle) -> UIFont {
        let size = textSize(forTextStyle: style) + CGFloat(appFont.sizeAdjustment ?? 0)
        return UIFont(name: appFont.postscriptName, size: size)
            ?? UIFont.preferredFont(forTextStyle: style)
    }

    func makeSmallCapsRoundedFont(size: CGFloat) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: .regular)
        guard let rounded = base.fontDescriptor.withDesign(.rounded) else { return base }
        let smallCaps = rounded.addingAttributes([
            .featureSettings: [
                [
                    UIFontDescriptor.FeatureKey.type: kLowerCaseType,
                    UIFontDescriptor.FeatureKey.selector: kLowerCaseSmallCapsSelector
                ]
            ]
        ])
        return UIFont(descriptor: smallCaps, size: size)
    }
}

// MARK: - Color Helpers

private extension ZikrShareImageRenderer {

    func resolveCardBackground(_ bg: ZikrShareBackgroundItem, traits: UITraitCollection) -> UIColor {
        if bg.type != .color {
            return UIColor.systemBackground.resolvedColor(with: traits).withAlphaComponent(0.8)
        }
        let ns = ColorTheme.current.assetsNamespace
        return UIColor(named: ns + "contentBackground", in: azkarResourcesBundle, compatibleWith: traits)
            ?? UIColor.secondarySystemBackground.resolvedColor(with: traits)
    }

    func detectIsDark(_ background: ZikrShareBackgroundItem) -> Bool {
        switch background.background {
        case .solidColor(let color):
            return isDarkColor(color)
        case .localImage(let image):
            return image.dominantColor().map(isDarkColor) ?? false
        case .remoteImage(let item):
            let request = ImageRequest(url: item.url)
            if let cached = ImagePipeline.shared.cache.cachedImage(for: request) {
                return cached.image.dominantColor().map(isDarkColor) ?? false
            }
            return false
        }
    }

    func isDarkColor(_ color: UIColor) -> Bool {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return 0.299 * r + 0.587 * g + 0.114 * b < 0.5
    }
}
