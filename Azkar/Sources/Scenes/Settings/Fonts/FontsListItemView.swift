// Copyright © 2021 Al Jawziyya. All rights reserved. 

import SwiftUI
import Nuke
import NukeUI
import Entities
import Library

struct FontsListItemView: View {
    
    let vm: AppFontViewModel
    let isArabicFontsType: Bool
    let isLoadingFont: Bool
    let isSelectedFont: Bool
    let hasAccessToFont: Bool
    let selectionCallback: () -> Void
    var isRedacted = false
    @Environment(\.colorTheme) var colorTheme
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Group {
                if isArabicFontsType {
                    Text(vm.name)
                        .systemFont(.body)
                } else {
                    Text(vm.name)
                        .customFont(vm.font, style: .body)
                }
            }
            .multilineTextAlignment(.leading)
            
            if isLoadingFont {
                ActivityIndicator(style: .medium, color: colorTheme.getColor(.text))
            }
            
            Spacer()
            
            if let imageURL = vm.imageURL {
                FontsListItemView.fontImageView(imageURL, isRedacted: isRedacted)
                    .tint(colorTheme.getColor(.accent))
                    .frame(width: 100, height: 40)
                    .foregroundStyle(.accent)
                    .onTapGesture(perform: selectionCallback)
            }
            
            if hasAccessToFont || isSelectedFont {
                CheckboxView(isCheked: .constant(isSelectedFont))
                    .frame(width: 20, height: 20)
            } else {
                ProBadgeView()
            }
        }
        .contentShape(Rectangle())
        .frame(minHeight: 50)
    }
    
    @MainActor
    static func fontImageView(_ url: URL?, isRedacted: Bool) -> some View {
        LazyImage(url: url) { state in
            if let image = state.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if state.error != nil {
                Color.clear
            } else {
                if isRedacted {
                    ActivityIndicator(style: .medium, color: Color.secondary)
                        .frame(width: 20, height: 20)
                }
            }
        }
        .processors([
            ImageProcessors.Anonymous(id: "rendering-mode") { image in
                image.withRenderingMode(.alwaysTemplate)
            }
        ])
    }
    
}

struct FontsListItemView_Previews: PreviewProvider {
    static var previews: some View {
        FontsListItemView(
            vm: AppFontViewModel(
                font: ArabicFont.noto,
                language: Language.english
            ),
            isArabicFontsType: false,
            isLoadingFont: false,
            isSelectedFont: false,
            hasAccessToFont: true,
            selectionCallback: {},
            isRedacted: false
        )
        .previewLayout(.fixed(width: 350, height: 50))
        .padding()
    }
}
