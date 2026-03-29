import SwiftUI

struct StreakWidgetTier {
    let streakCount: Int

    private enum Palette {
        static let radiantTop = Color(red: 0.99, green: 0.71, blue: 0.28)
        static let radiantBottom = Color(red: 0.93, green: 0.42, blue: 0.19)
        static let radiantTint = Color(red: 0.96, green: 0.56, blue: 0.21)
    }

    enum Level: Int, Comparable {
        case idle = 0, spark, steady, devoted, radiant
        static func < (lhs: Level, rhs: Level) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    var level: Level {
        switch streakCount {
        case 0: return .idle
        case 1...2: return .spark
        case 3...6: return .steady
        case 7...29: return .devoted
        default: return .radiant
        }
    }

    var iconName: String {
        switch level {
        case .idle: return "bolt"
        case .spark, .steady: return "bolt.fill"
        case .devoted: return "flame.fill"
        case .radiant: return "flame.circle.fill"
        }
    }

    var iconGradient: AnyShapeStyle {
        switch level {
        case .idle:
            return AnyShapeStyle(Color(.systemGray3))
        case .spark, .steady:
            return AnyShapeStyle(Color.orange)
        case .devoted:
            return AnyShapeStyle(LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom))
        case .radiant:
            return AnyShapeStyle(LinearGradient(colors: [Palette.radiantTop, Palette.radiantBottom], startPoint: .top, endPoint: .bottom))
        }
    }

    var numberColor: Color {
        level == .idle ? .secondary : .primary
    }

    var numberWeight: Font.Weight {
        switch level {
        case .idle: return .medium
        case .spark, .steady: return .bold
        case .devoted, .radiant: return .heavy
        }
    }

    var shadowColor: Color {
        switch level {
        case .idle, .spark: return .clear
        case .steady: return .orange.opacity(0.15)
        case .devoted: return .orange.opacity(0.25)
        case .radiant: return Palette.radiantTint.opacity(0.28)
        }
    }

    var shadowRadius: CGFloat {
        switch level {
        case .idle, .spark: return 0
        case .steady: return 3
        case .devoted: return 5
        case .radiant: return 6
        }
    }

    var backgroundTint: Color? {
        switch level {
        case .idle, .spark: return nil
        case .steady, .devoted: return .orange
        case .radiant: return Palette.radiantTint
        }
    }

    var backgroundOpacity: Double {
        switch level {
        case .idle, .spark: return 0
        case .steady: return 0.06
        case .devoted: return 0.08
        case .radiant: return 0.1
        }
    }
}
