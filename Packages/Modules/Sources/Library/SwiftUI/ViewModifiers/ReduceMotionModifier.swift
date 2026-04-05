import SwiftUI

public extension View {
    @ViewBuilder
    func animationIfAllowed(_ animation: Animation?, @ViewBuilder _ body: () -> some View) -> some View {
        if UIAccessibility.isReduceMotionEnabled {
            body()
        } else {
            withAnimation(animation) {
                body()
            }
        }
    }
}

public func withAnimationIfAllowed(_ animation: Animation?, _ body: () -> some View) -> some View {
    if UIAccessibility.isReduceMotionEnabled {
        return body()
    } else {
        return withAnimation(animation) {
            body()
        }
    }
}

public func withAnimationIfAllowed(_ animation: Animation?, _ body: () -> Void) {
    if !UIAccessibility.isReduceMotionEnabled {
        withAnimation(animation, body)
    }
}
