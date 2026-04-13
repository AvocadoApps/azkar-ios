// Copyright © 2021 Al Jawziyya. All rights reserved. 

import Foundation

/// Represents content language
/// .rawValue is ISO 639-1 identifier.
public enum Language: String, Codable, CaseIterable, Identifiable, Hashable {
    case arabic = "ar"
    case turkish = "tr"
    case english = "en"
    case russian = "ru"
    case georgian = "ka"
    case chechen = "che"
    case ingush = "inh"
    case uzbek = "uz"
    case kyrgyz = "ky"
    case kazakh = "kz"
    case tatar = "tat"
    
    /// A language to use in certain cases when content is not available for selected language.
    public var fallbackLanguage: Language {
        switch self {
        case .chechen, .ingush, .kyrgyz, .kazakh, .tatar: return .russian
        case .arabic, .georgian, .turkish: return .english
        case .uzbek: return .turkish
        default: return self
        }
    }
    
    /// ISO 639-1 identifier
    public var id: String {
        rawValue
    }
    
    /// Non-localized language title.
    public var title: String {
        switch self {
        case .arabic:
            return "اللغة العربية"
        case .turkish:
            return "Türk dili"
        case .russian:
            return "Русский язык"
        case .english:
            return "English language"
        case .georgian:
            return "ქართული ენა"
        case .chechen:
            return "Нохчийн мотт"
        case .ingush:
            return "Гӏалгӏай мотт"
        case .uzbek:
            return "Оʻzbek tili"
        case .kyrgyz:
            return "Кыргыз тили"
        case .kazakh:
            return "Қазақ тілі"
        case .tatar:
            return "Татар теле"
        }
    }
}

public extension Language {
    static func getSystemLanguage() -> Language {
        let code: String
        if let preffedLocalizationCode = Bundle.main.preferredLocalizations.first?.components(separatedBy: "-").first {
            code = preffedLocalizationCode
        } else {
            code = Locale.current.languageCode ?? "en"
        }
        let id = String(code.lowercased().prefix(2))
        return Language(rawValue: id) ?? .english
    }
}
