import Foundation
import SwiftUI

public enum AdSize: String, Codable, Hashable {
    case minimal
    case regular
}

public enum AdImageMode: String, Codable, Hashable {
    case icon, background
}

public struct Ad: Identifiable, Codable, Hashable {
    public let id: Int
    public let size: AdSize
    public var title: String?
    public var body: String?
    public var actionTitle: String?
    public let actionLink: URL
    public var imageLink: URL?
    public var imageMode: AdImageMode?
    public var backgroundColor: String?
    public var foregroundColor: String?
    public var accentColor: String?
    public var language = Language.english
    public var createdAt = Date()
    public var updatedAt = Date()
    public var beginDate = Date()
    public var expireDate = Date()
    public var isHidden = false
}

public extension Ad {
    static var telegramBotDemo: Ad {
        Ad(
            id: Int.random(in: -100 ... 0),
            size: .regular,
            title: "Did you hear about our bot?",
            body: "We created a Telegram bot which helps you download free books",
            actionLink: URL(string: "https://t.me/kutubist_bot")!,
            imageLink: URL(string: "https://images.unsplash.com/photo-1655388333786-6b8270e2e154?q=80&w=3131&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"),
            imageMode: .background
        )
    }
    
    static var hotelsDemo: Ad {
        Ad(
            id: Int.random(in: -100 ... 0),
            size: .minimal,
            title: "Are you traveling?",
            body: "Consider using our hotel room search service",
            actionTitle: "Find Hotel",
            actionLink: URL(string: "https://t.me/kutubist_bot")!,
            imageLink: URL(string: "https://images.unsplash.com/photo-1655388333786-6b8270e2e154?q=80&w=3131&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D")!,
            imageMode: .icon
        )
    }
    
    static var ticketsDemo: Ad {
        Ad(
            id: Int.random(in: -100 ... 0),
            size: .minimal,
            title: "Are you traveling?",
            body: "Consider using our ticket search service",
            actionLink: URL(string: "https://t.me/kutubist_bot")!
        )
    }
}
