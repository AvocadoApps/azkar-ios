// Copyright © 2021 Al Jawziyya. All rights reserved. 

import Foundation

public struct TranslationFont: Codable, Identifiable, Hashable, AppFont {
    
    public enum FontType: Int, Codable, Equatable, AppFontStyle {
        case serif, sansSerif, handwritten, decorative, additional
        
        public var key: String {
            "\(self)"
        }
    }
    
    public var id: String {
        postscriptName
    }
    
    public var style: AppFontStyle {
        type
    }
    
    public let name: String
    public var referenceName: String = STANDARD_FONT_REFERENCE_NAME
    public let postscriptName: String
    public let isStandardPackFont: Bool?
    public var type: FontType = .serif
    private var isCyrillic: Int?
    public var sizeAdjustment: Float?
    public var lineAdjustment: Float?
    
    public var supportsCyrillicCharacters: Bool {
        isCyrillic == 1
    }
    
    public static var placeholder: TranslationFont {
        return systemFont
    }
}

public extension TranslationFont {
    
    static var standardFonts: [TranslationFont] {
        [systemFont, courier, iowanOldStyle, baskerville]
    }
    
    static var systemFont: TranslationFont {
        TranslationFont(
            name: String(localized: "settings.text.standard-font-name"),
            postscriptName: "",
            isStandardPackFont: true,
            type: .sansSerif,
            isCyrillic: 1
        )
    }
    
    static var courier: TranslationFont {
        TranslationFont(
            name: "Courier New",
            postscriptName: "CourierNewPSMT",
            isStandardPackFont: true,
            isCyrillic: 1
        )
    }
    
    static var iowanOldStyle: TranslationFont {
        TranslationFont(
            name: "Iowan Old Style",
            postscriptName: "IowanOldStyle-Roman",
            isStandardPackFont: true,
            isCyrillic: 1
        )
    }
    
    static var baskerville: TranslationFont {
        TranslationFont(
            name: "Baskerville",
            postscriptName: "Baskerville",
            isStandardPackFont: true,
            isCyrillic: 1
        )
    }
    
}
