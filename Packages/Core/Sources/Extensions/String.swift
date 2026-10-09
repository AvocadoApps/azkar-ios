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

    /// Normalizes Arabic text for full-text search.
    ///
    /// Unlike `trimmingArabicVowels` (which is tuned for display and keeps the
    /// shadda), this removes *all* tashkeel including the shadda, drops the
    /// tatweel, and unifies common letter variants (alef/hamza forms, alef
    /// maqsura, ta marbuta). The exact same normalization is applied to both the
    /// `azkar_search` FTS index and to user queries so that searching works with
    /// or without vowels and regardless of how alef/hamza are typed.
    ///
    /// IMPORTANT: the offline indexing script
    /// (`scripts/populate_arabic_search_index.py`) replicates this logic. Keep
    /// the two in sync — any change here must be mirrored there and the database
    /// regenerated, otherwise Arabic search will silently stop matching.
    var arabicSearchNormalized: String {
        var result = ""
        result.unicodeScalars.reserveCapacity(unicodeScalars.count)
        for scalar in unicodeScalars {
            let value = scalar.value
            // Drop tashkeel / Quranic annotation marks and the tatweel.
            if (0x0610...0x061A).contains(value)
                || (0x064B...0x065F).contains(value)
                || value == 0x0670
                || (0x06D6...0x06ED).contains(value)
                || value == 0x0640 {
                continue
            }
            switch value {
            case 0x0622, 0x0623, 0x0625, 0x0671: // آ أ إ ٱ -> ا
                result.append("ا")
            case 0x0649: // ى -> ي
                result.append("ي")
            case 0x0629: // ة -> ه
                result.append("ه")
            default:
                result.unicodeScalars.append(scalar)
            }
        }
        return result
    }

    /// Returns the Arabic-search-normalized form of the string together with a
    /// mapping back to the original.
    ///
    /// For every character in the normalized string, `starts[i]` / `ends[i]`
    /// hold the index range in `self` of the original character it came from.
    /// Because normalization only ever drops a character or replaces it with a
    /// single one (never expands), this lets callers locate a match in the
    /// normalized text and translate the range back onto the *original*
    /// (vowelled) text — so search results can be displayed with their tashkeel
    /// while still highlighting exactly what matched.
    func arabicSearchNormalizedWithMapping() -> (normalized: String, starts: [String.Index], ends: [String.Index]) {
        var normalized = ""
        var starts: [String.Index] = []
        var ends: [String.Index] = []
        var index = startIndex
        while index < endIndex {
            let next = self.index(after: index)
            // A grapheme cluster has a single base letter, so its normalized
            // form is at most one character; the loop is defensive regardless.
            for character in String(self[index]).arabicSearchNormalized {
                normalized.append(character)
                starts.append(index)
                ends.append(next)
            }
            index = next
        }
        return (normalized, starts, ends)
    }

    /// Finds `query` inside the receiver using Arabic-insensitive matching
    /// (ignoring tashkeel and alef/hamza variants) and returns context windows
    /// taken from the *original* text, plus the exact original substrings that
    /// matched so they can be highlighted with their vowels intact.
    ///
    /// Returns `nil` when the query is empty or no match is found.
    func extractArabicHighlightContexts(
        query: String,
        contextWords: Int = 10
    ) -> (snippet: String, matches: [String])? {
        let mapping = arabicSearchNormalizedWithMapping()
        let normalizedSelf = mapping.normalized
        let normalizedQuery = query.arabicSearchNormalized
        guard normalizedQuery.isEmpty == false else { return nil }

        let contexts = normalizedSelf.extractContext(normalizedQuery, contextWords: contextWords)
        guard contexts.isEmpty == false else { return nil }

        func originalLowerBound(_ index: String.Index) -> String.Index {
            let offset = normalizedSelf.distance(from: normalizedSelf.startIndex, to: index)
            return offset < mapping.starts.count ? mapping.starts[offset] : endIndex
        }
        func originalUpperBound(_ index: String.Index) -> String.Index {
            let offset = normalizedSelf.distance(from: normalizedSelf.startIndex, to: index)
            guard offset > 0 else { return startIndex }
            return offset - 1 < mapping.ends.count ? mapping.ends[offset - 1] : endIndex
        }

        var snippets: [String] = []
        var matches: [String] = []
        for context in contexts {
            let lower = originalLowerBound(context.contextRange.lowerBound)
            let upper = originalUpperBound(context.contextRange.upperBound)
            guard lower < upper else { continue }

            var snippet = String(self[lower..<upper]).replacingOccurrences(of: "\n", with: " ")
            if lower != startIndex { snippet = "... " + snippet }
            if upper != endIndex { snippet += " ..." }
            snippets.append(snippet)

            let matchLower = originalLowerBound(context.resultRange.lowerBound)
            let matchUpper = originalUpperBound(context.resultRange.upperBound)
            if matchLower < matchUpper {
                matches.append(String(self[matchLower..<matchUpper]))
            }
        }

        guard let snippet = snippets.joined(separator: "\n\n").textOrNil else { return nil }
        // Preserve order while removing duplicate match spans.
        var seen = Set<String>()
        let uniqueMatches = matches.filter { seen.insert($0).inserted }
        return (snippet, uniqueMatches)
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
