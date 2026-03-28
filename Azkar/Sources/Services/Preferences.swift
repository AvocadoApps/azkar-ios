import UIKit
import Combine
import SwiftUI
import Entities
import Library

let defaultMorningNotificationTime: Date = {
    let components = DateComponents(calendar: Calendar.current, hour: 8)
    return components.date ?? Date()
}()

let defaultEveningNotificationTime: Date = {
    let components = DateComponents(calendar: Calendar.current, hour: 14)
    return components.date ?? Date()
}()

let defaultJumuaReminderTime: Date = {
    let components = DateComponents(calendar: Calendar.current, hour: 15, weekday: 5)
    return components.date ?? Date()
}()

final class Preferences: ObservableObject, TextProcessingPreferences {
    
    private let defaults: UserDefaults
    private let textSettingsChangePublishSubject = PassthroughSubject<UUID, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        
        Publishers
            .MergeMany(
                $sizeCategory.toVoid().dropFirst().map { _ in UUID() },
                $useSystemFontSize.toVoid().dropFirst().map { _ in UUID() },
                $showTashkeel.toVoid().dropFirst().map { _ in UUID() },
                $lineSpacing.toVoid().dropFirst().map { _ in UUID() },
                $translationLineSpacing.toVoid().dropFirst().map { _ in UUID() }
            )
            .subscribe(textSettingsChangePublishSubject)
            .store(in: &cancellables)
        
        $colorTheme
            .sink { theme in
                ColorTheme.current = theme
            }
            .store(in: &cancellables)
        
        $appTheme
            .sink { theme in
                AppTheme.current = theme
            }
            .store(in: &cancellables)
        
        storageChangesPublisher()
            .sink(receiveValue: objectWillChange.send)
            .store(in: &cancellables)
    }
    
    static var shared = Preferences()
    
    @Preference(Keys.zikrCollectionSource, defaultValue: ZikrCollectionSource.azkarRU, userDefaults: .appGroup)
    var zikrCollectionSource: ZikrCollectionSource

    @Preference(Keys.enableFunFeatures, defaultValue: true)
    var enableFunFeatures: Bool

    @Preference(Keys.expandTranslation, defaultValue: true)
    var expandTranslation: Bool

    @Preference(Keys.expandTransliteration, defaultValue: true)
    var expandTransliteration: Bool

    @Preference(Keys.showTashkeel, defaultValue: true)
    var showTashkeel

    @Preference(Keys.theme, defaultValue: .automatic)
    var theme: Theme
    
    @Preference(Keys.appTheme, defaultValue: AppTheme.current)
    var appTheme: AppTheme
    
    @Preference(Keys.colorTheme, defaultValue: ColorTheme.default)
    var colorTheme: ColorTheme

    @available(*, deprecated, message: "This property is deprecated and will be removed in a future release")
    var enableNotifications: Bool { true }
    
    @Preference(Keys.enableAdhkarReminder, defaultValue: true)
    var enableAdhkarReminder: Bool
    
    @Preference(Keys.enableJumuaReminder, defaultValue: true)
    var enableJumuaReminder: Bool
    
    @Preference(Keys.jumuaReminderTime, defaultValue: defaultJumuaReminderTime)
    var jumuaReminderTime: Date
    
    @Preference(Keys.morningNotificationsTime, defaultValue: defaultMorningNotificationTime)
    var morningNotificationTime: Date

    @Preference(Keys.eveningNotificationsTime, defaultValue: defaultEveningNotificationTime)
    var eveningNotificationTime: Date

    @Preference(Keys.appIcon, defaultValue: AppIcon.gold)
    var appIcon: AppIcon

    @Preference(Keys.useSystemFontSize, defaultValue: true)
    var useSystemFontSize

    @Preference(Keys.lineSpacing, defaultValue: LineSpacing.s)
    var lineSpacing

    @Preference(Keys.translationLineSpacing, defaultValue: LineSpacing.s)
    var translationLineSpacing
    
    @Preference(Keys.zikrReadingMode, defaultValue: ZikrReadingMode.normal)
    var zikrReadingMode: ZikrReadingMode

    @Preference(Keys.sizeCategory, defaultValue: ContentSizeCategory.medium)
    var sizeCategory
    
    @Preference(Keys.preferredAdhkarReminderSound, defaultValue: ReminderSound.standard)
    var adhkarReminderSound: ReminderSound
    
    @Preference(Keys.preferredJumuahReminderSound, defaultValue: ReminderSound.standard)
    var jumuahDuaReminderSound: ReminderSound
    
    // MARK: - Counter
    @Preference(Keys.enableCounter, defaultValue: true)
    var enableCounter: Bool

    @Preference(Keys.enableCounterTicker, defaultValue: true)
    var enableCounterTicker: Bool

    @Preference(Keys.enableCounterHapticFeedback, defaultValue: true)
    var enableCounterHapticFeedback: Bool
    
    @Preference(Keys.counterType, defaultValue: CounterType.floatingButton)
    var counterType: CounterType
    
    @Preference(Keys.counterSize, defaultValue: CounterSize.medium)
    var counterSize: CounterSize

    @Preference(Keys.counterPosition, defaultValue: CounterPosition.left)
    var counterPosition: CounterPosition

    @Preference(Keys.enableGoToNextZikrOnCounterFinished, defaultValue: true)
    var enableGoToNextZikrOnCounterFinished: Bool

    @Preference(Keys.pageIndicatorsMode, defaultValue: PageIndicatorsMode.all)
    var pageIndicatorsMode: PageIndicatorsMode

    @Preference(Keys.pageIndicatorsCategories, defaultValue: Set(ZikrCategory.allCases))
    var pageIndicatorsCategories: Set<ZikrCategory>

    func showPageIndicators(for category: ZikrCategory) -> Bool {
        switch pageIndicatorsMode {
        case .all:
            return true
        case .custom:
            return pageIndicatorsCategories.contains(category)
        }
    }

    @Preference(Keys.enableLineBreaks, defaultValue: true)
    var enableLineBreaks
    
    @Preference(Keys.transliterationType, defaultValue: ZikrTransliterationType.community)
    var transliterationType: ZikrTransliterationType
    
    @Preference(
        Keys.contentLanguage,
        defaultValue: Language.getSystemLanguage(),
        userDefaults: .appGroup
    )
    var contentLanguage: Language

    @Preference(Keys.hasCompletedFirstLaunch, defaultValue: false)
    var hasCompletedFirstLaunch: Bool
     
    private func getFont<T: AppFont & Decodable>(_ key: String) -> T? {
        guard
            let data = defaults.data(forKey: key),
            let font = try? JSONDecoder().decode(T.self, from: data) else {
                return nil
            }
        return font
    }
    
    func setPreferredArabicFont(font: AppFont) {
        guard let font = font as? ArabicFont, let data = try? JSONEncoder().encode(font) else {
            return
        }
        defaults.set(data, forKey: Keys.arabicFont)
        textSettingsChangePublishSubject.send(UUID())
    }
    
    func setPreferredTranslationFont(font: AppFont) {
        guard let font = font as? TranslationFont, let data = try? JSONEncoder().encode(font) else {
            return
        }
        defaults.set(data, forKey: Keys.preferredFont)
        textSettingsChangePublishSubject.send(UUID())
    }
    
    var preferredArabicFont: ArabicFont {
        guard let font: ArabicFont = getFont(Keys.arabicFont) else {
            return ArabicFont.noto
        }
        return font
    }

    var arabicLineAdjustment: CGFloat {
        lineSpacing.value * CGFloat(preferredArabicFont.lineAdjustment ?? 1)
    }
    
    var preferredTranslationFont: TranslationFont {
        guard let font: TranslationFont = getFont(Keys.preferredFont) else {
            return TranslationFont.iowanOldStyle
        }
        return font
    }

    var translationLineAdjustment: CGFloat {
        translationLineSpacing.value * CGFloat(preferredTranslationFont.lineAdjustment ?? 1)
    }
    
    private var notificationSubscription: AnyCancellable?

    func storageChangesPublisher() -> AnyPublisher<Void, Never> {
        return NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .map { _ in }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func fontSettingsChangesPublisher() -> AnyPublisher<UUID, Never> {
        textSettingsChangePublishSubject.share().eraseToAnyPublisher()
    }

}
