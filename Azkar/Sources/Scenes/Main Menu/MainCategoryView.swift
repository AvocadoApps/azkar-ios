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
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            imageView
                .frame(width: 50, height: 50)

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
                }
            }
        }
        .padding(15)
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
