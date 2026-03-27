//
//
//  Azkar
//  
//  Created on 18.02.2021
//  Copyright © 2021 Al Jawziyya. All rights reserved.
//  

import Combine
import Entities

@MainActor
final class Deeplinker {

    static let shared = Deeplinker()

    private let routeSubject = PassthroughSubject<Route, Never>()
    private var pendingRoute: Route?

    enum Route: Hashable {
        case home
        case settings(SettingsDestination)
        case azkar(ZikrCategory)
        case zikr(Int)
        case article(Int)
        case hadith(Int)
    }

    var routes: AnyPublisher<Route, Never> {
        routeSubject.eraseToAnyPublisher()
    }

    func open(_ route: Route) {
        pendingRoute = route
        routeSubject.send(route)
    }

    func takePendingRoute() -> Route? {
        defer { pendingRoute = nil }
        return pendingRoute
    }
}
