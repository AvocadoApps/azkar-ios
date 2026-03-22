import SwiftUI
import Library

struct PickerView<T: View>: View {
    let label: LocalizedStringKey
    var navigationTitle: LocalizedStringKey?
    var titleDisplayMode: NavigationBarItem.TitleDisplayMode = .automatic
    var subtitle: String
    var destination: T

    var body: some View {
        NavigationLink(
            destination: destination.navigationBarTitle(navigationTitle ?? label, displayMode: titleDisplayMode)
        ) {
            NavigationLabel(title: label, label: subtitle)
        }
    }
}
