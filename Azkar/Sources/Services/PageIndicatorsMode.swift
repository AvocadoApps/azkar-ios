import SwiftUI

enum PageIndicatorsMode: String, Codable, CaseIterable, Identifiable {
    case all, custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return String(localized: "settings.counter.page-indicators.all")
        case .custom: return String(localized: "settings.counter.page-indicators.custom")
        }
    }
}
