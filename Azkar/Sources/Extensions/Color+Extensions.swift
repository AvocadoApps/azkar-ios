import SwiftUI

extension Color {
    // Determines if the color is dark based on its components
    var isDark: Bool {
        guard let components = UIColor(self).cgColor.components,
              components.count >= 3 else {
            return false
        }
        
        // Calculate relative luminance using standard formula
        // 0 is darkest, 1 is brightest
        let luminance = 0.299 * components[0] + 0.587 * components[1] + 0.114 * components[2]
        
        // Consider colors with luminance < 0.5 as dark
        return luminance < 0.5
    }
}
