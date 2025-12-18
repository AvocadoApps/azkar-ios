import SwiftUI
import NukeUI
import Entities
import Extensions

public struct HeightPreferenceKey: PreferenceKey {
    public static var defaultValue: CGFloat = 0
    public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

public struct AdBottomSheetView: View {
    let item: AdButtonItem
    let onAction: () -> Void
    let onDismiss: () -> Void
    let onDontShowAgain: () -> Void
    
    @Environment(\.colorTheme) var colorTheme
    
    public init(
        item: AdButtonItem,
        onAction: @escaping () -> Void,
        onDismiss: @escaping () -> Void,
        onDontShowAgain: @escaping () -> Void
    ) {
        self.item = item
        self.onAction = onAction
        self.onDismiss = onDismiss
        self.onDontShowAgain = onDontShowAgain
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    if let imageLink = item.imageLink {
                        LazyImage(url: imageLink) { state in
                            if let image = state.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                Color.gray.opacity(0.2)
                            }
                        }
                        .frame(height: 200)
                        .clipped()
                    }
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                            .padding()
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        if let title = item.title {
                            Text(title)
                                .font(.title2.bold())
                                .foregroundColor(colorTheme.getColor(.text))
                        }
                        
                        if let bodyText = item.body {
                            Text(bodyText)
                                .font(.body)
                                .foregroundColor(colorTheme.getColor(.secondaryText))
                        }
                    }
                    
                    VStack(spacing: 12) {
                        Button(action: onAction) {
                            Text(item.actionTitle ?? NSLocalizedString("common.open", comment: ""))
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(item.accentColor)
                                .cornerRadius(12)
                        }
                        
                        Button(action: onDontShowAgain) {
                            Text(NSLocalizedString("ads.dont-show-again", comment: ""))
                                .font(.subheadline)
                                .foregroundColor(colorTheme.getColor(.secondaryText))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                    }
                }
                .padding(24)
            }
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: HeightPreferenceKey.self, value: proxy.size.height)
                }
            )
        }
        .background(colorTheme.getColor(.background))
    }
}

#Preview("Telegram Bot") {
    struct PreviewWrapper: View {
        @State private var isPresented = false
        
        var body: some View {
            Button("Show Telegram Bot Ad") {
                isPresented = true
            }
            .sheet(isPresented: $isPresented) {
                AdBottomSheetView(
                    item: AdButtonItem(ad: .telegramBotDemo),
                    onAction: { isPresented = false },
                    onDismiss: { isPresented = false },
                    onDontShowAgain: { isPresented = false }
                )
                .applyPresentationDetents([.medium])
            }
        }
    }
    
    return PreviewWrapper()
}

#Preview("Support Project") {
    struct PreviewWrapper: View {
        @State private var isPresented = false
        
        var body: some View {
            Button("Show Support Ad") {
                isPresented = true
            }
            .sheet(isPresented: $isPresented) {
                AdBottomSheetView(
                    item: AdButtonItem(ad: .bottomSheetDemo),
                    onAction: { isPresented = false },
                    onDismiss: { isPresented = false },
                    onDontShowAgain: { isPresented = false }
                )
                .applyPresentationDetents([.medium, .large])
            }
        }
    }
    
    return PreviewWrapper()
}

#Preview("No Image Ad") {
    struct PreviewWrapper: View {
        @State private var isPresented = false
        
        var body: some View {
            Button("Show No Image Ad") {
                isPresented = true
            }
            .sheet(isPresented: $isPresented) {
                AdBottomSheetView(
                    item: AdButtonItem(ad: .ticketsDemo),
                    onAction: { isPresented = false },
                    onDismiss: { isPresented = false },
                    onDontShowAgain: { isPresented = false }
                )
                .applyPresentationDetents([.medium])
            }
        }
    }
    
    return PreviewWrapper()
}
