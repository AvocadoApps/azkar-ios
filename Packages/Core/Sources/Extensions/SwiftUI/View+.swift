import SwiftUI
import UIKit

public extension View {
    
    @ViewBuilder
    func applyAccessibilityLabel(_ label: String?) -> some View {
        if let label {
            self.accessibilityLabel(Text(label))
        } else {
            self
        }
    }

    @ViewBuilder
    func applyAccessibilityLanguage(_ language: String?) -> some View {
        if let language {
            self.background(AccessibilityLanguageConfigurator(language: language))
        } else {
            self
        }
    }
    
}

private struct AccessibilityLanguageConfigurator: UIViewRepresentable {
    let language: String

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        view.isAccessibilityElement = false
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            guard let targetView = targetView(for: uiView) else {
                return
            }

            targetView.accessibilityLanguage = language
        }
    }

    private func targetView(for view: UIView) -> UIView? {
        var currentView: UIView? = view.superview

        while let unwrappedCurrentView = currentView {
            if unwrappedCurrentView is UIControl || unwrappedCurrentView.isAccessibilityElement {
                return unwrappedCurrentView
            }

            currentView = unwrappedCurrentView.superview
        }

        return view.superview
    }
}
