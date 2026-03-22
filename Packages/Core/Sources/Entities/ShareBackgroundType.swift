import SwiftUI

public enum ShareBackgroundType: String, Codable, Hashable, CaseIterable, Identifiable {
    case color
    case pattern
    case image
    
    public var id: Self { self }

    public var title: String {
        switch self {
        case .color: String(localized: "share.background-type.color")
        case .image: String(localized: "share.background-type.image")
        case .pattern: String(localized: "share.background-type.pattern")
        }
    }
}
