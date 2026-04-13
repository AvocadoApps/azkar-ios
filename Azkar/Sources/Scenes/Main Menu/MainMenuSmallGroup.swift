// ASCollectionView. Created by Apptek Studios 2019

import SwiftUI

struct MainMenuSmallGroup: View {
    
	var item: AzkarMenuType
    var flip = false
    
    @State private var isCompleted = false
    @EnvironmentObject var counter: ZikrCounter

    private var checkmarkColor: Color {
        guard let category = (item as? AzkarMenuItem)?.category else {
            return .secondary
        }

        switch category {
        case .morning:
            return .orange
        case .evening:
            return .blue
        default:
            return .secondary
        }
    }

    private var accessibilityLabel: String {
        isCompleted
            ? String(
                format: String(localized: "accessibility.common.item-completed"),
                locale: Locale.current,
                item.title
            )
            : item.title
    }

	var body: some View {
		HStack {
            image
            title
        }
        .environment(\.layoutDirection, flip ? .rightToLeft : .leftToRight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .task {
            guard let category = (item as? AzkarMenuItem)?.category else { return }
            isCompleted = await counter.isCategoryCompleted(category)
        }
	}
    
    @ViewBuilder
    var image: some View {
        switch item.iconType {
        case .system, .bundled:
            item.image.flatMap { image in
                image
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(item.imageCornerRadius)
                    .padding(.vertical, 8)
                    .frame(width: 40, height: 40)
                    .foregroundStyle(item.color)
                    .accessibilityHidden(true)
            }
        case .emoji:
            Text(item.imageName)
                .minimumScaleFactor(0.1)
                .font(Font.largeTitle)
                .padding(.vertical, 4)
                .frame(width: 40, height: 40)
                .accessibilityHidden(true)
        }
    }

    var title: some View {
        HStack {
            Text(item.title)
                .systemFont(.body)
                .foregroundStyle(.text)
                .multilineTextAlignment(flip ? .trailing : .leading)
            
            if isCompleted {
                Image(systemName: "checkmark")
                    .foregroundStyle(checkmarkColor)
                    .font(.caption2)
                    .accessibilityHidden(true)
            }
        }
        .environment(\.layoutDirection, flip ? .rightToLeft : .leftToRight)
        .frame(maxWidth: .infinity, alignment: flip ? .trailing : .leading)
    }

}

#Preview("Main Menu Small Group items demo.") {
    List {
        MainMenuSmallGroup(item: AzkarMenuItem.demo)
        MainMenuSmallGroup(item: AzkarMenuItem.noCountDemo)
        MainMenuSmallGroup(item: AzkarMenuItem.noCountDemo, flip: true)
        MainMenuSmallGroup(item: AzkarMenuOtherItem(groupType: .notificationsAccess, imageName: "🌍", title: "Title", color: Color.red, iconType: .emoji), flip: false)
        MainMenuSmallGroup(item: AzkarMenuOtherItem(groupType: .notificationsAccess, imageName: "🌗", title: "Священный месяц рамадан 1442 г.х. (2021 г.)", color: Color.red, iconType: .emoji), flip: true)
    }
    .listStyle(.plain)
}
