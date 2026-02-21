//
//
//  Azkar
//  
//  Created on 18.02.2021
//  Copyright © 2021 Al Jawziyya. All rights reserved.
//  

import SwiftUI
import Combine

final class Deeplinker: ObservableObject {

    static let shared = Deeplinker()

    @Published var route: Route?

    enum Route: Hashable {
        case home
        case settings(SettingsRoute)
        case azkar(ZikrCategory)
        case zikr(Int)
    }
    
}

struct RouteKey: EnvironmentKey {
    static var defaultValue: Deeplinker.Route? {
        return nil
    }
}

extension EnvironmentValues {
    var route: Deeplinker.Route? {
        get {
            self[RouteKey.self]
        } set {
            self[RouteKey.self] = newValue
        }
    }
}
