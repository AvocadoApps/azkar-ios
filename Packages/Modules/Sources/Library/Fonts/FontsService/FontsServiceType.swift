// Copyright © 2021 Al Jawziyya. All rights reserved. 

import Foundation

public enum FontsType {
    case arabic, translation

    public static let baseURL = URL(string: "https://storage.yandexcloud.net/azkar/fonts/")!

    public var url: URL {
        switch self {
        case .arabic:
            return Self.baseURL.appendingPathComponent("arabic_fonts.json")
        case .translation:
            return Self.baseURL.appendingPathComponent("translation_fonts.json")
        }
    }
}

public protocol FontsServiceType {
    func loadFonts<T: AppFont & Decodable>(of type: FontsType) async throws -> [T]
    func loadFont(url: URL) async throws -> [URL]
}
