import SwiftUI
import Combine
import Library
import AzkarServices
import Entities
#if canImport(ActivityKit)
import ActivityKit
#endif

final class ZikrPagesViewModel: ObservableObject, Equatable {
    
    enum PageType: Hashable, Identifiable {
        var id: String {
            switch self {
            case .zikr(let vm): return vm.id.description
            case .readingCompletion: return "readingCompletion"
            }
        }
        
        case zikr(ZikrViewModel)
        case readingCompletion
    }

    static func == (lhs: ZikrPagesViewModel, rhs: ZikrPagesViewModel) -> Bool {
        lhs.category == rhs.category && lhs.title == rhs.title
    }
    
    let router: UnownedRouteTrigger<RootSection>
    let category: ZikrCategory
    let title: String
    let azkar: [ZikrViewModel]
    let pages: [PageType]
    let preferences: Preferences
    let zikrCounter: ZikrCounterType
    let selectedPage: AnyPublisher<Int, Never>
    let initialPage: Int
    
    @Published var page = 0
    @Published var hasRemainingRepeats = true
    @Published var counterPosition: CounterPosition

    @Published var isCategoryCompleted = false

    private var cancellables = Set<AnyCancellable>()
    private var liveActivityUpdateTask: Task<Void, Never>?
    private var liveActivitySessionID: UUID?
    private var liveActivityUpdateSequence = 0
    private var completedRepeatsInCategory = 0
    private var totalRepeatsInCategory: Int { azkar.reduce(0) { $0 + $1.zikr.repeats } }

    init(
        router: UnownedRouteTrigger<RootSection>,
        category: ZikrCategory,
        title: String,
        azkar: [ZikrViewModel],
        preferences: Preferences,
        zikrCounter: ZikrCounterType = ZikrCounter.shared,
        selectedPagePublisher: AnyPublisher<Int, Never>,
        initialPage: Int
    ) {
        self.router = router
        self.category = category
        self.title = title
        self.preferences = preferences
        self.zikrCounter = zikrCounter
        self.azkar = azkar
        self.selectedPage = selectedPagePublisher
        self.initialPage = initialPage
        self.page = initialPage
        counterPosition = preferences.counterPosition

        var pages = azkar.map { PageType.zikr($0) }
        if category != .other {
            pages.append(.readingCompletion)
        }
        self.pages = pages

        // Setup completion tracking if category is not 'other'
        if category != .other {
            Task { [weak self] in
                await self?.setupCompletionTracking()
            }
        }

        preferences
            .$counterType
            .toVoid()
            .sink(receiveValue: objectWillChange.send)
            .store(in: &cancellables)

        selectedPagePublisher.dropFirst().assign(to: &$page)

        observePageChangesForLiveActivity()
    }

    // MARK: - Live Activity

    /// Called from the view when the user taps the counter button.
    /// Starts the live activity on the first tap.
    func onCounterTapped() {
        #if canImport(ActivityKit)
        guard category != .other else { return }
        if #available(iOS 16.2, *) {
            Task { [weak self] in
                guard let self else { return }
                guard await ReadingActivityManager.shared.hasActiveSession(for: self.category.rawValue) == false else {
                    return
                }
                let currentPage = self.page
                let currentZikr = self.azkar[safe: currentPage]
                let remaining: Int
                if let zikr = currentZikr?.zikr {
                    remaining = await self.zikrCounter.getRemainingRepeats(for: zikr) ?? zikr.repeats
                } else {
                    remaining = 0
                }
                let sessionID = await ReadingActivityManager.shared.startSession(.init(
                    categoryName: self.title,
                    categoryRawValue: self.category.rawValue,
                    categoryIcon: self.category.systemImageName,
                    categoryImageName: self.category.widgetImageName,
                    currentPage: currentPage + 1,
                    totalPages: self.azkar.count,
                    completedRepeats: self.completedRepeatsInCategory,
                    totalRepeats: self.totalRepeatsInCategory,
                    currentZikrTitle: String((currentZikr?.zikr.title ?? currentZikr?.zikr.translation ?? "").prefix(80)),
                    currentZikrRemainingRepeats: remaining,
                    currentZikrTotalRepeats: currentZikr?.zikr.repeats ?? 0
                ))

                guard let sessionID else { return }
                self.liveActivitySessionID = sessionID
                self.liveActivityUpdateSequence = 0
            }
        }
        #endif
    }

    private func observePageChangesForLiveActivity() {
        #if canImport(ActivityKit)
        guard category != .other else { return }
        $page
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self else { return }
                if #available(iOS 16.2, *) {
                    self.refreshLiveActivityState()
                }
            }
            .store(in: &cancellables)
        #endif
    }

    /// Single serialized path for all live activity updates.
    /// Reads current page at the moment of execution to avoid stale captures.
    @available(iOS 16.2, *)
    private func refreshLiveActivityState() {
        guard let sessionID = liveActivitySessionID else { return }

        liveActivityUpdateSequence += 1
        let updateSequence = liveActivityUpdateSequence
        liveActivityUpdateTask?.cancel()
        liveActivityUpdateTask = Task { [weak self] in
            guard let self else { return }
            let currentPage = self.page
            guard let zikrVM = self.azkar[safe: currentPage] else {
                await ReadingActivityManager.shared.updateSession(state: .init(
                    currentPage: self.azkar.count,
                    totalPages: self.azkar.count,
                    completedRepeats: self.completedRepeatsInCategory,
                    totalRepeats: self.totalRepeatsInCategory,
                    currentZikrTitle: "",
                    currentZikrRemainingRepeats: 0,
                    currentZikrTotalRepeats: 0,
                    isCompleted: !self.hasRemainingRepeats
                ), sequence: updateSequence, sessionID: sessionID)
                return
            }
            let remaining = await self.zikrCounter.getRemainingRepeats(for: zikrVM.zikr)
            guard !Task.isCancelled else { return }
            await ReadingActivityManager.shared.updateSession(state: .init(
                currentPage: currentPage + 1,
                totalPages: self.azkar.count,
                completedRepeats: self.completedRepeatsInCategory,
                totalRepeats: self.totalRepeatsInCategory,
                currentZikrTitle: String((zikrVM.zikr.title ?? zikrVM.zikr.translation ?? "").prefix(80)),
                currentZikrRemainingRepeats: remaining ?? zikrVM.zikr.repeats,
                currentZikrTotalRepeats: zikrVM.zikr.repeats,
                isCompleted: self.completedRepeatsInCategory >= self.totalRepeatsInCategory
            ), sequence: updateSequence, sessionID: sessionID)
        }
    }

    func endLiveActivity(completed: Bool) {
        #if canImport(ActivityKit)
        if #available(iOS 16.2, *) {
            liveActivityUpdateTask?.cancel()
            liveActivityUpdateTask = nil

            let sessionID = liveActivitySessionID
            liveActivitySessionID = nil
            liveActivityUpdateSequence = 0
            let totalRepeats = totalRepeatsInCategory

            Task {
                await ReadingActivityManager.shared.endSession(
                    isCompleted: completed,
                    totalRepeats: totalRepeats,
                    sessionID: sessionID
                )
            }
        }
        #endif
    }
    
    /// Sets up tracking for category completion status
    /// Checks if category is already marked as completed and observes completion status changes
    private func setupCompletionTracking() async {
        if category == .afterSalah {
            await zikrCounter.resetCounterForCategory(category)
        }
        
        @Sendable func setHasRemainingRepeats(_ flag: Bool) {
            withAnimation(.smooth) {
                self.hasRemainingRepeats = flag
            }
        }
        
        // Check if category is already marked as completed
        let isCategoryCompleted = await zikrCounter.isCategoryCompleted(category)
        await MainActor.run {
            setHasRemainingRepeats(!isCategoryCompleted)
        }

        guard !isCategoryCompleted else {
            return
        }
        
        // Set up observation for completed repeats
        let totalCount = totalRepeatsInCategory
        zikrCounter.observeCompletedRepeats(in: category)
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] count in
                self.completedRepeatsInCategory = count
                let hasRemainingRepeats = count < totalCount
                setHasRemainingRepeats(hasRemainingRepeats)
                if !hasRemainingRepeats {
                    Task {
                        try await zikrCounter.markCategoryAsCompleted(category)
                    }
                    self.endLiveActivity(completed: true)
                    return
                }
                // Update live activity progress if already running
                #if canImport(ActivityKit)
                if #available(iOS 16.2, *) {
                    self.refreshLiveActivityState()
                }
                #endif
            }
            .store(in: &cancellables)
    }

    func navigateToZikr(_ vm: ZikrViewModel, index: Int) {
        if UIDevice.current.isIpadInterface {
            router.trigger(.zikr(vm.zikr, index: index))
        } else {
            router.trigger(RootSection.zikrPages(ZikrPagesViewModel(
                router: router,
                category: category,
                title: title,
                azkar: azkar,
                preferences: preferences,
                selectedPagePublisher: selectedPage.eraseToAnyPublisher(),
                initialPage: index
            )))
        }
    }
    
    func navigateToTextSettings() {
        router.trigger(.settings(.text, presentModally: true))
    }

    func goToNextZikrIfNeeded() {
        let newIndex = page + 1
        guard preferences.enableGoToNextZikrOnCounterFinished, newIndex < pages.count else {
            return
        }
        router.trigger(.goToPage(newIndex))
    }
    
    static var placeholder: ZikrPagesViewModel {
        AzkarListViewModel(
            router: .empty,
            category: .other,
            title: ZikrCategory.morning.title,
            azkar: [.demo()],
            preferences: Preferences.shared,
            selectedPagePublisher: PassthroughSubject<Int, Never>().eraseToAnyPublisher(),
            initialPage: 0
        )
    }
        
    func shareCurrentZikr() {
        guard azkar.count > page else {
            return
        }
        let zikr = azkar[page].zikr
        router.trigger(.shareOptions(zikr))
    }
        
    @MainActor func markCurrentCategoryAsCompleted() async {
        do {
            try await zikrCounter.markCategoryAsCompleted(category)
        } catch {
            print("Error marking category as completed: \(error)")
        }
        hasRemainingRepeats = false
        endLiveActivity(completed: true)
    }

    deinit {
        endLiveActivity(completed: !hasRemainingRepeats)
    }

}
