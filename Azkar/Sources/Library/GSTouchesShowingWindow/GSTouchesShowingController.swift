//
//  GSTouchesShowingController.swift
//  GSTouchesShowingWindow-Swift
//
//  Created by Lukas Petr on 8/25/17.
//  Copyright © 2017 Glimsoft. All rights reserved.
//

import UIKit

private struct CONSTANTS {
    static let TouchImageName = "TouchImageBlue"
    static let ShowExpandingCircle = false
    static let ShortTapThresholdDuration = 0.11
    static let ShortTapInitialCircleRadius : CGFloat = 22.0
    static let ShortTapFinalCircleRadius : CGFloat = 57.0
}

class GSTouchesShowingController {
    
    let touchImageViewQueue = GSTouchImageViewQueue(touchesCount: 8)
    var touchImgViewsDict: [String: UIImageView] = [:]
    var touchesStartDateMapTable = NSMapTable<UITouch, NSDate>()
    
    func touchBegan(_ touch: UITouch, view: UIView) {
        let touchImgView = self.touchImageViewQueue.popTouchImageView()
        touchImgView.center = touch.location(in: view)
        view.addSubview(touchImgView)
        
        touchImgView.alpha = 0.0
        touchImgView.transform = CGAffineTransform(scaleX: 1.13, y: 1.13)
        self.setTouchImageView(touchImgView, for: touch)
        
        UIView.animate(withDuration: 0.1) { 
            touchImgView.alpha = 1.0
            touchImgView.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        self.touchesStartDateMapTable.setObject(NSDate(), forKey: touch)
    }
    
    func touchMoved(_ touch: UITouch, view: UIView) {
        self.touchImageView(for: touch).center = touch.location(in: view)
    }
    
    func touchEnded(_ touch: UITouch, view: UIView) {
        let touchStartDate = self.touchesStartDateMapTable.object(forKey: touch)
        let touchDuration = NSDate().timeIntervalSince(touchStartDate! as Date)
        self.touchesStartDateMapTable.removeObject(forKey: touch)
        
        if touchDuration < CONSTANTS.ShortTapThresholdDuration, CONSTANTS.ShowExpandingCircle {
            self.showExpandingCircle(at: touch.location(in: view), in: view)
        }
        
        let touchImgView = self.touchImageView(for: touch)
        UIView.animate(withDuration: 0.1, animations: {
            touchImgView.alpha = 0.0
            touchImgView.transform = CGAffineTransform(scaleX: 1.13, y: 1.13)
        }, completion: { _ in
            touchImgView.removeFromSuperview()
            touchImgView.alpha = 1.0
            self.touchImageViewQueue.push(touchImgView)
            self.removeTouchImageView(for: touch)
        })
    }
    
    func showExpandingCircle(at position: CGPoint, in view: UIView) {
        let circleLayer = CAShapeLayer()
        let initialRadius = CONSTANTS.ShortTapInitialCircleRadius
        let finalRadius = CONSTANTS.ShortTapFinalCircleRadius
        circleLayer.position = CGPoint(x: position.x - initialRadius, y: position.y - initialRadius)
        
        let startPathRect = CGRect(x: 0, y: 0, width: initialRadius * 2, height: initialRadius * 2)
        let startPath = UIBezierPath(roundedRect: startPathRect, cornerRadius: initialRadius)
        
        let endPathOrigin = initialRadius - finalRadius
        let endPathRect = CGRect(x: endPathOrigin, y: endPathOrigin, width: finalRadius * 2, height: finalRadius * 2)
        let endPath = UIBezierPath(roundedRect: endPathRect, cornerRadius: finalRadius)
        
        circleLayer.path = startPath.cgPath
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.strokeColor = UIColor(red: 0.0/255, green: 135.0/255, blue: 244.0/255, alpha: 0.8).cgColor
        circleLayer.lineWidth = 2.0
        view.layer.addSublayer(circleLayer)
        
        CATransaction.begin()
        CATransaction.setCompletionBlock { 
            circleLayer.removeFromSuperlayer()
        }
        
        // Expanding animation
        let expandingAnimation = CABasicAnimation(keyPath: "path")
        expandingAnimation.fromValue = startPath.cgPath
        expandingAnimation.toValue = endPath.cgPath
        expandingAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        expandingAnimation.duration = 0.4
        expandingAnimation.repeatCount = 1.0
        circleLayer.add(expandingAnimation, forKey: "expandingAnimation")
        circleLayer.path = endPath.cgPath
        
        // Delayed fade out animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            let fadingOutAnimation = CABasicAnimation(keyPath: "opacity")
            fadingOutAnimation.fromValue = 1.0
            fadingOutAnimation.toValue = 0.0
            fadingOutAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            fadingOutAnimation.duration = 0.15
            circleLayer.add(fadingOutAnimation, forKey: "fadeOutAnimation")
            circleLayer.opacity = 0.0
        }
        
        CATransaction.commit()
    }
    
    func touchImageView(for touch: UITouch) -> UIImageView {
        return self.touchImgViewsDict["\(touch.hash)"]!
    }
    
    func setTouchImageView(_ touchImageView: UIImageView, for touch: UITouch) {
        self.touchImgViewsDict["\(touch.hash)"] = touchImageView
    }
    
    func removeTouchImageView(for touch: UITouch) {
        self.touchImgViewsDict.removeValue(forKey: "\(touch.hash)")
    }
}

class GSTouchImageViewQueue {
    
    var backingArray: [UIImageView] = []
    
    convenience init(touchesCount: Int) {
        self.init()
        
        let bundle = Bundle(for: type(of: self))
        for _ in 0..<touchesCount {
            let imageView = UIImageView(image: UIImage(named: CONSTANTS.TouchImageName, in: resourcesBundle, compatibleWith: nil))
            self.backingArray.append(imageView)
        }
    }
    
    func popTouchImageView() -> UIImageView {
        return self.backingArray.removeFirst()
    }
    
    func push(_ touchImageView: UIImageView) {
        self.backingArray.append(touchImageView)
    }
    
}
