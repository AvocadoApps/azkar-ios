import Foundation
import WidgetKit
import Entities

struct VirtuesWidgetEntry: TimelineEntry {
    let date: Date
    let fadl: Fadl

    static var placeholder: VirtuesWidgetEntry {
        VirtuesWidgetEntry(date: Date(), fadl: Fadl.placeholder)
    }
}
