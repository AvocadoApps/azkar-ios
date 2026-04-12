import SwiftUI

/// A compatibility wrapper for the Glass type available in iOS 26+
public struct GlassCompat: Equatable, Sendable {
    internal enum Variant: Equatable, Sendable {
        case regular
        case clear
        case identity
    }
    
    internal var variant: Variant
    internal var tintColor: Color?
    internal var isInteractive: Bool
    
    private init(variant: Variant, tintColor: Color? = nil, isInteractive: Bool = false) {
        self.variant = variant
        self.tintColor = tintColor
        self.isInteractive = isInteractive
    }
    
    /// The regular variant of glass.
    ///
    /// The regular variant of glass automatically maintains legibility
    /// of content by adjusting its content based on the luminosity of the
    /// content beneath the glass.
    public static var regular: GlassCompat {
        GlassCompat(variant: .regular)
    }
    
    /// The clear variant of glass.
    ///
    /// When using clear glass, ensure content remains legible by adding a
    /// dimming layer or other treatment beneath the glass.
    public static var clear: GlassCompat {
        GlassCompat(variant: .clear)
    }
    
    /// The identity variant of glass. When applied, your content
    /// remains unaffected as if no glass effect was applied.
    public static var identity: GlassCompat {
        GlassCompat(variant: .identity)
    }
    
    /// Returns a copy of the glass with the provided tint color.
    public func tint(_ color: Color?) -> GlassCompat {
        GlassCompat(variant: self.variant, tintColor: color, isInteractive: self.isInteractive)
    }
    
    /// Returns a copy of the glass configured to be interactive.
    public func interactive(_ isEnabled: Bool = true) -> GlassCompat {
        GlassCompat(variant: self.variant, tintColor: self.tintColor, isInteractive: isEnabled)
    }
    
    @available(iOS 26, *)
    internal func toNativeGlass() -> Glass {
        var glass: Glass
        switch variant {
        case .regular:
            glass = .regular
        case .clear:
            glass = .clear
        case .identity:
            glass = .identity
        }
        
        if let tintColor = tintColor {
            glass = glass.tint(tintColor)
        }
        
        if isInteractive {
            glass = glass.interactive(true)
        }
        
        return glass
    }
}

extension View {
    /// Applies a glass effect to the view, compatible with iOS 15+
    /// On iOS 26+, uses the native `.glassEffect()` modifier with the specified glass type and shape
    /// Does nothing on previous iOS versions.
    @ViewBuilder
    nonisolated public func glassEffectCompat(
        _ glass: GlassCompat = .regular.interactive(),
        in shape: some Shape = Capsule()
    ) -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(glass.toNativeGlass(), in: shape)
        } else {
            self
        }
    }
}
