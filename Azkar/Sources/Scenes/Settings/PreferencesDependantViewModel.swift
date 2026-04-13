// Copyright © 2023 Azkar
// All Rights Reserved.

import SwiftUI
import Combine
import FactoryKit

/// Base view model which sends update signal on any preferneces changes.
class PreferencesDependantViewModel: ObservableObject {
    @Injected(\.preferences) var preferences: Preferences
    private var cancellables = Set<AnyCancellable>()

    init() {
        preferences
            .storageChangesPublisher()
            .receive(on: RunLoop.main)
            .sink(receiveValue: objectWillChange.send)
            .store(in: &cancellables)
    }
}
