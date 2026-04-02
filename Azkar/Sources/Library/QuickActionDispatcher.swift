import Combine

@MainActor
final class QuickActionDispatcher {

    static let shared = QuickActionDispatcher()

    private let routeSubject = PassthroughSubject<Deeplinker.Route, Never>()
    private var pendingRoute: Deeplinker.Route?

    var routes: AnyPublisher<Deeplinker.Route, Never> {
        routeSubject.eraseToAnyPublisher()
    }

    func enqueue(_ route: Deeplinker.Route) {
        pendingRoute = route
        routeSubject.send(route)
    }

    func takePendingRoute() -> Deeplinker.Route? {
        defer { pendingRoute = nil }
        return pendingRoute
    }
}
