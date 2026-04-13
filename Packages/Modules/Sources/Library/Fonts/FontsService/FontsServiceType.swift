// Copyright © 2021 Al Jawziyya. All rights reserved. 

import Foundation

public enum FontsType {
    case arabic, translation
    
    public var url: URL {
        switch self {
        case .arabic:
            return URL(string: "https://storage.yandexcloud.net/azkar/fonts/arabic_fonts.json")!
        case .translation:
            return URL(string: "https://storage.yandexcloud.net/azkar/fonts/translation_fonts.json")!
        }
    }
}

public protocol FontsServiceType {
    func loadFonts<T: AppFont & Decodable>(of type: FontsType) async throws -> [T]
    func loadFont(url: URL) async throws -> [URL]
}
