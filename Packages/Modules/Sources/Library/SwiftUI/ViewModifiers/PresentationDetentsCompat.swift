import SwiftUI

public enum PresentationDetentCompat: Hashable {
    case medium
    case large
    case height(CGFloat)
    case fraction(CGFloat)
    
    @available(iOS 16.0, *)
    var native: PresentationDetent {
        switch self {
        case .medium: return .medium
        case .large: return .large
        case .height(let height): return .height(height)
        case .fraction(let fraction): return .fraction(fraction)
        }
    }
}

extension View {
    @ViewBuilder
    public func applyPresentationDetents(_ detents: Set<PresentationDetentCompat>) -> some View {
        if #available(iOS 16.0, *) {
            self.presentationDetents(Set(detents.map { $0.native }))
                .presentationDragIndicator(.visible)
        } else {
            self
        }
    }

    @ViewBuilder
    public func applyPresentationDetents(height: CGFloat) -> some View {
        if #available(iOS 16.0, *) {
            self.presentationDetents(height > 0 ? [.height(height)] : [.medium])
                .presentationDragIndicator(.visible)
        } else {
            self
        }
    }
}
