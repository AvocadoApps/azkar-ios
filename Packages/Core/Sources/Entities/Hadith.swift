//  Created by Abdurahim Jauzee on 16.05.2020.
//  Copyright © 2020 Al Jawziyya. All rights reserved.

import Foundation

public struct Hadith: Identifiable, Hashable {
   
    public let id: Int
    public let text: String
    public let translation: String?
    public let source: String
    
    public init(
        id: Int,
        text: String,
        translation: String?,
        source: String
    ) {
        self.id = id
        self.text = text
        self.translation = translation
        self.source = source
    }

    public static var placeholder: Hadith {
        Hadith(
            id: 1,
            text: "Text",
            translation: "Translatioin",
            source: "Source 123"
        )
    }

}
