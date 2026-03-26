import Foundation

public enum ZikrCategory: String, Codable, Equatable, CaseIterable, Identifiable {
    case morning, evening, night, afterSalah = "after-salah", other, hundredDua = "hundred-dua"
    
    public var id: Self { self }

    public var title: String {
        return NSLocalizedString("category." + rawValue, comment: "")
    }
    
    public var systemImageName: String {
        switch self {
        case .morning: return "sun.max.fill"
        case .evening: return "moon.stars.fill"
        case .night: return "bed.double.circle.fill"
        case .afterSalah: return "checkmark.seal.fill"
        case .other: return "square.stack.3d.down.right.fill"
        case .hundredDua: return "list.bullet"
        }
    }

    public var widgetImageName: String {
        switch self {
        case .morning: return "categories/morning"
        case .evening: return "categories/full-moon"
        case .night: return "categories/night"
        case .afterSalah: return "categories/after-salah"
        case .other: return "categories/important-adhkar"
        case .hundredDua: return "categories/hundred-dua"
        }
    }
}
