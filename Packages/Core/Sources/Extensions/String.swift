//
//  String.swift
//  Azkar
//
//  Created by Abdurahim Jauzee on 12.04.2020.
//  Copyright © 2020 Al Jawziyya. All rights reserved.
//

import Foundation
import SwiftUI

var arabicVowelsPattern: String {
    return "[\\u064B-\\u0650]|[\\u065D-\\u065E]|\\u0657|[\\u0618-\\u061A]"
}

extension String: @retroactive Identifiable {
    public var id: String {
        return self
    }
}

public extension String {

    var textOrNil: String? {
        let text = trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }

    func firstWord() -> Self {
        return self.components(separatedBy: ",").first ?? self
    }

    /// Returns a new string without any arabic vowels (tashkeel) in
    var trimmingArabicVowels: String {
      let arabicVowelsRange = UnicodeScalar(1611)!...UnicodeScalar(1630)!
      let arabicVowelsSet = CharacterSet(charactersIn: arabicVowelsRange)
        .subtracting(CharacterSet(charactersIn: "ّ"))
      return components(separatedBy: arabicVowelsSet).joined()
    }

    /// Normalizes the string for use in URLs or file paths.
    /// - Returns: A normalized string with special characters removed/replaced, spaces converted to hyphens, and lowercase.
    func normalizeForPath() -> String {
        let decomposedString = self.folding(options: .diacriticInsensitive, locale: .current)
        
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: ".-_"))
        let components = decomposedString.components(separatedBy: allowedCharacters.inverted)
        let filteredString = components.joined(separator: "-")
        
        // Replace multiple consecutive hyphens with a single one
        var normalizedString = filteredString.replacingOccurrences(of: "-+", with: "-", options: .regularExpression)
        
        // Remove leading and trailing hyphens
        normalizedString = normalizedString.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        
        return normalizedString.lowercased()
    }
    
}

public extension String {

    func imageWith(font: UIFont, color: UIColor, size: CGSize) -> UIImage? {
        let nsstring = (self as NSString)
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let stringSize = nsstring.size(withAttributes: attributes)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let origin = CGPoint(x: size.width/2 - stringSize.width/2, y: size.height/2 - stringSize.height/2)
        nsstring.draw(in: .init(origin: origin, size: stringSize), withAttributes: attributes)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

}

public struct SearchContext {
    /// Range of the query inside the string
    public let resultRange: Range<String.Index>
    /// The context which the result appears in.
    public let context: String
    public let contextRange: Range<String.Index>
}

public extension String {
    
    func extractContext(_ query: String, contextWords: Int = 10) -> [SearchContext] {
        // Define the regex pattern to find the query with a specified number of words before and after, case insensitive
        let wordsPattern = "(?:\\S+\\s)?"
        let pattern = "\(String(repeating: wordsPattern, count: contextWords))\\S*\(NSRegularExpression.escapedPattern(for: query))\\S*(?:\\s\\S+)?\(String(repeating: wordsPattern, count: contextWords))"

        // Compile the regular expression
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return [] }
        
        // Find matches in the given text
        let matches = regex.matches(in: self, options: [], range: NSRange(self.startIndex..., in: self))
        
        // Extract the matching strings and format them with ellipses
        return matches.compactMap { match -> SearchContext? in
            guard let contextRange = Range(match.range, in: self) else { return nil }
            var context = String(self[contextRange]).replacingOccurrences(of: "\n", with: " ")

            // Add ellipses where appropriate
            if contextRange.lowerBound != self.startIndex {
                context = "... \(context)"
            }
            if contextRange.upperBound != self.endIndex {
                context = "\(context) ..."
            }

            // Find the range of the query in the context
            guard let resultRange = self.range(of: query, options: [.caseInsensitive], range: contextRange) else { return nil }

            return SearchContext(resultRange: resultRange, context: context, contextRange: contextRange)
        }
    }

}
