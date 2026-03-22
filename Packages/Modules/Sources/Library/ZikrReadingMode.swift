import Foundation

public enum ZikrReadingMode: String, Codable, CaseIterable, Identifiable {
    case normal, lineByLine
    
    public var id: Self { self }
    
    public var title: String {
        switch self {
        case .normal: String(localized: "settings.text.reading_mode.normal.title")
        case .lineByLine: String(localized: "settings.text.reading_mode.line_by_line.title")
        }
    }
}
