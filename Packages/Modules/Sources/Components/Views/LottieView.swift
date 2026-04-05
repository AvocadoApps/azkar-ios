import SwiftUI
import Lottie

public struct LottieView: UIViewRepresentable {
    
    public typealias Action = () -> Void
    public typealias UIViewType = UIView
    
    let animationView = LottieAnimationView()
    let name: String
    var loopMode: LottieLoopMode = .playOnce
    var contentMode: UIView.ContentMode = .scaleAspectFit
    var fillColor: Color?
    var speed: CGFloat = 1
    var progress: CGFloat?
    var completionBlock: Action?
    
    public init(
        name: String,
        loopMode: LottieLoopMode = .playOnce,
        contentMode: UIView.ContentMode = .scaleAspectFit,
        fillColor: Color? = nil,
        speed: CGFloat = 1,
        progress: CGFloat? = nil,
        completionBlock: Action? = nil
    ) {
        self.name = name
        self.loopMode = loopMode
        self.contentMode = contentMode
        self.speed = speed
        self.progress = progress
        self.fillColor = fillColor
        self.completionBlock = completionBlock
    }
    
    public class Coordinator {
        var colorScheme: ColorScheme?
        var completionBlock: Action?
        var reduceMotion: Bool = false
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    public func makeUIView(context: UIViewRepresentableContext<LottieView>) -> UIView {
        context.coordinator.colorScheme = context.environment.colorScheme
        context.coordinator.completionBlock = completionBlock
        context.coordinator.reduceMotion = context.environment.accessibilityReduceMotion
        
        animationView.animation = LottieAnimation.named(name)
        animationView.contentMode = contentMode
        animationView.loopMode = loopMode
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.animationSpeed = speed
        
        if let fillColor {
            applyFillColor(to: animationView, color: fillColor)
        }
        
        if let progress = progress {
            animationView.currentProgress = progress
        }
        
        let shouldPlay = !context.coordinator.reduceMotion && progress != 1
        if shouldPlay {
            animationView.play { finished in
                guard finished else { return }
                context.coordinator.completionBlock?()
            }
        }
        
        animationView.isUserInteractionEnabled = false
        
        let view = UIView()
        view.addSubview(animationView)
        animationView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return view
    }

    public func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<LottieView>) {
        context.coordinator.reduceMotion = context.environment.accessibilityReduceMotion
        
        guard context.coordinator.colorScheme != context.environment.colorScheme else {
            return
        }
        context.coordinator.colorScheme = context.environment.colorScheme
        DispatchQueue.main.async {
            if let view = uiView.subviews.first(where: { $0 is LottieAnimationView }) as? LottieAnimationView {
                view.stop()
                view.animation = LottieAnimation.named(name)
                if let fillColor {
                    applyFillColor(to: view, color: fillColor)
                }
                if !context.coordinator.reduceMotion {
                    view.play()
                }
            }
        }
    }
    
    private func applyFillColor(to animationView: LottieAnimationView, color: Color) {
        let uiColor = UIColor(color)
        let components = uiColor.cgColor.components ?? [1, 1, 1, 1]
        let lottieColor = LottieColor(r: components[0], g: components[1], b: components[2], a: components.count > 3 ? components[3] : 1.0)
        
        let colorValueProvider = ColorValueProvider(lottieColor)
        
        // Apply the fill color to all elements
        animationView.setValueProvider(colorValueProvider, keypath: AnimationKeypath(keypath: "**.Fill 1.Color"))
    }
    
}
