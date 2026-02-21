import Foundation

enum AppDeepLink: Equatable {
    case home
    case category(ZikrCategory)
    case zikr(Int)

    private static let scheme = "azkar"
    private static let searchableIdentifierNamespace = "io.jawziyya.azkar-app.spotlight"
    private static let searchableIdentifierSeparator = "|"

    private static let homeToken = "home"
    private static let categoryTokenPrefix = "category:"
    private static let zikrTokenPrefix = "zikr:"
    private static let tagTokenPrefix = "tag:"

    init?(url: URL) {
        guard url.scheme?.lowercased() == Self.scheme else {
            return nil
        }

        let host = (url.host ?? "").lowercased()
        var pathComponents = url.pathComponents
            .filter { $0 != "/" }
            .map { $0.lowercased() }

        let routeComponent: String
        if host.isEmpty {
            guard let first = pathComponents.first else {
                return nil
            }
            routeComponent = first
            pathComponents.removeFirst()
        } else {
            routeComponent = host
        }

        switch routeComponent {
        case "home":
            self = .home

        case "category":
            guard
                let rawValue = pathComponents.first,
                let category = ZikrCategory(rawValue: rawValue)
            else {
                return nil
            }
            self = .category(category)

        case "zikr":
            guard
                let idString = pathComponents.first,
                let id = Int(idString),
                id > 0
            else {
                return nil
            }
            self = .zikr(id)

        default:
            return nil
        }
    }

    init?(searchableIdentifier: String) {
        let candidate = searchableIdentifier
            .components(separatedBy: Self.searchableIdentifierSeparator)
            .last ?? searchableIdentifier

        if let link = Self.parseSearchableToken(candidate) {
            self = link
            return
        }

        return nil
    }

    var url: URL {
        let value: String
        switch self {
        case .home:
            value = "\(Self.scheme)://home"
        case .category(let category):
            value = "\(Self.scheme)://category/\(category.rawValue)"
        case .zikr(let id):
            value = "\(Self.scheme)://zikr/\(id)"
        }
        return URL(string: value)!
    }

    var searchableToken: String {
        switch self {
        case .home:
            return Self.homeToken
        case .category(let category):
            return Self.categoryTokenPrefix + category.rawValue
        case .zikr(let id):
            return Self.zikrTokenPrefix + String(id)
        }
    }

    var searchableIdentifier: String {
        searchableToken
    }

    func scopedSearchableIdentifier(scope: String) -> String {
        [
            Self.searchableIdentifierNamespace,
            scope,
            searchableToken
        ]
        .joined(separator: Self.searchableIdentifierSeparator)
    }

    var route: Deeplinker.Route {
        switch self {
        case .home:
            return .home
        case .category(let category):
            return .azkar(category)
        case .zikr(let id):
            return .zikr(id)
        }
    }

    static func parseSearchableToken(_ token: String) -> AppDeepLink? {
        if token == homeToken {
            return .home
        }

        if token.hasPrefix(categoryTokenPrefix) {
            let rawValue = String(token.dropFirst(categoryTokenPrefix.count))
            guard let category = ZikrCategory(rawValue: rawValue) else {
                return nil
            }
            return .category(category)
        }

        if token.hasPrefix(zikrTokenPrefix) {
            let idString = String(token.dropFirst(zikrTokenPrefix.count))
            guard
                let id = Int(idString),
                id > 0
            else {
                return nil
            }
            return .zikr(id)
        }

        if token.hasPrefix(tagTokenPrefix) {
            return .home
        }

        return nil
    }
}
