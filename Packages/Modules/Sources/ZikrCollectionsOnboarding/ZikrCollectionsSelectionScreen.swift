import SwiftUI
import Entities
import Library

struct ZikrCollectionsSelectionScreen: View {
    
    @State var selectedCollection: ZikrCollectionSource
    @Environment(\.appTheme) var appTheme
    @Environment(\.colorTheme) var colorTheme
    let onContinue: (ZikrCollectionSource) -> Void
    
    init(
        selectedCollection: ZikrCollectionSource,
        onContinue: @escaping (ZikrCollectionSource) -> Void
    ) {
        _selectedCollection = .init(wrappedValue: selectedCollection)
        self.onContinue = onContinue
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Color.clear.frame(height: 0)
                
                content
                
                note
                
                mainActionButton
            }
            .padding(.horizontal, 20)
        }
        .customScrollContentBackground()
        .background(colorTheme.getColor(.background))
        .navigationTitle("adhkar-collections.selection-screen-title")
    }
    
    var mainActionButton: some View {
        Button {
            onContinue(selectedCollection)
        } label: {
            Text("common.done")
                .font(Font.body.weight(.semibold))
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
    
    var content: some View {
        VStack(spacing: 21) {
            itemView(collection: .hisnulMuslim)
            itemView(collection: .azkarRU)
        }
    }
    
    func itemView(
        collection: ZikrCollectionSource
    ) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            if UIAccessibility.isReduceMotionEnabled {
                selectedCollection = collection
            } else {
                withAnimation(.spring) {
                    selectedCollection = collection
                }
            }
        } label: {
            itemViewLabel(collection)
        }

    }
    
    func itemViewLabel(_ collection: ZikrCollectionSource) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(collection.title)
                    .font(Font.title3.bold())
                
                Spacer()
                
                Image(systemName: "checkmark")
                    .foregroundStyle(.accent)
                    .opacity(collection == selectedCollection ? 1 : 0)
            }
            Text(collection.description)
        }
        .foregroundStyle(Color.primary)
        .multilineTextAlignment(.leading)
        .padding(.vertical, 20)
        .padding(.horizontal, 30)
        .frame(maxWidth: .infinity)
        .background(.contentBackground)
        .clipShape(RoundedRectangle(cornerRadius: appTheme.cornerRadius))
    }
    
    var note: some View {
        HStack(alignment: .top) {
            Image(systemName: "info.circle.fill")
            Text("adhkar-collections.order-explanation-text")
        }
        .foregroundStyle(.secondaryText, opacity: 0.5)
        .font(Font.caption2)
        .frame(maxWidth: .infinity)
    }
    
}

#Preview {
    NavigationView {
        ZikrCollectionsSelectionScreen(
            selectedCollection: .hisnulMuslim,
            onContinue: { _ in }
        )
    }
}
