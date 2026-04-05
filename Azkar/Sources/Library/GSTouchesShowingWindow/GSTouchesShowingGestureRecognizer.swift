//
//  GSTouchesShowingGestureRecognizer.swift
//  GSTouchesShowingWindow-Swift
//
//  Created by Lukas Petr on 8/25/17.
//  Copyright © 2017 Glimsoft. All rights reserved.
//

import UIKit

public class GSTouchesShowingGestureRecognizer: UIGestureRecognizer, UIGestureRecognizerDelegate {
    let touchesShowingController = GSTouchesShowingController()
    
    public init() {
        super.init(target: nil, action: nil)
        self.cancelsTouchesInView = false
        self.delaysTouchesBegan = false
        self.delaysTouchesEnded = false
        self.delegate = self
    }
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let view = self.view else { return }
        for touch in touches {
            self.touchesShowingController.touchBegan(touch, view: view)
        }
    }

    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let view = self.view else { return }
        for touch in touches {
            self.touchesShowingController.touchMoved(touch, view: view)
        }
    }

    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let view = self.view else { return }
        for touch in touches {
            self.touchesShowingController.touchEnded(touch, view: view)
        }
    }

    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let view = self.view else { return }
        for touch in touches {
            self.touchesShowingController.touchEnded(touch, view: view)
        }
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
