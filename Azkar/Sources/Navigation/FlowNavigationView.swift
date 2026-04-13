import SwiftUI

struct FlowNavigationContainer<Screen, Root: View>: View {

    @Binding private var stack: [Screen]
    @Binding private var resetToken: UUID
    private let root: () -> Root
    private let destination: (Screen) -> AnyView

    init(
        stack: Binding<[Screen]>,
        resetToken: Binding<UUID>,
        @ViewBuilder root: @escaping () -> Root,
        destination: @escaping (Screen) -> AnyView
    ) {
        _stack = stack
        _resetToken = resetToken
        self.root = root
        self.destination = destination
    }

    var body: some View {
        NavigationView {
            FlowNavigationStack(
                stack: $stack,
                resetToken: $resetToken,
                root: root,
                destination: destination
            )
        }
#if os(iOS)
        .navigationViewStyle(.stack)
#endif
    }
}

struct FlowNavigationStack<Screen, Root: View>: View {

    @Binding private var stack: [Screen]
    @Binding private var resetToken: UUID
    private let root: () -> Root
    private let destination: (Screen) -> AnyView

    init(
        stack: Binding<[Screen]>,
        resetToken: Binding<UUID>,
        @ViewBuilder root: @escaping () -> Root,
        destination: @escaping (Screen) -> AnyView
    ) {
        _stack = stack
        _resetToken = resetToken
        self.root = root
        self.destination = destination
    }

    var body: some View {
        FlowNavigationNode(
            stack: $stack,
            currentResetToken: $resetToken,
            nodeResetToken: resetToken,
            rootView: AnyView(root()),
            destination: destination
        )
    }
}

private struct FlowNavigationNode<Screen>: View {

    @Binding var stack: [Screen]
    @Binding var currentResetToken: UUID
    let nodeResetToken: UUID
    let rootView: AnyView
    let destination: (Screen) -> AnyView

    var body: some View {
        rootView.background(hiddenNavigationLink)
    }

    private var hiddenNavigationLink: some View {
        let link = NavigationLink(
            destination: nextView,
            isActive: isActiveBinding,
            label: EmptyView.init
        )

#if os(iOS)
        return AnyView(link.isDetailLink(false).hidden())
#else
        return AnyView(link.hidden())
#endif
    }

    private var isActiveBinding: Binding<Bool> {
        Binding(
            get: { !stack.isEmpty },
            set: { isActive in
                guard !isActive else { return }
                if !stack.isEmpty, currentResetToken == nodeResetToken {
                    stack.removeLast()
                }
            }
        )
    }

    @ViewBuilder
    private var nextView: some View {
        if let current = stack.first {
            FlowNavigationNode(
                stack: remainingStackBinding(current),
                currentResetToken: $currentResetToken,
                nodeResetToken: nodeResetToken,
                rootView: destination(current),
                destination: destination
            )
        } else {
            EmptyView()
        }
    }

    private func remainingStackBinding(_ current: Screen) -> Binding<[Screen]> {
        Binding(
            get: {
                Array(stack.dropFirst())
            },
            set: { newValue in
                stack = [current] + newValue
            }
        )
    }
}
