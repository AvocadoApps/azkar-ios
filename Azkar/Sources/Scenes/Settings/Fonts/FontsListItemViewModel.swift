// Copyright © 2021 Al Jawziyya. All rights reserved. 

import SwiftUI
import Entities
import Library

struct AppFontViewModel: Identifiable, Equatable, Hashable {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
    }
    
    static func == (lhs: AppFontViewModel, rhs: AppFontViewModel) -> Bool {
        lhs.id == rhs.id
    }
    
    private static let filesBaseURL = FontsType.baseURL.appendingPathComponent("files")
    
    let id = UUID()
    let font: AppFont
    let name: String
    let imageURL: URL?
    let zipFileURL: URL?
    let supportsTashkeel: Bool?
    let supportsCyrillicCharacters: Bool?
    
    init(font: AppFont, language: Language) {
        self.font = font
        name = font.name
        var supportsTashkeel: Bool?
        var supportsCyrillicCharacters: Bool?
        var langIdSuffix = ""
        
        if let arabicFont = font as? ArabicFont {
            langIdSuffix = ""
            supportsTashkeel = arabicFont.hasTashkeelSupport
        } else if let translationFont = font as? TranslationFont {
            supportsCyrillicCharacters = translationFont.supportsCyrillicCharacters
            switch language {
            case .arabic: langIdSuffix = "_en"
            default: langIdSuffix = "_" + language.id
            }
        }
        
        self.supportsTashkeel = supportsTashkeel
        self.supportsCyrillicCharacters = supportsCyrillicCharacters
        
        let referenceName = font.referenceName
        if referenceName != STANDARD_FONT_REFERENCE_NAME {
            imageURL = AppFontViewModel.filesBaseURL.appendingPathComponent("\(referenceName)/\(referenceName)\(langIdSuffix).png")
            zipFileURL = AppFontViewModel.filesBaseURL.appendingPathComponent(referenceName).appendingPathComponent("\(referenceName).zip")
        } else {
            imageURL = nil
            zipFileURL = nil
        }
    }
    
}
