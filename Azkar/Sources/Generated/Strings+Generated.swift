// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  /// Azkar
  internal static let appName = L10n.tr("Localizable", "app-name", fallback: "Azkar")
  /// Plural format key: "%#@value@"
  internal static func remainingRepeats(_ p1: Int) -> String {
    return L10n.tr("Localizable", "remaining-repeats", p1, fallback: "Plural format key: \"%#@value@\"")
  }
  /// 
  internal static let remainingRepeatsPlural4 = L10n.tr("Localizable", "remaining-repeats-plural-4", fallback: "")
  /// 
  internal static let remainingRepeatsPlural5 = L10n.tr("Localizable", "remaining-repeats-plural-5", fallback: "")
  /// Plural format key: "%#@value@"
  internal static func repeatsNumber(_ p1: Int) -> String {
    return L10n.tr("Localizable", "repeats_number", p1, fallback: "Plural format key: \"%#@value@\"")
  }
  /// 
  internal static let repeatsNumberPlural4 = L10n.tr("Localizable", "repeats_number-plural-4", fallback: "")
  /// 
  internal static let repeatsNumberPlural5 = L10n.tr("Localizable", "repeats_number-plural-5", fallback: "")
  /// Photo library access denied. You can allow access in Settings.
  internal static let sharePhotoLibraryAccessDenied = L10n.tr("Localizable", "share_photo_library_access_denied", fallback: "Photo library access denied. You can allow access in Settings.")
  internal enum About {
    /// About
    internal static let title = L10n.tr("Localizable", "about.title", fallback: "About")
    internal enum Credits {
      /// Font %@
      internal static func font(_ p1: Any) -> String {
        return L10n.tr("Localizable", "about.credits.font", String(describing: p1), fallback: "Font %@")
      }
      /// Image %@
      internal static func image(_ p1: Any) -> String {
        return L10n.tr("Localizable", "about.credits.image", String(describing: p1), fallback: "Image %@")
      }
    }
    internal enum Support {
      /// ⚒ Feedback
      internal static let header = L10n.tr("Localizable", "about.support.header", fallback: "⚒ Feedback")
      /// Leave a review
      internal static let leaveReview = L10n.tr("Localizable", "about.support.leave-review", fallback: "Leave a review")
      /// Write email
      internal static let writeToEmail = L10n.tr("Localizable", "about.support.write-to-email", fallback: "Write email")
    }
  }
  internal enum AdhkarCollections {
    /// There is no specific order for reciting adhkar mentioned in the Sunnah of the Prophet, peace and blessings be upon him. The compiler of a given collection arranges the adhkar at their discretion, and the reader is likewise free to choose an order that is convenient for them.
    internal static let orderExplanationText = L10n.tr("Localizable", "adhkar-collections.order-explanation-text", fallback: "There is no specific order for reciting adhkar mentioned in the Sunnah of the Prophet, peace and blessings be upon him. The compiler of a given collection arranges the adhkar at their discretion, and the reader is likewise free to choose an order that is convenient for them.")
    /// Select collection
    internal static let selectionScreenTitle = L10n.tr("Localizable", "adhkar-collections.selection-screen-title", fallback: "Select collection")
    internal enum AzkarRu {
      /// This is a collection from the Azkar.ru website, which has been used in this application since its first release.
      internal static let description = L10n.tr("Localizable", "adhkar-collections.azkar-ru.description", fallback: "This is a collection from the Azkar.ru website, which has been used in this application since its first release.")
      /// Azkar.ru Website
      internal static let title = L10n.tr("Localizable", "adhkar-collections.azkar-ru.title", fallback: "Azkar.ru Website")
    }
    internal enum Hisn {
      /// A collection of morning and evening adhkar from the well-known compilation 'Fortress of the Muslim.'
      /// This collection is used in the vast majority of adhkar reading applications.
      internal static let description = L10n.tr("Localizable", "adhkar-collections.hisn.description", fallback: "A collection of morning and evening adhkar from the well-known compilation 'Fortress of the Muslim.'\nThis collection is used in the vast majority of adhkar reading applications.")
      /// Fortress
      internal static let shortTitle = L10n.tr("Localizable", "adhkar-collections.hisn.short-title", fallback: "Fortress")
      /// Hisn Al Muslim
      internal static let title = L10n.tr("Localizable", "adhkar-collections.hisn.title", fallback: "Hisn Al Muslim")
    }
    internal enum Onboarding {
      /// Based on numerous user requests, we have added a new collection of adhkar.
      internal static let step1 = L10n.tr("Localizable", "adhkar-collections.onboarding.step1", fallback: "Based on numerous user requests, we have added a new collection of adhkar.")
      /// Please select which collection you would like to use.
      internal static let step2 = L10n.tr("Localizable", "adhkar-collections.onboarding.step2", fallback: "Please select which collection you would like to use.")
      /// You can change your selection in the settings at any time.
      internal static let step3 = L10n.tr("Localizable", "adhkar-collections.onboarding.step3", fallback: "You can change your selection in the settings at any time.")
      /// Morning and Evening Adhkar Collections
      internal static let title = L10n.tr("Localizable", "adhkar-collections.onboarding.title", fallback: "Morning and Evening Adhkar Collections")
    }
  }
  internal enum Ads {
    /// Do not show again
    internal static let dontShowAgain = L10n.tr("Localizable", "ads.dont-show-again", fallback: "Do not show again")
  }
  internal enum Alerts {
    /// Select your favorite app icon
    internal static let checkoutIconPacks = L10n.tr("Localizable", "alerts.checkout-icon-packs", fallback: "Select your favorite app icon")
    /// Turn on notifications to receive reminders about morning and evening adhkar
    internal static let turnOnNotificationsAlert = L10n.tr("Localizable", "alerts.turn-on-notifications-alert", fallback: "Turn on notifications to receive reminders about morning and evening adhkar")
  }
  internal enum Category {
    /// Adhkar after salah
    internal static let afterSalah = L10n.tr("Localizable", "category.after-salah", fallback: "Adhkar after salah")
    /// Evening
    internal static let evening = L10n.tr("Localizable", "category.evening", fallback: "Evening")
    /// 100 Duas from the Quran and Sunnah
    internal static let hundredDua = L10n.tr("Localizable", "category.hundred-dua", fallback: "100 Duas from the Quran and Sunnah")
    /// Morning
    internal static let morning = L10n.tr("Localizable", "category.morning", fallback: "Morning")
    /// Bedtime
    internal static let night = L10n.tr("Localizable", "category.night", fallback: "Bedtime")
    /// Important adhkar
    internal static let other = L10n.tr("Localizable", "category.other", fallback: "Important adhkar")
  }
  internal enum Common {
    /// About
    internal static let about = L10n.tr("Localizable", "common.about", fallback: "About")
    /// Apply
    internal static let apply = L10n.tr("Localizable", "common.apply", fallback: "Apply")
    /// Back
    internal static let back = L10n.tr("Localizable", "common.back", fallback: "Back")
    /// Cancel
    internal static let cancel = L10n.tr("Localizable", "common.cancel", fallback: "Cancel")
    /// Complete
    internal static let complete = L10n.tr("Localizable", "common.complete", fallback: "Complete")
    /// Feedback
    internal static let contact = L10n.tr("Localizable", "common.contact", fallback: "Feedback")
    /// Continue
    internal static let `continue` = L10n.tr("Localizable", "common.continue", fallback: "Continue")
    /// Default
    internal static let `default` = L10n.tr("Localizable", "common.default", fallback: "Default")
    /// Dhikr #%@
    internal static func dhikr(_ p1: Any) -> String {
      return L10n.tr("Localizable", "common.dhikr", String(describing: p1), fallback: "Dhikr #%@")
    }
    /// Done
    internal static let done = L10n.tr("Localizable", "common.done", fallback: "Done")
    /// Enable
    internal static let enable = L10n.tr("Localizable", "common.enable", fallback: "Enable")
    /// Error
    internal static let error = L10n.tr("Localizable", "common.error", fallback: "Error")
    /// Language
    internal static let language = L10n.tr("Localizable", "common.language", fallback: "Language")
    /// Menu
    internal static let menu = L10n.tr("Localizable", "common.menu", fallback: "Menu")
    /// Next
    internal static let next = L10n.tr("Localizable", "common.next", fallback: "Next")
    /// No search results
    internal static let noSearchResults = L10n.tr("Localizable", "common.no-search-results", fallback: "No search results")
    /// OK
    internal static let ok = L10n.tr("Localizable", "common.ok", fallback: "OK")
    /// Open
    internal static let `open` = L10n.tr("Localizable", "common.open", fallback: "Open")
    /// Please select section
    internal static let pickSection = L10n.tr("Localizable", "common.pick-section", fallback: "Please select section")
    /// project
    internal static let project = L10n.tr("Localizable", "common.project", fallback: "project")
    /// Report a problem
    internal static let reportProblem = L10n.tr("Localizable", "common.report-problem", fallback: "Report a problem")
    /// Reset counter
    internal static let resetCounter = L10n.tr("Localizable", "common.reset-counter", fallback: "Reset counter")
    /// Restore
    internal static let restore = L10n.tr("Localizable", "common.restore", fallback: "Restore")
    /// Search
    internal static let search = L10n.tr("Localizable", "common.search", fallback: "Search")
    /// Send
    internal static let send = L10n.tr("Localizable", "common.send", fallback: "Send")
    /// Settings
    internal static let settings = L10n.tr("Localizable", "common.settings", fallback: "Settings")
    /// Share
    internal static let share = L10n.tr("Localizable", "common.share", fallback: "Share")
    /// Share Azkar App
    internal static let shareApp = L10n.tr("Localizable", "common.share-app", fallback: "Share Azkar App")
    /// Skip
    internal static let skip = L10n.tr("Localizable", "common.skip", fallback: "Skip")
    /// Theme
    internal static let theme = L10n.tr("Localizable", "common.theme", fallback: "Theme")
    /// Unable to Load
    internal static let unableToLoad = L10n.tr("Localizable", "common.unable-to-load", fallback: "Unable to Load")
    /// Version
    internal static let version = L10n.tr("Localizable", "common.version", fallback: "Version")
  }
  internal enum Credits {
    /// Animation %@
    internal static func animation(_ p1: Any) -> String {
      return L10n.tr("Localizable", "credits.animation", String(describing: p1), fallback: "Animation %@")
    }
    /// Russian translation, transcription, audiofiles (azkar.ru)
    internal static let azkarRu = L10n.tr("Localizable", "credits.azkar-ru", fallback: "Russian translation, transcription, audiofiles (azkar.ru)")
    /// ✏️ Fonts
    internal static let fonts = L10n.tr("Localizable", "credits.fonts", fallback: "✏️ Fonts")
    /// 🎨 Graphic materials and fonts
    internal static let graphics = L10n.tr("Localizable", "credits.graphics", fallback: "🎨 Graphic materials and fonts")
    /// 🧱 Open source libraries
    internal static let libraries = L10n.tr("Localizable", "credits.libraries", fallback: "🧱 Open source libraries")
    /// 🗃 Reference
    internal static let materials = L10n.tr("Localizable", "credits.materials", fallback: "🗃 Reference")
    /// Font of «King Fahd Complex for the Printing of the Holy Quran»
    internal static let quranComplexFont = L10n.tr("Localizable", "credits.quran-complex-font", fallback: "Font of «King Fahd Complex for the Printing of the Holy Quran»")
    /// 🔊 Sounds
    internal static let sounds = L10n.tr("Localizable", "credits.sounds", fallback: "🔊 Sounds")
    /// Source code of the app (github.com)
    internal static let sourceCode = L10n.tr("Localizable", "credits.source-code", fallback: "Source code of the app (github.com)")
    /// Information on used text, graphic, and other media materials.
    internal static let subtitle = L10n.tr("Localizable", "credits.subtitle", fallback: "Information on used text, graphic, and other media materials.")
    /// Credits
    internal static let title = L10n.tr("Localizable", "credits.title", fallback: "Credits")
    internal enum Studio {
      /// Instagram page
      internal static let instagramPage = L10n.tr("Localizable", "credits.studio.instagram-page", fallback: "Instagram page")
      /// Our Apps
      internal static let jawziyyaApps = L10n.tr("Localizable", "credits.studio.jawziyya-apps", fallback: "Our Apps")
      /// Telegram channel
      internal static let telegramChannel = L10n.tr("Localizable", "credits.studio.telegram-channel", fallback: "Telegram channel")
    }
  }
  internal enum Fadl {
    internal enum Source {
      /// Abu Daud
      internal static let abuDaud = L10n.tr("Localizable", "fadl.source.AbuDaud", fallback: "Abu Daud")
      /// al-Beyhaqi
      internal static let beyhaqi = L10n.tr("Localizable", "fadl.source.Beyhaqi", fallback: "al-Beyhaqi")
      /// Sahih al-Bukhari
      internal static let bukhari = L10n.tr("Localizable", "fadl.source.Bukhari", fallback: "Sahih al-Bukhari")
      /// Sahih Muslim
      internal static let muslim = L10n.tr("Localizable", "fadl.source.Muslim", fallback: "Sahih Muslim")
      /// Quran
      internal static let quran = L10n.tr("Localizable", "fadl.source.Quran", fallback: "Quran")
    }
  }
  internal enum Fonts {
    /// Monospaced
    internal static let monospaceFont = L10n.tr("Localizable", "fonts.monospace-font", fallback: "Monospaced")
    /// System font
    internal static let standardFont = L10n.tr("Localizable", "fonts.standard-font", fallback: "System font")
    /// Fonts
    internal static let title = L10n.tr("Localizable", "fonts.title", fallback: "Fonts")
    internal enum Arabic {
      /// Some fonts do not support displaying Arabic language vowels. Please look at the sample image to determine which font supports vowels.
      internal static let info = L10n.tr("Localizable", "fonts.arabic.info", fallback: "Some fonts do not support displaying Arabic language vowels. Please look at the sample image to determine which font supports vowels.")
    }
    internal enum `Type` {
      /// Decorative
      internal static let decorative = L10n.tr("Localizable", "fonts.type.decorative", fallback: "Decorative")
      /// Handwritten
      internal static let handwritten = L10n.tr("Localizable", "fonts.type.handwritten", fallback: "Handwritten")
      /// Sans Serif
      internal static let sansSerif = L10n.tr("Localizable", "fonts.type.sansSerif", fallback: "Sans Serif")
      /// Serif
      internal static let serif = L10n.tr("Localizable", "fonts.type.serif", fallback: "Serif")
      /// Standard
      internal static let standard = L10n.tr("Localizable", "fonts.type.standard", fallback: "Standard")
      internal enum Arabic {
        /// Kufi
        internal static let kufi = L10n.tr("Localizable", "fonts.type.arabic.kufi", fallback: "Kufi")
        /// Maghribi
        internal static let maghribi = L10n.tr("Localizable", "fonts.type.arabic.maghribi", fallback: "Maghribi")
        /// Modern
        internal static let modern = L10n.tr("Localizable", "fonts.type.arabic.modern", fallback: "Modern")
        /// Naskh
        internal static let naskh = L10n.tr("Localizable", "fonts.type.arabic.naskh", fallback: "Naskh")
        /// Other
        internal static let other = L10n.tr("Localizable", "fonts.type.arabic.other", fallback: "Other")
        /// Riqa
        internal static let riqa = L10n.tr("Localizable", "fonts.type.arabic.riqa", fallback: "Riqa")
        /// Thuluth
        internal static let thuluth = L10n.tr("Localizable", "fonts.type.arabic.thuluth", fallback: "Thuluth")
      }
    }
  }
  internal enum IconPack {
    internal enum Info {
      /// You have purchased this App Icon pack 🎉
      internal static let purchasedMessage = L10n.tr("Localizable", "icon_pack.info.purchased-message", fallback: "You have purchased this App Icon pack 🎉")
    }
    internal enum Standard {
      ///  
      internal static let description = L10n.tr("Localizable", "icon_pack.standard.description", fallback: " ")
      /// Standard icons pack
      internal static let title = L10n.tr("Localizable", "icon_pack.standard.title", fallback: "Standard icons pack")
    }
  }
  internal enum Notifications {
    /// Evening adhkar 🌄
    internal static let eveningNotificationTitle = L10n.tr("Localizable", "notifications.evening-notification-title", fallback: "Evening adhkar 🌄")
    /// Morning adhkar 🌅
    internal static let morningNotificationTitle = L10n.tr("Localizable", "notifications.morning-notification-title", fallback: "Morning adhkar 🌅")
    internal enum Jumua {
      /// Dua in Jumua day
      internal static let title = L10n.tr("Localizable", "notifications.jumua.title", fallback: "Dua in Jumua day")
    }
  }
  internal enum Onboarding {
    internal enum Collections {
      /// The app offers 2 adhkar collections
      internal static let message = L10n.tr("Localizable", "onboarding.collections.message", fallback: "The app offers 2 adhkar collections")
      /// Collections of adhkar
      internal static let title = L10n.tr("Localizable", "onboarding.collections.title", fallback: "Collections of adhkar")
    }
    internal enum Completion {
      /// Contact us on Telegram
      internal static let contact = L10n.tr("Localizable", "onboarding.completion.contact", fallback: "Contact us on Telegram")
      /// Thank you! If you need any help or want to share feedback, feel free to reach out to us on Telegram — we’re always here to assist you.
      internal static let message = L10n.tr("Localizable", "onboarding.completion.message", fallback: "Thank you! If you need any help or want to share feedback, feel free to reach out to us on Telegram — we’re always here to assist you.")
      /// Setup complete!
      internal static let title = L10n.tr("Localizable", "onboarding.completion.title", fallback: "Setup complete!")
    }
    internal enum ReadingMode {
      /// You have two reading modes available. The normal mode displays the text as sections. The combined mode shows the text line by line.
      internal static let message = L10n.tr("Localizable", "onboarding.reading-mode.message", fallback: "You have two reading modes available. The normal mode displays the text as sections. The combined mode shows the text line by line.")
      /// Reading mode
      internal static let title = L10n.tr("Localizable", "onboarding.reading-mode.title", fallback: "Reading mode")
    }
    internal enum Transliteration {
      /// Transliteration helps you read Arabic text using Latin letters.
      internal static let intro = L10n.tr("Localizable", "onboarding.transliteration.intro", fallback: "Transliteration helps you read Arabic text using Latin letters.")
      /// Transliteration
      internal static let title = L10n.tr("Localizable", "onboarding.transliteration.title", fallback: "Transliteration")
      internal enum Types {
        /// A strict scientific system for Latinizing Arabic script. It represents each Arabic letter unambiguously using diacritics. Suitable for precise academic reading.
        internal static let din31635 = L10n.tr("Localizable", "onboarding.transliteration.types.DIN31635", fallback: "A strict scientific system for Latinizing Arabic script. It represents each Arabic letter unambiguously using diacritics. Suitable for precise academic reading.")
      }
    }
    internal enum Welcome {
      /// Let me show you a brief guide to configuring the app’s features.
      /// 
      /// This will help you set it up for more convenient use.
      internal static let message = L10n.tr("Localizable", "onboarding.welcome.message", fallback: "Let me show you a brief guide to configuring the app’s features.\n\nThis will help you set it up for more convenient use.")
      /// Welcome to Azkar!
      internal static let title = L10n.tr("Localizable", "onboarding.welcome.title", fallback: "Welcome to Azkar!")
    }
  }
  internal enum Purchases {
    /// We are unable to display subscription options at this time. Please try again later.
    internal static let genericError = L10n.tr("Localizable", "purchases.generic-error", fallback: "We are unable to display subscription options at this time. Please try again later.")
    /// In-app Purchases Unavailable
    internal static let unavailable = L10n.tr("Localizable", "purchases.unavailable", fallback: "In-app Purchases Unavailable")
    /// This device cannot make purchases because billing is not available. Please ensure the store app is installed and you are signed in, then try again
    internal static let unavailableMessage = L10n.tr("Localizable", "purchases.unavailable-message", fallback: "This device cannot make purchases because billing is not available. Please ensure the store app is installed and you are signed in, then try again")
  }
  internal enum Read {
    /// narrated by
    internal static let narratedBy = L10n.tr("Localizable", "read.narrated-by", fallback: "narrated by")
    /// repeats
    internal static let repeats = L10n.tr("Localizable", "read.repeats", fallback: "repeats")
    /// source
    internal static let source = L10n.tr("Localizable", "read.source", fallback: "source")
    /// transliteration
    internal static let transcription = L10n.tr("Localizable", "read.transcription", fallback: "transliteration")
    /// translation
    internal static let translation = L10n.tr("Localizable", "read.translation", fallback: "translation")
  }
  internal enum ReadingCompletion {
    /// Mark as completed
    internal static let markAsCompleted = L10n.tr("Localizable", "reading_completion.mark_as_completed", fallback: "Mark as completed")
    /// You completed reading adhkar in this category
    internal static let subtitle = L10n.tr("Localizable", "reading_completion.subtitle", fallback: "You completed reading adhkar in this category")
    /// Completed!
    internal static let title = L10n.tr("Localizable", "reading_completion.title", fallback: "Completed!")
    /// You can mark your progress
    internal static let trackYourProgress = L10n.tr("Localizable", "reading_completion.track_your_progress", fallback: "You can mark your progress")
  }
  internal enum RemainingRepeats {
    /// %d times more
    internal static func few(_ p1: Int) -> String {
      return L10n.tr("Localizable", "remaining-repeats.few", p1, fallback: "%d times more")
    }
    /// %d times more
    internal static func other(_ p1: Int) -> String {
      return L10n.tr("Localizable", "remaining-repeats.other", p1, fallback: "%d times more")
    }
    /// 
    internal static let zero = L10n.tr("Localizable", "remaining-repeats.zero", fallback: "")
  }
  internal enum RepeatsNumber {
    /// %d times
    internal static func few(_ p1: Int) -> String {
      return L10n.tr("Localizable", "repeats_number.few", p1, fallback: "%d times")
    }
    /// done
    internal static let other = L10n.tr("Localizable", "repeats_number.other", fallback: "done")
    /// 
    internal static let zero = L10n.tr("Localizable", "repeats_number.zero", fallback: "")
  }
  internal enum Search {
    /// Adhkar
    internal static let suggestedAdhkar = L10n.tr("Localizable", "search.suggested-adhkar", fallback: "Adhkar")
    /// Search queries
    internal static let suggestedQueries = L10n.tr("Localizable", "search.suggested-queries", fallback: "Search queries")
  }
  internal enum Settings {
    /// Settings
    internal static let title = L10n.tr("Localizable", "settings.title", fallback: "Settings")
    /// Fun Features
    internal static let useFunFeatures = L10n.tr("Localizable", "settings.use_fun_features", fallback: "Fun Features")
    /// These are features which make Azkar app a bit beautiful but some people find useless and annoying.
    internal static let useFunFeaturesTip = L10n.tr("Localizable", "settings.use_fun_features_tip", fallback: "These are features which make Azkar app a bit beautiful but some people find useless and annoying.")
    internal enum Appearance {
      /// App language
      internal static let language = L10n.tr("Localizable", "settings.appearance.language", fallback: "App language")
      /// Themes and app icons
      internal static let subtitle = L10n.tr("Localizable", "settings.appearance.subtitle", fallback: "Themes and app icons")
      /// Appearance
      internal static let title = L10n.tr("Localizable", "settings.appearance.title", fallback: "Appearance")
      internal enum AppTheme {
        /// Flat
        internal static let flat = L10n.tr("Localizable", "settings.appearance.app-theme.flat", fallback: "Flat")
        /// E-reader
        internal static let reader = L10n.tr("Localizable", "settings.appearance.app-theme.reader", fallback: "E-reader")
        /// Themes
        internal static let title = L10n.tr("Localizable", "settings.appearance.app-theme.title", fallback: "Themes")
      }
      internal enum ColorScheme {
        internal enum Auto {
          /// The app automatically adapts to your device appearance setting.
          internal static let description = L10n.tr("Localizable", "settings.appearance.color-scheme.auto.description", fallback: "The app automatically adapts to your device appearance setting.")
          /// System
          internal static let title = L10n.tr("Localizable", "settings.appearance.color-scheme.auto.title", fallback: "System")
        }
        internal enum Dark {
          /// The app always uses a dark appearance
          internal static let description = L10n.tr("Localizable", "settings.appearance.color-scheme.dark.description", fallback: "The app always uses a dark appearance")
          /// Dark
          internal static let title = L10n.tr("Localizable", "settings.appearance.color-scheme.dark.title", fallback: "Dark")
        }
        internal enum Light {
          /// The app always uses a light appearance
          internal static let description = L10n.tr("Localizable", "settings.appearance.color-scheme.light.description", fallback: "The app always uses a light appearance")
          /// Light
          internal static let title = L10n.tr("Localizable", "settings.appearance.color-scheme.light.title", fallback: "Light")
        }
      }
      internal enum ColorTheme {
        /// Forest
        internal static let forest = L10n.tr("Localizable", "settings.appearance.color-theme.forest", fallback: "Forest")
        /// Color scheme
        internal static let header = L10n.tr("Localizable", "settings.appearance.color-theme.header", fallback: "Color scheme")
        /// Ink
        internal static let ink = L10n.tr("Localizable", "settings.appearance.color-theme.ink", fallback: "Ink")
        /// Purple Rose
        internal static let purpleRose = L10n.tr("Localizable", "settings.appearance.color-theme.purple-rose", fallback: "Purple Rose")
        /// Rose Quartz
        internal static let roseQuartz = L10n.tr("Localizable", "settings.appearance.color-theme.rose-quartz", fallback: "Rose Quartz")
        /// Sea
        internal static let sea = L10n.tr("Localizable", "settings.appearance.color-theme.sea", fallback: "Sea")
      }
    }
    internal enum Breaks {
      /// If enabled, Azkar will insert line-breaks after each sentence in dhikr/dua.
      internal static let info = L10n.tr("Localizable", "settings.breaks.info", fallback: "If enabled, Azkar will insert line-breaks after each sentence in dhikr/dua.")
      /// Use smart line-breaks
      internal static let title = L10n.tr("Localizable", "settings.breaks.title", fallback: "Use smart line-breaks")
    }
    internal enum Counter {
      /// Haptic feedback
      internal static let counterHaptics = L10n.tr("Localizable", "settings.counter.counter-haptics", fallback: "Haptic feedback")
      /// Ticker sound
      internal static let counterTicker = L10n.tr("Localizable", "settings.counter.counter-ticker", fallback: "Ticker sound")
      /// Go to next dhikr when repeats completed
      internal static let goToNextDhikr = L10n.tr("Localizable", "settings.counter.go-to-next-dhikr", fallback: "Go to next dhikr when repeats completed")
      /// If this option is enabled whenever you finish repeating a dhikr Azkar will show the next one
      internal static let goToNextDhikrTip = L10n.tr("Localizable", "settings.counter.go-to-next-dhikr-tip", fallback: "If this option is enabled whenever you finish repeating a dhikr Azkar will show the next one")
      /// Fine-tuning adhkar counter
      internal static let subtitle = L10n.tr("Localizable", "settings.counter.subtitle", fallback: "Fine-tuning adhkar counter")
      /// Counter
      internal static let title = L10n.tr("Localizable", "settings.counter.title", fallback: "Counter")
      internal enum CounterPosition {
        /// Center
        internal static let center = L10n.tr("Localizable", "settings.counter.counter-position.center", fallback: "Center")
        /// Left
        internal static let `left` = L10n.tr("Localizable", "settings.counter.counter-position.left", fallback: "Left")
        /// Right
        internal static let `right` = L10n.tr("Localizable", "settings.counter.counter-position.right", fallback: "Right")
        /// Position
        internal static let title = L10n.tr("Localizable", "settings.counter.counter-position.title", fallback: "Position")
      }
      internal enum CounterSize {
        /// Size
        internal static let title = L10n.tr("Localizable", "settings.counter.counter-size.title", fallback: "Size")
      }
      internal enum CounterType {
        /// Button
        internal static let button = L10n.tr("Localizable", "settings.counter.counter-type.button", fallback: "Button")
        /// This option allows you to switch type of the counter used.
        /// 
        /// If you choose 'button' Azkar will display a button at the bottom of reading screen. If you choose 'tap' there will be no visible indication, but you will be able to tap twice at any area to decrement the counter.
        internal static let info = L10n.tr("Localizable", "settings.counter.counter-type.info", fallback: "This option allows you to switch type of the counter used.\n\nIf you choose 'button' Azkar will display a button at the bottom of reading screen. If you choose 'tap' there will be no visible indication, but you will be able to tap twice at any area to decrement the counter.")
        /// Tap
        internal static let tap = L10n.tr("Localizable", "settings.counter.counter-type.tap", fallback: "Tap")
        /// Type
        internal static let title = L10n.tr("Localizable", "settings.counter.counter-type.title", fallback: "Type")
      }
    }
    internal enum Icon {
      /// Icon
      internal static let title = L10n.tr("Localizable", "settings.icon.title", fallback: "Icon")
      internal enum List {
        /// Azure
        internal static let azure = L10n.tr("Localizable", "settings.icon.list.azure", fallback: "Azure")
        /// Crater Cookie
        internal static let cookie = L10n.tr("Localizable", "settings.icon.list.cookie", fallback: "Crater Cookie")
        /// Dark night
        internal static let darkNight = L10n.tr("Localizable", "settings.icon.list.dark_night", fallback: "Dark night")
        /// Gold
        internal static let gold = L10n.tr("Localizable", "settings.icon.list.gold", fallback: "Gold")
        /// Ink
        internal static let ink = L10n.tr("Localizable", "settings.icon.list.ink", fallback: "Ink")
        /// MidJourney v0.0.1
        internal static let midjourney001 = L10n.tr("Localizable", "settings.icon.list.midjourney001", fallback: "MidJourney v0.0.1")
        /// Ramadan
        internal static let ramadan = L10n.tr("Localizable", "settings.icon.list.ramadan", fallback: "Ramadan")
      }
      internal enum Pro {
        /// Crescent
        internal static let crescent = L10n.tr("Localizable", "settings.icon.pro.crescent", fallback: "Crescent")
        /// Light
        internal static let light = L10n.tr("Localizable", "settings.icon.pro.light", fallback: "Light")
        /// Moon Serpentine
        internal static let serpentine = L10n.tr("Localizable", "settings.icon.pro.serpentine", fallback: "Moon Serpentine")
        /// Spring
        internal static let spring = L10n.tr("Localizable", "settings.icon.pro.spring", fallback: "Spring")
        /// Vibrant Crescent
        internal static let vibrantMoon = L10n.tr("Localizable", "settings.icon.pro.vibrantMoon", fallback: "Vibrant Crescent")
      }
    }
    internal enum Onboarding {
      /// How to use the app
      internal static let subtitle = L10n.tr("Localizable", "settings.onboarding.subtitle", fallback: "How to use the app")
      /// Onboarding
      internal static let title = L10n.tr("Localizable", "settings.onboarding.title", fallback: "Onboarding")
    }
    internal enum Reminders {
      /// Enable reminders
      internal static let enable = L10n.tr("Localizable", "settings.reminders.enable", fallback: "Enable reminders")
      /// Configuration
      internal static let header = L10n.tr("Localizable", "settings.reminders.header", fallback: "Configuration")
      /// Reminder types
      internal static let reminderTypesSectionTitle = L10n.tr("Localizable", "settings.reminders.reminder-types-section-title", fallback: "Reminder types")
      /// Morning and evening adhkar reminders
      internal static let subtitle = L10n.tr("Localizable", "settings.reminders.subtitle", fallback: "Morning and evening adhkar reminders")
      /// Time
      internal static let time = L10n.tr("Localizable", "settings.reminders.time", fallback: "Time")
      /// Reminders
      internal static let title = L10n.tr("Localizable", "settings.reminders.title", fallback: "Reminders")
      internal enum Jumua {
        /// Jumua supplication
        internal static let label = L10n.tr("Localizable", "settings.reminders.jumua.label", fallback: "Jumua supplication")
        /// Remind about dua in Jumua
        internal static let switchLabel = L10n.tr("Localizable", "settings.reminders.jumua.switch-label", fallback: "Remind about dua in Jumua")
      }
      internal enum MorningEvening {
        /// Evening reminder
        internal static let eveningLabel = L10n.tr("Localizable", "settings.reminders.morning-evening.evening-label", fallback: "Evening reminder")
        /// Morning & Evening adhkar
        internal static let label = L10n.tr("Localizable", "settings.reminders.morning-evening.label", fallback: "Morning & Evening adhkar")
        /// Morning reminder
        internal static let morningLabel = L10n.tr("Localizable", "settings.reminders.morning-evening.morning-label", fallback: "Morning reminder")
        /// Remind about morning & evening adhkar
        internal static let switchLabel = L10n.tr("Localizable", "settings.reminders.morning-evening.switch-label", fallback: "Remind about morning & evening adhkar")
      }
      internal enum NoAccess {
        /// Azkar App can not send notifications since the permission wasn't granted.
        internal static let general = L10n.tr("Localizable", "settings.reminders.no-access.general", fallback: "Azkar App can not send notifications since the permission wasn't granted.")
        /// Azkar App can send notifications but sounds switched off
        internal static let noSound = L10n.tr("Localizable", "settings.reminders.no-access.no-sound", fallback: "Azkar App can send notifications but sounds switched off")
        /// No permission to send notifications
        internal static let titleGeneral = L10n.tr("Localizable", "settings.reminders.no-access.title-general", fallback: "No permission to send notifications")
        /// No access to play sounds
        internal static let titleSound = L10n.tr("Localizable", "settings.reminders.no-access.title-sound", fallback: "No access to play sounds")
        /// Turn ON in Settings
        internal static let turnOnTitle = L10n.tr("Localizable", "settings.reminders.no-access.turn-on-title", fallback: "Turn ON in Settings")
      }
      internal enum Sounds {
        /// Custom
        internal static let custom = L10n.tr("Localizable", "settings.reminders.sounds.custom", fallback: "Custom")
        /// Sound
        internal static let sound = L10n.tr("Localizable", "settings.reminders.sounds.sound", fallback: "Sound")
        /// Standard
        internal static let standard = L10n.tr("Localizable", "settings.reminders.sounds.standard", fallback: "Standard")
        /// Sounds
        internal static let title = L10n.tr("Localizable", "settings.reminders.sounds.title", fallback: "Sounds")
      }
    }
    internal enum Text {
      /// Line spacing (arabic)
      internal static let arabicLineSpacing = L10n.tr("Localizable", "settings.text.arabic-line-spacing", fallback: "Line spacing (arabic)")
      /// Arabic font
      internal static let arabicTextFont = L10n.tr("Localizable", "settings.text.arabic-text-font", fallback: "Arabic font")
      /// Extra settings
      internal static let extra = L10n.tr("Localizable", "settings.text.extra", fallback: "Extra settings")
      /// Text size
      internal static let fontSize = L10n.tr("Localizable", "settings.text.font-size", fallback: "Text size")
      /// Translation language
      internal static let language = L10n.tr("Localizable", "settings.text.language", fallback: "Translation language")
      /// Line spacing
      internal static let lineSpacing = L10n.tr("Localizable", "settings.text.line-spacing", fallback: "Line spacing")
      /// Show tashkeel
      internal static let showTashkeel = L10n.tr("Localizable", "settings.text.show-tashkeel", fallback: "Show tashkeel")
      /// System Font
      internal static let standardFontName = L10n.tr("Localizable", "settings.text.standard-font-name", fallback: "System Font")
      /// Fonts, line spacing, text size
      internal static let subtitle = L10n.tr("Localizable", "settings.text.subtitle", fallback: "Fonts, line spacing, text size")
      /// Text
      internal static let title = L10n.tr("Localizable", "settings.text.title", fallback: "Text")
      /// Line spacing (translation)
      internal static let translationLineSpacing = L10n.tr("Localizable", "settings.text.translation-line-spacing", fallback: "Line spacing (translation)")
      /// Translation font
      internal static let translationTextFont = L10n.tr("Localizable", "settings.text.translation_text_font", fallback: "Translation font")
      /// Romanization Type
      internal static let transliteration = L10n.tr("Localizable", "settings.text.transliteration", fallback: "Romanization Type")
      /// System text size
      internal static let useSystemFontSize = L10n.tr("Localizable", "settings.text.use-system-font-size", fallback: "System text size")
      /// If this option is turned on Azkar app will use text size from iOS Settings (Settings — Display & Brightness — Text Size).
      /// If it's turned off you can choose desired text size below.
      internal static let useSystemFontSizeTip = L10n.tr("Localizable", "settings.text.use_system_font_size_tip", fallback: "If this option is turned on Azkar app will use text size from iOS Settings (Settings — Display & Brightness — Text Size).\nIf it's turned off you can choose desired text size below.")
      internal enum AdhkarCollectionsSource {
        /// Morning & Evening Adhkar Collection
        internal static let header = L10n.tr("Localizable", "settings.text.adhkar_collections_source.header", fallback: "Morning & Evening Adhkar Collection")
        /// Collection
        internal static let title = L10n.tr("Localizable", "settings.text.adhkar_collections_source.title", fallback: "Collection")
      }
      internal enum Content {
        /// Translation & Romanization
        internal static let header = L10n.tr("Localizable", "settings.text.content.header", fallback: "Translation & Romanization")
      }
      internal enum Fonts {
        /// Fonts
        internal static let header = L10n.tr("Localizable", "settings.text.fonts.header", fallback: "Fonts")
      }
      internal enum ReadingMode {
        /// Reading mode
        internal static let title = L10n.tr("Localizable", "settings.text.reading_mode.title", fallback: "Reading mode")
        internal enum LineByLine {
          /// Displays each line of the original text followed immediately by its translation.
          internal static let description = L10n.tr("Localizable", "settings.text.reading_mode.line_by_line.description", fallback: "Displays each line of the original text followed immediately by its translation.")
          /// Line by line
          internal static let title = L10n.tr("Localizable", "settings.text.reading_mode.line_by_line.title", fallback: "Line by line")
        }
        internal enum Normal {
          /// Shows the full original text, then the full translation in separate blocks.
          internal static let description = L10n.tr("Localizable", "settings.text.reading_mode.normal.description", fallback: "Shows the full original text, then the full translation in separate blocks.")
          /// Normal
          internal static let title = L10n.tr("Localizable", "settings.text.reading_mode.normal.title", fallback: "Normal")
        }
      }
    }
    internal enum Zikr {
      /// Adhkar reading settings
      internal static let subtitle = L10n.tr("Localizable", "settings.zikr.subtitle", fallback: "Adhkar reading settings")
      /// Adhkar
      internal static let title = L10n.tr("Localizable", "settings.zikr.title", fallback: "Adhkar")
    }
  }
  internal enum Share {
    /// Background
    internal static let backgroundHeader = L10n.tr("Localizable", "share.background-header", fallback: "Background")
    /// Font size
    internal static let fontSize = L10n.tr("Localizable", "share.font-size", fallback: "Font size")
    /// Image
    internal static let image = L10n.tr("Localizable", "share.image", fallback: "Image")
    /// Image saved
    internal static let imageSaved = L10n.tr("Localizable", "share.image_saved", fallback: "Image saved")
    /// Include Azkar logo
    internal static let includeAzkarLogo = L10n.tr("Localizable", "share.include-azkar-logo", fallback: "Include Azkar logo")
    /// Include text of benefit
    internal static let includeBenefit = L10n.tr("Localizable", "share.include-benefit", fallback: "Include text of benefit")
    /// Include Original Text
    internal static let includeOriginalText = L10n.tr("Localizable", "share.include-original-text", fallback: "Include Original Text")
    /// Include title
    internal static let includeTitle = L10n.tr("Localizable", "share.include-title", fallback: "Include title")
    /// Translation Text
    internal static let includeTranslation = L10n.tr("Localizable", "share.include-translation", fallback: "Translation Text")
    /// Transliteration Text
    internal static let includeTransliteration = L10n.tr("Localizable", "share.include-transliteration", fallback: "Transliteration Text")
    /// Share as
    internal static let shareAs = L10n.tr("Localizable", "share.share-as", fallback: "Share as")
    /// Shared from Azkar App
    internal static let sharedWithAzkar = L10n.tr("Localizable", "share.shared-with-azkar", fallback: "Shared from Azkar App")
    /// Show Extra Options
    internal static let showExtraOptions = L10n.tr("Localizable", "share.show-extra-options", fallback: "Show Extra Options")
    /// Text
    internal static let text = L10n.tr("Localizable", "share.text", fallback: "Text")
    /// Text alignment
    internal static let textAlignment = L10n.tr("Localizable", "share.text-alignment", fallback: "Text alignment")
    /// Text copied
    internal static let textCopied = L10n.tr("Localizable", "share.text_copied", fallback: "Text copied")
    internal enum BackgroundType {
      /// All
      internal static let all = L10n.tr("Localizable", "share.background-type.all", fallback: "All")
      /// Colour
      internal static let color = L10n.tr("Localizable", "share.background-type.color", fallback: "Colour")
      /// Images
      internal static let image = L10n.tr("Localizable", "share.background-type.image", fallback: "Images")
      /// Patterns
      internal static let pattern = L10n.tr("Localizable", "share.background-type.pattern", fallback: "Patterns")
    }
  }
  internal enum Subscribe {
    /// Cancel subscription
    internal static let cancel = L10n.tr("Localizable", "subscribe.cancel", fallback: "Cancel subscription")
    /// Purchase for %@
    internal static func purchaseFor(_ p1: Any) -> String {
      return L10n.tr("Localizable", "subscribe.purchase-for", String(describing: p1), fallback: "Purchase for %@")
    }
    /// Continue
    internal static let purchaseTitle = L10n.tr("Localizable", "subscribe.purchase-title", fallback: "Continue")
    /// Restore
    internal static let restore = L10n.tr("Localizable", "subscribe.restore", fallback: "Restore")
    /// Subscribe
    internal static let subscribeTitle = L10n.tr("Localizable", "subscribe.subscribe-title", fallback: "Subscribe")
    /// Some of the features only available for **Azkar Pro** users.
    internal static let title = L10n.tr("Localizable", "subscribe.title", fallback: "Some of the features only available for **Azkar Pro** users.")
    internal enum Billing {
      /// The subscription renews automatically until you turn it off
      internal static let autoRenewing = L10n.tr("Localizable", "subscribe.billing.auto-renewing", fallback: "The subscription renews automatically until you turn it off")
      /// One-time purchase
      internal static let lifetime = L10n.tr("Localizable", "subscribe.billing.lifetime", fallback: "One-time purchase")
      /// Billed monthly
      internal static let monthly = L10n.tr("Localizable", "subscribe.billing.monthly", fallback: "Billed monthly")
    }
    internal enum Features {
      internal enum ColorThemes {
        /// Colorful themes
        internal static let title = L10n.tr("Localizable", "subscribe.features.color-themes.title", fallback: "Colorful themes")
      }
      internal enum CustomFonts {
        /// 10+ custom fonts
        internal static let title = L10n.tr("Localizable", "subscribe.features.custom-fonts.title", fallback: "10+ custom fonts")
      }
      internal enum More {
        /// And all the new features to come!
        internal static let title = L10n.tr("Localizable", "subscribe.features.more.title", fallback: "And all the new features to come!")
      }
      internal enum ReminderSounds {
        /// Different reminder sounds
        internal static let title = L10n.tr("Localizable", "subscribe.features.reminder-sounds.title", fallback: "Different reminder sounds")
      }
    }
    internal enum Finish {
      /// Thank you for purchasing **Azkar Pro**!
      internal static let thanks = L10n.tr("Localizable", "subscribe.finish.thanks", fallback: "Thank you for purchasing **Azkar Pro**!")
    }
    internal enum Why {
      /// • All basic features of Azkar app available for **free**.
      /// 
      /// • Developing and publishing apps on the App Store takes money and time. Purchases help to cover these costs.
      /// 
      /// • Free apps without ads and purchases do not profit developers.
      /// 
      /// • We decided to provide Pro features instead of adding ads while keeping all the core functionality free.
      internal static let message = L10n.tr("Localizable", "subscribe.why.message", fallback: "• All basic features of Azkar app available for **free**.\n\n• Developing and publishing apps on the App Store takes money and time. Purchases help to cover these costs.\n\n• Free apps without ads and purchases do not profit developers.\n\n• We decided to provide Pro features instead of adding ads while keeping all the core functionality free.")
      /// Why?
      internal static let title = L10n.tr("Localizable", "subscribe.why.title", fallback: "Why?")
    }
  }
  internal enum Subscription {
    internal enum Period {
      /// month
      internal static let month = L10n.tr("Localizable", "subscription.period.month", fallback: "month")
      /// week
      internal static let week = L10n.tr("Localizable", "subscription.period.week", fallback: "week")
      /// year
      internal static let year = L10n.tr("Localizable", "subscription.period.year", fallback: "year")
    }
  }
  internal enum Text {
    internal enum Source {
      /// Abu Daud
      internal static let abudaud = L10n.tr("Localizable", "text.source.abudaud", fallback: "Abu Daud")
      /// Ahmad
      internal static let ahmad = L10n.tr("Localizable", "text.source.ahmad", fallback: "Ahmad")
      /// Beyhaqi
      internal static let beyhaqi = L10n.tr("Localizable", "text.source.beyhaqi", fallback: "Beyhaqi")
      /// al-Bukhari
      internal static let bukhari = L10n.tr("Localizable", "text.source.bukhari", fallback: "al-Bukhari")
      /// ad-Darimi
      internal static let darimi = L10n.tr("Localizable", "text.source.darimi", fallback: "ad-Darimi")
      /// Ibn Huzeyma
      internal static let ibnhuzeyma = L10n.tr("Localizable", "text.source.ibnhuzeyma", fallback: "Ibn Huzeyma")
      /// Ibn Majah
      internal static let ibnmaja = L10n.tr("Localizable", "text.source.ibnmaja", fallback: "Ibn Majah")
      /// Muslim
      internal static let muslim = L10n.tr("Localizable", "text.source.muslim", fallback: "Muslim")
      /// an-Nasai
      internal static let nasai = L10n.tr("Localizable", "text.source.nasai", fallback: "an-Nasai")
      /// Quran
      internal static let quran = L10n.tr("Localizable", "text.source.quran", fallback: "Quran")
      /// at-Tabarani
      internal static let tabarani = L10n.tr("Localizable", "text.source.tabarani", fallback: "at-Tabarani")
      /// at-Tirmidhi
      internal static let tirmidhi = L10n.tr("Localizable", "text.source.tirmidhi", fallback: "at-Tirmidhi")
    }
  }
  internal enum Updates {
    /// What's new?
    internal static let title = L10n.tr("Localizable", "updates.title", fallback: "What's new?")
  }
  internal enum Widgets {
    internal enum Completion {
      /// Keep track of your recitation progress directly on your lock screen. The widget updates automatically as your daily progress changes.
      internal static let description = L10n.tr("Localizable", "widgets.completion.description", fallback: "Keep track of your recitation progress directly on your lock screen. The widget updates automatically as your daily progress changes.")
      /// Recitation Progress
      internal static let title = L10n.tr("Localizable", "widgets.completion.title", fallback: "Recitation Progress")
    }
    internal enum Launcher {
      /// Quick launch
      internal static let title = L10n.tr("Localizable", "widgets.launcher.title", fallback: "Quick launch")
    }
    internal enum Virtues {
      /// Different Ayas and ahadith describing virtues of remembering Allah Almighty
      internal static let description = L10n.tr("Localizable", "widgets.virtues.description", fallback: "Different Ayas and ahadith describing virtues of remembering Allah Almighty")
      /// Virtues of dhikr
      internal static let title = L10n.tr("Localizable", "widgets.virtues.title", fallback: "Virtues of dhikr")
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
