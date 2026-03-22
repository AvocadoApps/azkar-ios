import SwiftUI

enum ZikrShareType: String, CaseIterable, Identifiable {
    case image, text

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .text:
            return String(localized: "share.text")
        case .image:
            return String(localized: "share.image")
        }
    }

    var imageName: String {
        switch self {
        case .image:
            return "photo"
        case .text:
            return "doc.plaintext"
        }
    }
}
