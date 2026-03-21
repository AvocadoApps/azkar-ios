import Foundation
import CoreSpotlight
import Entities

extension SpotlightIndexer {

    func stripMarkdown(_ text: String) -> String {
        var result = text
        // Remove images: ![alt](url)
        result = result.replacingOccurrences(
            of: #"!\[.*?\]\(.*?\)"#,
            with: "",
            options: .regularExpression
        )
        // Convert links [text](url) to just text
        result = result.replacingOccurrences(
            of: #"\[([^\]]*)\]\([^\)]*\)"#,
            with: "$1",
            options: .regularExpression
        )
        // Remove headings markers
        result = result.replacingOccurrences(
            of: #"(?m)^#{1,6}\s+"#,
            with: "",
            options: .regularExpression
        )
        // Remove bold/italic markers
        result = result.replacingOccurrences(
            of: #"(\*{1,3}|_{1,3})(.+?)\1"#,
            with: "$2",
            options: .regularExpression
        )
        // Remove inline code
        result = result.replacingOccurrences(
            of: #"`([^`]+)`"#,
            with: "$1",
            options: .regularExpression
        )
        // Remove blockquote markers
        result = result.replacingOccurrences(
            of: #"(?m)^>\s+"#,
            with: "",
            options: .regularExpression
        )
        // Remove horizontal rules
        result = result.replacingOccurrences(
            of: #"(?m)^[-*_]{3,}\s*$"#,
            with: "",
            options: .regularExpression
        )
        // Remove list markers
        result = result.replacingOccurrences(
            of: #"(?m)^[\s]*[-*+]\s+"#,
            with: "",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: #"(?m)^[\s]*\d+\.\s+"#,
            with: "",
            options: .regularExpression
        )
        return result
    }

    func normalizedText(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let text = value
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.isEmpty == false }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return text.isEmpty ? nil : text
    }

    func shortText(_ value: String?, maxLength: Int) -> String? {
        guard let normalized = normalizedText(value) else {
            return nil
        }

        guard normalized.count > maxLength else {
            return normalized
        }

        let index = normalized.index(normalized.startIndex, offsetBy: maxLength)
        return String(normalized[..<index]) + "..."
    }

    func uniqueKeywords(_ keywords: [String]) -> [String] {
        var seen = Set<String>()
        var unique: [String] = []

        for keyword in keywords {
            let normalized = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
            guard normalized.isEmpty == false else {
                continue
            }
            guard seen.insert(normalized.lowercased()).inserted else {
                continue
            }
            unique.append(normalized)
        }

        return unique
    }

    func makeIdentifierScope(
        language: Language,
        zikrCollectionSource: ZikrCollectionSource
    ) -> String {
        "\(language.id).\(zikrCollectionSource.rawValue).\(versionSalt)"
    }

    func makeUniqueIdentifier(for deepLink: AppDeepLink, scope: String) -> String {
        deepLink.scopedSearchableIdentifier(scope: scope)
    }

    var deviceLanguage: String {
        Bundle.main.preferredLocalizations.first
            ?? Locale.current.languageCode
            ?? "en"
    }

    func makeIndexVersion(
        language: Language,
        zikrCollectionSource: ZikrCollectionSource
    ) -> String {
        let shortVersion = Bundle.main
            .object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        let build = Bundle.main
            .object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        return [versionSalt, shortVersion, build, language.id, deviceLanguage, zikrCollectionSource.rawValue]
            .joined(separator: "-")
    }

    func resetAndIndex(_ items: [CSSearchableItem]) async throws {
        try await deleteItemsInDomain()
        try await index(items)
    }

    func deleteItemsInDomain() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            searchableIndex.deleteSearchableItems(
                withDomainIdentifiers: [domainIdentifier],
                completionHandler: { error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            )
        }
    }

    func index(_ items: [CSSearchableItem]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            searchableIndex.indexSearchableItems(items) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func log(_ message: String) {
#if DEBUG
        print("[Spotlight] \(message)")
#endif
    }

    func logIdentifierUniqueness(of items: [CSSearchableItem]) {
#if DEBUG
        let identifiers = items.compactMap(\.uniqueIdentifier)
        let duplicates = Dictionary(grouping: identifiers, by: { $0 })
            .filter { $1.count > 1 }
            .map(\.key)

        if duplicates.isEmpty {
            log("Identifiers are unique: \(identifiers.count) items")
        } else {
            log("Found duplicate identifiers: \(duplicates.prefix(5))")
        }
#endif
    }
}
