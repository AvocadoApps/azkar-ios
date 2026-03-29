import SwiftUI
import Entities

@available(iOS 16, *)
func contextualCategory(for date: Date) -> ZikrCategory {
    let hour = Calendar.current.component(.hour, from: date)
    switch hour {
    case 4..<15:
        return .morning
    case 15..<20:
        return .evening
    default:
        return .night
    }
}

@available(iOS 16, *)
struct CategoryQuickAccessWidgetPalette {
    let tint: Color
    let gradientTop: Color
    let gradientBottom: Color
    let contextualFillOpacity: Double

    static func palette(for category: ZikrCategory) -> CategoryQuickAccessWidgetPalette {
        switch category {
        case .morning:
            return CategoryQuickAccessWidgetPalette(tint: .orange, gradientTop: .orange, gradientBottom: .yellow, contextualFillOpacity: 0.2)
        case .evening:
            return CategoryQuickAccessWidgetPalette(tint: .indigo, gradientTop: .indigo, gradientBottom: .purple, contextualFillOpacity: 0.12)
        case .night:
            return CategoryQuickAccessWidgetPalette(tint: .blue, gradientTop: Color(red: 0.15, green: 0.25, blue: 0.45), gradientBottom: .blue, contextualFillOpacity: 0.2)
        case .afterSalah:
            return CategoryQuickAccessWidgetPalette(tint: .brown, gradientTop: .brown, gradientBottom: .orange, contextualFillOpacity: 0.2)
        default:
            return CategoryQuickAccessWidgetPalette(tint: .gray, gradientTop: .gray, gradientBottom: Color(uiColor: .systemGray3), contextualFillOpacity: 0.2)
        }
    }
}
