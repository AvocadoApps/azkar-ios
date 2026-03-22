import SwiftUI

enum CounterType: Int, Codable, CaseIterable, Identifiable {
    case floatingButton, tap

    var id: Int {
        rawValue
    }

    var title: String {
        switch self {
        case .floatingButton: return String(localized: "settings.counter.counter-type.button")
        case .tap: return String(localized: "settings.counter.counter-type.tap")
        }
    }
}
