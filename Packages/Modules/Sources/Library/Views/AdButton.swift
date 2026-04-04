import SwiftUI
import NukeUI
import Entities
import Extensions

struct CustomContainerRelativeShape: Shape {
    var cornerRadius: CGFloat = 25

    func path(in rect: CGRect) -> Path {
        let adaptiveRadius = min(rect.width, rect.height) * (cornerRadius / 100)
        return RoundedRectangle(cornerRadius: adaptiveRadius).path(in: rect)
    }
}

public struct AdButton: View {

    let item: AdButtonItem
    let onClose: () -> Void
    let action: () -> Void
    let cornerRadius: CGFloat
    
    @Environment(\.colorTheme) var colorTheme
    
    public init(
        item: AdButtonItem,
        cornerRadius: CGFloat = 25,
        onClose: @escaping () -> Void,
        action: @escaping () -> Void
    ) {
        self.item = item
        self.cornerRadius = cornerRadius
        self.onClose = onClose
        self.action = action
    }

    // The color used for the text will automatically switch to white if a background image is specified
    private var effectiveforegroundStyle: Color {
        item.imageMode == .background ? .white : (item.foregroundColor ?? colorTheme.getColor(.text))
    }
    
    private var presentationType: AdPresentationType { item.presentationType }
    private var backgroundColor: Color { item.backgroundColor ?? colorTheme.getColor(.contentBackground) }
    private var accentColor: Color { item.accentColor }

    public var body: some View {
        Button(action: action) {
            label
                .glassEffectCompat(.regular.interactive(true), in: RoundedRectangle(cornerRadius: cornerRadius))
        }
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
        .accessibilityAction(named: Text("common.cancel")) {
            onClose()
        }
    }

    var label: some View {
        HStack(alignment: .center, spacing: 0) {
            if let imageLink = item.imageLink, item.imageMode == .icon {
                iconImageView(imageLink)
                    .frame(width: 80 * item.presentationType.scale, height: 80 * item.presentationType.scale)
                    .clipShape(CustomContainerRelativeShape(cornerRadius: cornerRadius))
                    .shadow(color: item.accentColor.opacity(0.5), radius: 3)
                    .removeSaturationIfNeeded()
            }
            
            HStack(alignment: .bottom, spacing: 0) {
                VStack(alignment: .leading, spacing: presentationType.scale * 8) {
                    if let title = item.title {
                        Text(title)
                            .foregroundStyle(effectiveforegroundStyle)
                            .font(presentationType.titleFont)
                    }
                    
                    if let subtitle = item.body {
                        Text(subtitle)
                            .foregroundStyle(effectiveforegroundStyle)
                            .font(presentationType.bodyFont)
                    }
                }
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                if let actionTitle = item.actionTitle {
                    actionButton(actionTitle)
                } else {
                    closeButton.opacity(0) // for spacing.
                }
            }
        }
        .padding(.vertical, 20 * presentationType.scale)
        .padding(.horizontal, 15 * presentationType.scale)
        .overlay(alignment: .topTrailing) {
            GeometryReader { geometry in
                VStack(alignment: .trailing) {
                    closeButton
                    
                    Spacer()
                    
                    if item.actionTitle == nil {
                        arrowImage
                    }
                }
                .padding([.trailing, .vertical], 20 * presentationType.scale)
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .trailing)
            }
        }
        .background(
            ZStack {
                Color.black.opacity(0.1)
                backgroundColor
                if let imageLink = item.imageLink, item.imageMode == .background {
                    backgroundImageView(for: imageLink)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                }
            }
        )
    }
    
    private var arrowImage: some View {
        Image(systemName: "arrow.up.forward")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: presentationType.scale * 10, height: presentationType.scale * 10)
            .padding(presentationType.scale * 5)
            .foregroundStyle(effectiveforegroundStyle.opacity(0.75))
    }
    
    private var closeButton: some View {
        Image(systemName: "xmark")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: presentationType.scale * 10, height: presentationType.scale * 10)
            .foregroundStyle(effectiveforegroundStyle)
            .padding(presentationType.scale * 5)
            .contentShape(Rectangle())
            .accessibilityHidden(true)
            .highPriorityGesture(
                TapGesture()
                    .onEnded(onClose)
            )
    }
    
    private func actionButton(_ title: String) -> some View {
        Text(title)
            .font(presentationType.actionFont)
            .foregroundStyle(Color.white)
            .shadow(color: item.accentColor.opacity(0.5), radius: 10, x: 0, y: 5)
            .padding(presentationType.scale * 10)
            .background {
                CustomContainerRelativeShape(cornerRadius: cornerRadius)
                    .fill(item.accentColor)
            }
    }
    
    @ViewBuilder
    private func iconImageView(_ url: URL) -> some View {
        LazyImage(url: url) { state in
            if let image = state.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if state.isLoading {
                backgroundColor
            }
        }
    }

    @ViewBuilder
    private func backgroundImageView(for url: URL) -> some View {
        LazyImage(url: url) { state in
            if let image = state.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .overlay(Color.black.opacity(0.35))
            } else if state.isLoading {
                Color.black
            }
        }
    }
}

@available(iOS 17, *)
#Preview("Telegram Bot", traits: .fixedLayout(width: 375, height: 150)) {
    VStack {
        Spacer()
        AdButton(
            item: AdButtonItem(ad: .telegramBotDemo),
            onClose: {},
            action: {}
        )
        .frame(height: 120)
    }
    .padding()
}

@available(iOS 17, *)
#Preview("Tickets. Minimal", traits: .fixedLayout(width: 375, height: 125)) {
    AdButton(
        item: AdButtonItem(ad: .ticketsDemo),
        onClose: {},
        action: {}
    )
    .background(Color(.secondarySystemBackground))
    .padding()
}

@available(iOS 17, *)
#Preview("Find Hotel. Minimal", traits: .fixedLayout(width: 375, height: 125)) {
    VStack {
        Spacer()
        AdButton(
            item: AdButtonItem(ad: .hotelsDemo),
            onClose: {},
            action: {}
        )
    }
    .padding()
}
