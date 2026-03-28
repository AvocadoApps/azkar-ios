import SwiftUI
import Library
import Entities
import AzkarResources

struct MainCategoryView: View {
    
    let category: ZikrCategory
    
    @State private var isCompleted = false
    @EnvironmentObject var counter: ZikrCounter

    private var checkmarkColor: Color {
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
                category.title
            )
            : category.title
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            imageView
                .frame(width: 50, height: 50)
                .accessibilityHidden(true)

            HStack {
                Text(category.title)
                    .systemFont(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.text)
                    .layoutPriority(1)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .foregroundStyle(checkmarkColor)
                        .font(.caption)
                        .accessibilityHidden(true)
                }
            }
        }
        .padding(15)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
        .task {
            isCompleted = await counter.isCategoryCompleted(category)
        }
    }
    
    @ViewBuilder private var imageView: some View {
        switch category {
        case .morning:
            Image("categories/morning", bundle: azkarResourcesBundle)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
                .foregroundStyle(.text)
        case .evening:
            LunarPhaseView(info: LunarPhaseInfo(Date()))
        default:
            EmptyView()
        }
    }
    
}
