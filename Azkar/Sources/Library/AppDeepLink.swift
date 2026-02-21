import Foundation

enum AppDeepLink: Equatable {
    case home
    case category(ZikrCategory)
    case zikr(Int)

    private static let scheme = "azkar"
    private static let appIdentifier = "app"
    private static let categoryPrefix = "category."
    private static let zikrPrefix = "zikr."

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
        if searchableIdentifier == Self.appIdentifier {
            self = .home
            return
        }

        if searchableIdentifier.hasPrefix(Self.categoryPrefix) {
            let rawValue = String(searchableIdentifier.dropFirst(Self.categoryPrefix.count))
            guard let category = ZikrCategory(rawValue: rawValue) else {
                return nil
            }
            self = .category(category)
            return
        }

        if searchableIdentifier.hasPrefix(Self.zikrPrefix) {
            let idString = String(searchableIdentifier.dropFirst(Self.zikrPrefix.count))
            guard
                let id = Int(idString),
                id > 0
            else {
                return nil
            }
            self = .zikr(id)
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

    var searchableIdentifier: String {
        switch self {
        case .home:
            return Self.appIdentifier
        case .category(let category):
            return Self.categoryPrefix + category.rawValue
        case .zikr(let id):
            return Self.zikrPrefix + String(id)
        }
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
}
