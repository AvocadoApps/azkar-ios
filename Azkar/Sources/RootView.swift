import SwiftUI
import Combine
import Library

final class RootViewModel: ObservableObject {
    var mainMenuViewModel: MainMenuViewModel
    private var cancellables = Set<AnyCancellable>()
    
    @Published var title = ""
    
    private func getRandomEmoji() -> String {
        ["🌙", "🌸", "☘️", "🌳", "🌴", "🌱", "🌼", "💫", "🌎", "🌍", "🌏", "🪐", "✨", "❄️", "🤍", "🌌"].randomElement()!
    }
    
    init(
        mainMenuViewModel: MainMenuViewModel
    ) {
        self.mainMenuViewModel = mainMenuViewModel
        
        let appName = String(localized: "app-name")
        let title = "\(appName)"
        mainMenuViewModel.preferences
            .$enableFunFeatures
            .map { [unowned self] flag in
                if flag {
                    return title + self.getRandomEmoji()
                } else {
                    return title
                }
            }
            .assign(to: \.title, on: self)
            .store(in: &cancellables)
    }
}

struct RootView: View {
    
    @ObservedObject var viewModel: RootViewModel
    @Environment(\.appTheme) var appTheme
    
    var body: some View {
        MainMenuView(
            viewModel: viewModel.mainMenuViewModel
        )
        .environmentObject(ZikrCounter.shared)
        .navigationBarTitle(appName)
        .navigationTitleMode(.large)
        .searchable(
            text: $viewModel.mainMenuViewModel.searchQuery,
            placement: .navigationBarDrawer(displayMode: .always)
        )
        .autocorrectionDisabled(true)
        .attachSafariPresenter()
    }
    
    var appName: String {
        if appTheme == .code {
            return "~" + viewModel.title
        } else {
            return viewModel.title
        }
    }
    
}

#Preview("Root View") {
    NavigationView {
        RootView(
            viewModel: .init(mainMenuViewModel: .placeholder)
        )
    }
}
