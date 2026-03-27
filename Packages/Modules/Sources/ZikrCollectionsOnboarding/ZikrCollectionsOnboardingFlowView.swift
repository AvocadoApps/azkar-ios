import SwiftUI
import Entities

public struct ZikrCollectionsOnboardingFlowView: View {

    public let preselectedCollection: ZikrCollectionSource
    public let onZikrCollectionSelect: (ZikrCollectionSource) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showsCollectionPicker = false

    public init(
        preselectedCollection: ZikrCollectionSource,
        onZikrCollectionSelect: @escaping (ZikrCollectionSource) -> Void
    ) {
        self.preselectedCollection = preselectedCollection
        self.onZikrCollectionSelect = onZikrCollectionSelect
    }

    public var body: some View {
        NavigationView {
            ZikrCollectionsOnboardingScreen(
                onShowCollectionPicker: {
                    showsCollectionPicker = true
                },
                onDismiss: {
                    dismiss()
                }
            )
            .background(hiddenNavigationLink)
        }
        .navigationViewStyle(.stack)
    }

    private var hiddenNavigationLink: some View {
        NavigationLink(
            destination: ZikrCollectionsSelectionScreen(
                selectedCollection: preselectedCollection,
                onContinue: { source in
                    onZikrCollectionSelect(source)
                    dismiss()
                }
            ),
            isActive: $showsCollectionPicker,
            label: EmptyView.init
        )
        .hidden()
    }
}
