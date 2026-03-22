import UIKit
import SwiftUI
import Combine
import AudioPlayer
import AVFoundation
import Library
import AzkarServices
import DatabaseInteractors

final class ZikrViewModel: ObservableObject, Identifiable, Hashable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(zikr)
    }

    static func == (lhs: ZikrViewModel, rhs: ZikrViewModel) -> Bool {
        return lhs.id == rhs.id
    }

    var id: Int {
        zikr.id
    }

    let zikr: Zikr
    let title: String?
    /// Is nested into a container like page view or other.
    let isNested: Bool

    @Published private(set) var text: [String]
    @Published private(set) var translation: [String]
    @Published private(set) var transliteration: [String]
    let highlightPattern: String?

    @Published private(set) var highlightCurrentIndex = true
    @Published private(set) var indexToHighlight: Int?

    let preferences: Preferences
    let counter: ZikrCounterType
    let textProcessor: TextProcessor
    let transcriptor: Transcriptor?

    let source: String?

    var playerViewModel: PlayerViewModel?
    var hadithViewModel: HadithViewModel?

    @Published var expandTranslation: Bool

    let hasTransliteration: Bool
    @Published var expandTransliteration: Bool
    
    @Published var textSettingsToken = UUID()

    @Published var remainingRepeatsFormatted: String?
    @Published var remainingRepeatsNumber: Int? {
        didSet {
            updateRemainingRepeatsText()
        }
    }
    private var showRemainingCounter = true {
        didSet {
            updateRemainingRepeatsText()
        }
    }

    @MainActor
    func updateRemainingRepeats() async {
        remainingRepeatsNumber = await counter.getRemainingRepeats(for: zikr)
    }

    func updateRemainingRepeatsText() {
        guard let remainingRepeatsNumber = remainingRepeatsNumber else {
            remainingRepeatsFormatted = nil
            return
        }
        
        if !showRemainingCounter || remainingRepeatsNumber == zikr.repeats {
            remainingRepeatsFormatted = String(format: String(localized: "repeats_number"), locale: Locale.current, zikr.repeats)
        } else {
            remainingRepeatsFormatted = String(format: String(localized: "remaining-repeats"), locale: Locale.current, remainingRepeatsNumber)
        }
    }
    
    var showCounterButton: Bool {
        preferences.counterType == .floatingButton
    }
    
    private var cancellables: Set<AnyCancellable> = []
    private let player: Player
    
    public var audioURL: URL? {
        if let link = zikr.audio?.link {
            return Bundle.main.url(forAuxiliaryExecutable: link)
        }
        return nil
    }
    
    public var audioDuration: Double? {
        guard let url = audioURL else {
            return nil
        }
        let asset = AVURLAsset(url: url)
        return Double(CMTimeGetSeconds(asset.duration))
    }
    
    var rowNumber: String?

    init(
        zikr: Zikr,
        isNested: Bool,
        highlightPattern: String? = nil,
        row: Int? = nil,
        hadith: Hadith?,
        preferences: Preferences,
        player: Player,
        counter: ZikrCounterType = ZikrCounter.shared,
        textProcessor: TextProcessor = TextProcessor(preferences: Preferences.shared)
    ) {
        self.highlightPattern = highlightPattern
        self.counter = counter
        self.isNested = isNested
        self.zikr = zikr
        self.preferences = preferences
        self.textProcessor = textProcessor
        self.player = player
        transcriptor = TranscriptorProvider.createTranscriptor(for: preferences.transliterationType)
        title = zikr.title
        
        if let row {
            rowNumber = String(format: String(localized: "common.dhikr"), locale: Locale.current, String(describing: row))
        }
        
        text = textProcessor.processArabicText(zikr.text)
        
        expandTranslation = preferences.expandTranslation
        expandTransliteration = preferences.expandTransliteration
        var transliterationText = zikr.transliteration
        if let transcriptor, zikr.originType != .quran {
            transliterationText = transcriptor.transcribe(zikr.text)
        }
        hasTransliteration = transliterationText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        
        translation = zikr.translation?.textOrNil.flatMap(textProcessor.processTranslationText) ?? []
        transliteration = transliterationText?.textOrNil.flatMap(textProcessor.processTransliterationText) ?? []
        source = zikr.source?.firstWord()
        
        Task {
            self.remainingRepeatsNumber = await counter.getRemainingRepeats(for: zikr)
        }

        if let url = audioURL {
            let timings = zikr.audioTimings
            let playerViewModel = PlayerViewModel(
                title: title ?? zikr.id.description,
                subtitle: zikr.category?.title,
                audioURL: url,
                timings: timings,
                player: player
            )
            self.playerViewModel = playerViewModel

            playerViewModel
                .$progressInSeconds
                .filter { _ in preferences.enableLineBreaks }
                .filter { $0 > 0 }
                .compactMap { time -> AudioTiming? in
                    return timings.last(where: { $0.time == time || $0.time < time })
                }
                .removeDuplicates()
                .sink { [weak self] timing in
                    self?.indexToHighlight = timings.firstIndex(of: timing) ?? 0
                }
                .store(in: &cancellables)

            playerViewModel
                .$progress
                .sink { [weak self] progress in
                    if progress == 0 {
                        self?.indexToHighlight = nil
                    }
                }
                .store(in: &cancellables)
        }

        if let hadith = hadith {
            hadithViewModel = HadithViewModel(
                hadith: hadith,
                highlightPattern: highlightPattern,
                preferences: preferences
            )
        }
        
        cancellables.insert(
            preferences.$expandTranslation.assign(to: \.expandTranslation, on: self)
        )

        cancellables.insert(
            preferences.$expandTransliteration.assign(to: \.expandTransliteration, on: self)
        )
        
        preferences.fontSettingsChangesPublisher()
            .receive(on: RunLoop.main)
            .sink { [unowned self] id in
                self.textSettingsToken = id
            }
            .store(in: &cancellables)

        preferences.$enableLineBreaks
            .dropFirst()
            .throttle(for: 1, scheduler: DispatchQueue.main, latest: true)
            .sink(receiveValue: { [unowned self] _ in
                text = textProcessor.processArabicText(zikr.text)
                translation = zikr.translation?.textOrNil.flatMap(textProcessor.processTranslationText) ?? []
                transliteration = transliterationText?.textOrNil.flatMap(textProcessor.processTransliterationText) ?? []
            })
            .store(in: &cancellables)

        updateRemainingRepeatsText()
    }
    
    func getShareText(
        includeTitle: Bool,
        includeTranslation: Bool,
        includeTransliteration: Bool,
        includeBenefits: Bool,
        enableLineBreaks: Bool
    ) -> String {
        ShareTextProvider(
            zikr: zikr,
            translation: translation,
            transliteration: transliteration,
            includeTitle: includeTitle,
            includeTranslation: includeTranslation,
            includeTransliteration: includeTransliteration,
            includeBenefits: includeBenefits,
            enableLineBreaks: enableLineBreaks
        )
        .getShareText()
    }
    
    func increaseFontSize() {
        preferences.sizeCategory = preferences.sizeCategory.bigger()
    }
    
    func decreaseFontSize() {
        preferences.sizeCategory = preferences.sizeCategory.smaller()
    }

    @MainActor
    func incrementZikrCount() async {
        guard remainingRepeatsNumber != nil else {
            return
        }
        showRemainingCounter = true
        do {
            try await counter.incrementCounter(for: zikr)
        } catch {
            return
        }
        guard let remainingRepeatsNumber = await counter.getRemainingRepeats(for: zikr) else {
            return
        }
        
        withAnimation(.smooth.speed(1.5)) {
            self.remainingRepeatsNumber = remainingRepeatsNumber
        }

        if preferences.enableCounterTicker, !player.isPlaying {
            DispatchQueue.global(qos: .userInitiated).async {
                self.playTickerSound()
            }
        }
    }

    func toggleCounterFormat() {
        showRemainingCounter.toggle()
    }

    private func playTickerSound() {
        guard
            let url = Bundle.main.url(forResource: "counter-ticker", withExtension: "m4a"),
            let audioItem = AudioItem(soundURLs: [.high: url]) else {
            return
        }
        player.playItem(audioItem, atVolume: 0.25)
    }
    
    func playAudio(at index: Int) {
        if text.count > 1 {
            indexToHighlight = index
        }
        playerViewModel?.goToTiming(at: index)
    }
    
    func pausePlayer() {
        player.pause()
    }
    
    @MainActor func resetCounter() async {
        guard let category = zikr.category, category != .other else {
            return
        }
        await counter.resetCounterForCategory(category)
        remainingRepeatsNumber = await counter.getRemainingRepeats(for: zikr)
        updateRemainingRepeatsText()
    }
    
    @MainActor func completeCounter() async {
        guard let category = zikr.category, category != .other else {
            return
        }
        do {
            try await counter.incrementCounter(for: zikr, by: remainingRepeatsNumber ?? 100)
            remainingRepeatsNumber = 0
            updateRemainingRepeatsText()
        } catch {
            print(error)
        }
    }
    
}

extension ZikrViewModel {
    
    static func demo() -> ZikrViewModel {
        ZikrViewModel(
            zikr: Zikr.placeholder(),
            isNested: true,
            hadith: nil,
            preferences: Preferences.shared,
            player: Player.test
        )
    }
    
}
