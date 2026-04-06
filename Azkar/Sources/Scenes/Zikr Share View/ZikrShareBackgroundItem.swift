// Copyright © 2022 Al Jawziyya. All rights reserved.

import Foundation
import SwiftUI
import Library
import Entities

extension ZikrShareBackgroundItem {

    static let defaultBackground = ZikrShareBackgroundItem(
        id: ColorType.background.rawValue,
        background: .solidColor(UIColor(Color.getColor(.contentBackground))),
        type: .color,
        isProItem: false
    )
    
    private static let colorTypes: [(id: String, color: UIColor)] = [
        (UUID().uuidString, UIColor(hex: 0xCBDCEB)),
        (UUID().uuidString, UIColor(hex: 0x99BC85)),
        (UUID().uuidString, UIColor(hex: 0x6D94C5)),
    ]
    
    static var colors: [ZikrShareBackgroundItem] {
        colorTypes.map {
            ZikrShareBackgroundItem(
                id: $0.id,
                background: .solidColor($0.color),
                type: .color,
                isProItem: false
            )
        }
    }

    private static let imageNames: [(imageName: String, type: ShareBackgroundType)] = [
        ("gradient-blur-pink-blue-abstract-background", .color),
        ("rippednotes", .pattern),
        ("paper", .pattern),
        ("paper2", .pattern),
        ("paper3", .pattern),
    ]
    
    static var images: [ZikrShareBackgroundItem] {
        imageNames.compactMap {
            guard let image = UIImage(named: "Patterns/" + $0.imageName, in: resourcesBundle, with: nil) else {
                return nil
            }
            return ZikrShareBackgroundItem(
                id: $0.imageName,
                background: .localImage(image),
                type: $0.type,
                isProItem: false
            )
        }
    }
    
    static var preset: [ZikrShareBackgroundItem] {
        [defaultBackground] + colors + images
    }
    
}
