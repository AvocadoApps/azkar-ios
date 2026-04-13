import SwiftUI
import FactoryKit
import Library

final class AppIconPackListViewModel: ObservableObject {

    @Injected(\.preferences) private var preferences: Preferences
    @Injected(\.subscriptionManager) private var subscriptionManager: SubscriptionManagerType
    let subscribeScreenTrigger: Action
    @Published var icon: AppIcon = .gold
    
    let iconPacks: [AppIconPack] = AppIconPack.allCases

    init(subscribeScreenTrigger: @escaping Action) {
        self.subscribeScreenTrigger = subscribeScreenTrigger
        icon = preferences.appIcon
    }
    
    func setAppIcon(_ icon: AppIcon) {
        guard isIconAvailable(icon) else {
            subscribeScreenTrigger()
            return
        }
        switch icon {
        case .gold:
            // Reset to standard icon.
            UIApplication.shared.setAlternateIconName(nil)
        default:
            // Apply custom icon.
            UIApplication.shared.setAlternateIconName(icon.referenceName)
        }
        self.icon = icon
        preferences.appIcon = icon
    }
    
    func isIconAvailable(_ icon: AppIcon) -> Bool {
        return subscriptionManager.isProUser() || AppIconPack.standard.icons.contains(icon)
    }

}

struct AppIconPackListView: View {

    @ObservedObject var viewModel: AppIconPackListViewModel

    init(viewModel: AppIconPackListViewModel) {
        self.viewModel = viewModel
    }

    @Environment(\.safariPresenter) var safariPresenter

    private var animation = Animation.spring().speed(1.25)

    var body: some View {
        list
            .onAppear {
                AnalyticsReporter.reportScreen("App Icon Pack List", className: viewName)
            }
    }

    var list: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.iconPacks) { pack in
                    iconPicker(pack)
                }
                
                Color.clear.frame(height: 20)
            }
        }
        .scrollContentBackground(.hidden)
        .background(.background, ignoreSafeArea: .all)
    }

    func iconPicker(_ iconPack: AppIconPack) -> some View {
        Section {
            self.content(for: iconPack)
        } header: {
            HStack {
                Text(iconPack.title)
                    .systemFont(.title3, modification: .smallCaps)
                    .foregroundStyle(.secondaryText)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                iconPack.link.flatMap { link in
                    Button(action: {
                        safariPresenter.set(link)
                    }, label: {
                        Image(systemName: "link")
                    })
                }
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 16)
        }
    }

    func content(for pack: AppIconPack) -> some View {
        ForEachIndexed(pack.icons) { _, position, icon in
            Button(action: {
                viewModel.setAppIcon(icon)
            }, label: {
                iconView(for: icon, position: position)
            })
            .buttonStyle(.plain)
        }
    }
    
    func iconView(for icon: AppIcon, position: IndexPosition) -> some View {
        HStack(spacing: 16) {
            if let image = UIImage(named: icon.iconImageName, in: resourcesBundle, compatibleWith: nil) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 45, height: 45)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 1)
            }
            
            Text(icon.title)
                .systemFont(.body)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            if viewModel.icon == icon || viewModel.isIconAvailable(icon) {
                CheckboxView(isChecked:  .constant(self.viewModel.icon.referenceName == icon.referenceName))
                    .frame(width: 20, height: 20)
            } else {
                ProBadgeView()
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 12)
        .padding(.horizontal)
        .background(.contentBackground)
        .applyTheme(indexPosition: position)
        .padding(.horizontal)
    }

}

struct AppIconPackListView_Previews: PreviewProvider {
    static var previews: some View {
        AppIconPackListView(
            viewModel: AppIconPackListViewModel(
                subscribeScreenTrigger: {}
            )
        )
    }
}
