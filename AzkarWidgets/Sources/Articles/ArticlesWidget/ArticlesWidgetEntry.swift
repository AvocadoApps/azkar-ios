import Foundation
import WidgetKit
import Entities

struct ArticlesWidgetEntry: TimelineEntry {
    let date: Date
    let article: Article?
    let imageData: Data?

    static var placeholder: ArticlesWidgetEntry {
        ArticlesWidgetEntry(
            date: Date(),
            article: .placeholder(
                title: "The Virtues of Morning Remembrance",
                text: "The Prophet (peace be upon him) said: \"Whoever says 'SubhanAllahi wa bihamdihi' one hundred times a day, will be forgiven all his sins even if they were as much as the foam of the sea.\" This hadith highlights the immense reward...",
                imageLink: nil,
                imageResourceName: nil,
                coverImageFormat: .titleBackground
            ),
            imageData: nil
        )
    }
}
