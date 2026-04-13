// Copyright © 2022 Al Jawziyya. All rights reserved.

import SwiftUI
import NukeUI
import Nuke
import FactoryKit
import Library

struct ZikrShareBackgroundPickerView: View {
    let backgrounds: [ZikrShareBackgroundItem]
    @Binding var selectedBackground: ZikrShareBackgroundItem
    @Environment(\.appTheme) var appTheme
    
    // Add a scrollToSelection trigger that parent views can set to true
    @Binding var scrollToSelection: Bool
    
    // Initialize with a default binding if not provided
    init(backgrounds: [ZikrShareBackgroundItem], selectedBackground: Binding<ZikrShareBackgroundItem>, scrollToSelection: Binding<Bool> = .constant(false)) {
        self.backgrounds = backgrounds
        self._selectedBackground = selectedBackground
        self._scrollToSelection = scrollToSelection
    }
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(backgrounds) { item in
                        Button(action: {
                            selectedBackground = item
                            HapticGenerator.performFeedback(.impact(flexibility: .soft))
                            withAnimation {
                                scrollProxy.scrollTo(item.id, anchor: .center)
                            }
                        }, label: {
                            ZikrShareBackgroundCardView(
                                item: item, 
                                isSelected: selectedBackground == item
                            )
                        })
                        .padding(5)
                        .id(item.id)
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
            .onAppear {
                // Scroll on appear if the background is already in the array
                if backgrounds.contains(selectedBackground) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        scrollProxy.scrollTo(selectedBackground.id, anchor: .center)
                    }
                }
            }
            .onChange(of: scrollToSelection) { shouldScroll in
                if shouldScroll && backgrounds.contains(selectedBackground) {
                    withAnimation {
                        scrollProxy.scrollTo(selectedBackground.id, anchor: .center)
                    }
                    // Reset the trigger
                    DispatchQueue.main.async {
                        scrollToSelection = false
                    }
                }
            }
            .onChange(of: selectedBackground) { newBackground in
                if backgrounds.contains(newBackground) {
                    withAnimation {
                        scrollProxy.scrollTo(newBackground.id, anchor: .center)
                    }
                }
            }
        }
    }
}

struct ZikrShareBackgroundCardView: View {
    let item: ZikrShareBackgroundItem
    let isSelected: Bool
    @Injected(\.subscriptionManager) private var subscriptionManager: SubscriptionManagerType
    @Environment(\.appTheme) var appTheme
    @Environment(\.colorTheme) var colorTheme
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        backgroundContent
            .frame(width: 55, height: 70)
            .clipShape(RoundedRectangle(cornerRadius: appTheme.cornerRadius/2))
            .overlay(
                RoundedRectangle(cornerRadius: appTheme.cornerRadius/2)
                    .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
            .overlay(
                displayProBadge ? 
                ProBadgeView()
                    .padding(6)
                    .allowsHitTesting(false)
                    .shadow(color: Color.yellow.opacity(0.8), radius: 2, x: 0, y: 0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                : nil
            )
            .shadow(color: isSelected ? Color.accentColor.opacity(0.25) : Color.clear, 
                    radius: 1, x: 0, y: 0)
    }
    
    private var displayProBadge: Bool {
        subscriptionManager.isProUser() == false && item.isProItem
    }
    
    @ViewBuilder
    private var backgroundContent: some View {
        switch item.background {
        case .solidColor(let color):
            Color(color)
        case .localImage(let image):
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        case .remoteImage(let item):
            LazyImage(url: item.previewUrl ?? item.url) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        Color.gray.opacity(0.2)
                        if state.isLoading {
                            ProgressView()
                        }
                    }
                }
            }
            .pipeline(.shared)
        }
    }
}

struct HorizontalBackgroundPicker_Previews: PreviewProvider {
    static var previews: some View {
        ZikrShareBackgroundPickerView(
            backgrounds: ZikrShareBackgroundItem.preset,
            selectedBackground: .constant(ZikrShareBackgroundItem.defaultBackground)
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
