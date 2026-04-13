//  Copyright © 2020 Al Jawziyya. All rights reserved.

import SwiftUI

public struct ArabicFont: AppFont, Identifiable, Codable, Hashable {
    
    public enum FontType: Int, Codable, AppFontStyle {
        case naskh = 0, riqa = 1, thuluth = 2, kufi = 3, maghribi = 4, modern = 5, other = 6
        
        public var key: String {
            switch self {
            case .naskh: return "arabic.naskh"
            case .riqa: return "arabic.riqa"
            case .thuluth: return "arabic.thuluth"
            case .kufi: return "arabic.kufi"
            case .maghribi: return "arabic.maghribi"
            case .modern: return "arabic.modern"
            case .other: return "arabic.other"
            }
        }
    }
    
    public var id: String {
        postscriptName
    }
    
    public var style: AppFontStyle {
        type
    }
    
    public var name: String
    
    public var referenceName: String = STANDARD_FONT_REFERENCE_NAME
    
    public var postscriptName: String
    
    public let isStandardPackFont: Bool?
    
    public var sizeAdjustment: Float?
    
    public var lineAdjustment: Float?
    
    public var type: FontType = .naskh
    
    private var supportsTashkeel: Int? = 1
    
    public var hasTashkeelSupport: Bool {
        supportsTashkeel == 1
    }
    
}

public extension ArabicFont {
    
    static var standardFonts: [AppFont] {
        [systemArabic, adobe, KFGQP, noto, marhey]
    }
    
    static var systemArabic: ArabicFont {
        ArabicFont(
            name: String(localized: "settings.text.standard-font-name"),
            postscriptName: "",
            isStandardPackFont: true
        )
    }
    
    static var adobe: ArabicFont {
        ArabicFont(
            name: "Adobe",
            postscriptName: "AdobeArabic-Regular",
            isStandardPackFont: true
        )
    }
    
    static var KFGQP: ArabicFont {
        ArabicFont(
            name: "KFGQP",
            postscriptName: "KFGQPCUthmanicScriptHAFS",
            isStandardPackFont: true
        )
    }
    
    static var noto: ArabicFont {
        ArabicFont(
            name: "Noto Naskh",
            postscriptName: "NotoNaskhArabicUI",
            isStandardPackFont: true
        )
    }
    
    static var marhey: ArabicFont {
        ArabicFont(
            name: "Marhey",
            postscriptName: "Marhey",
            isStandardPackFont: true
        )
    }
    
}
