import SwiftUI
import UIKit
import Library

struct NavigationControllerHost<Screen: Hashable>: UIViewControllerRepresentable {

    @Binding private var stack: [Screen]
    private let root: () -> AnyView
    private let destination: (Screen) -> AnyView

    init<Root: View>(
        stack: Binding<[Screen]>,
        @ViewBuilder root: @escaping () -> Root,
        destination: @escaping (Screen) -> AnyView
    ) {
        _stack = stack
        self.root = { AnyView(root()) }
        self.destination = destination
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UINavigationController {
        let navigationController = UINavigationController()
        let rootController = UIHostingController(rootView: root())

        context.coordinator.navigationController = navigationController
        context.coordinator.rootController = rootController
        context.coordinator.renderedStack = []

        applyBackgroundColor(to: navigationController)
        configureHostingController(rootController)
        navigationController.delegate = context.coordinator
        navigationController.setViewControllers([rootController], animated: false)

        return navigationController
    }

    func updateUIViewController(_ navigationController: UINavigationController, context: Context) {
        context.coordinator.parent = self
        applyBackgroundColor(to: navigationController)

        if context.coordinator.renderedStack != stack {
            context.coordinator.apply(stack: stack)
        } else {
            context.coordinator.reloadVisibleControllers(rootView: root())
        }
    }

    private func applyBackgroundColor(to navigationController: UINavigationController) {
        navigationController.view.backgroundColor = UIColor(
            Color.getColor(.background, theme: Preferences.shared.colorTheme)
        )
    }

    private func configureHostingController(_ viewController: UIViewController) {
        viewController.view.backgroundColor = .clear
        viewController.view.isOpaque = false
    }
}

extension NavigationControllerHost {

    final class Coordinator: NSObject, UINavigationControllerDelegate {

        var parent: NavigationControllerHost
        weak var navigationController: UINavigationController?
        var rootController: UIHostingController<AnyView>?
        var renderedStack: [Screen] = []
        var isApplyingProgrammaticChange = false

        init(parent: NavigationControllerHost) {
            self.parent = parent
        }

        func apply(stack: [Screen]) {
            guard renderedStack != stack, let navigationController, let rootController else {
                return
            }

            isApplyingProgrammaticChange = true

            if stack.count == renderedStack.count + 1,
               Array(stack.dropLast()) == renderedStack,
               let nextScreen = stack.last {
                renderedStack = stack
                navigationController.pushViewController(makeController(for: nextScreen), animated: true)
                completeProgrammaticChange()
                return
            }

            if renderedStack.count == stack.count + 1,
               Array(renderedStack.dropLast()) == stack {
                renderedStack = stack
                navigationController.popViewController(animated: true)
                completeProgrammaticChange()
                return
            }

            renderedStack = stack
            let controllers = [rootController] + stack.map(makeController(for:))
            navigationController.setViewControllers(controllers, animated: false)
            completeProgrammaticChange()
        }

        func reloadVisibleControllers(rootView: AnyView) {
            guard let rootController else {
                return
            }

            rootController.rootView = rootView
            parent.configureHostingController(rootController)
        }

        func navigationController(
            _ navigationController: UINavigationController,
            didShow viewController: UIViewController,
            animated: Bool
        ) {
            guard !isApplyingProgrammaticChange else {
                return
            }

            let visibleDepth = max(0, navigationController.viewControllers.count - 1)
            let updatedStack = Array(renderedStack.prefix(visibleDepth))
            guard updatedStack != renderedStack else {
                return
            }

            renderedStack = updatedStack
            DispatchQueue.main.async { [weak self] in
                self?.parent.stack = updatedStack
            }
        }

        private func makeController(for screen: Screen) -> UIViewController {
            let controller = UIHostingController(rootView: parent.destination(screen))
            parent.configureHostingController(controller)
            return controller
        }

        private func completeProgrammaticChange() {
            DispatchQueue.main.async { [weak self] in
                self?.isApplyingProgrammaticChange = false
            }
        }
    }
}
