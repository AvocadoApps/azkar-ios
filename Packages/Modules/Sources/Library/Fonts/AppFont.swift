// Copyright © 2021 Al Jawziyya. All rights reserved.

import Foundation

public let STANDARD_FONT_REFERENCE_NAME = "standard-font-reference-name"

public protocol AppFontStyle {
    var key: String { get }
}

public protocol AppFont {
    var id: String { get }
    var style: AppFontStyle { get }
    var name: String { get }
    var referenceName: String { get }
    var postscriptName: String { get }
    var sizeAdjustment: Float? { get }
    var lineAdjustment: Float? { get }
    var isStandardPackFont: Bool? { get }
}
