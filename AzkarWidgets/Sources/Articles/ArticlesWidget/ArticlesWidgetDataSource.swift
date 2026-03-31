import Foundation
import ImageIO
import UIKit
import Entities
import GRDB

enum ArticlesWidgetDataSource {

    /// Read articles directly from the shared app-group database using
    /// synchronous GRDB calls (safe for widget timeline providers).
    static func fetchArticles(language: Language, limit: Int = 20) -> [Article] {
        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: WidgetAppGroup.identifier)
        else {
            return []
        }

        let databasePath = containerURL
            .appendingPathComponent("articles.db")
            .absoluteString

        guard let dbPool = try? DatabasePool(path: databasePath) else {
            return []
        }

        let lang = language.rawValue
        return (try? dbPool.read { db in
            try Article
                .filter(sql: "language = ?", arguments: [lang])
                .order(sql: "created_at DESC")
                .limit(limit)
                .fetchAll(db)
        }) ?? []
    }

    /// Download and downsample the cover image so the widget stores a
    /// display-sized asset instead of full-resolution bytes.
    static func loadImageData(from article: Article) async -> Data? {
        guard let imageLink = article.imageLink,
              let url = URL(string: imageLink)
        else {
            return nil
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
        request.timeoutInterval = 20

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode
        else {
            return nil
        }

        return downsampledImageData(from: data)
    }

    private static func downsampledImageData(
        from data: Data,
        maxPixelSize: CGFloat = 1_200
    ) -> Data? {
        let sourceOptions = [
            kCGImageSourceShouldCache: false
        ] as CFDictionary

        guard let imageSource = CGImageSourceCreateWithData(data as CFData, sourceOptions) else {
            return data.isEmpty ? nil : data
        }

        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ] as CFDictionary

        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, thumbnailOptions) else {
            return data.isEmpty ? nil : data
        }

        let image = UIImage(cgImage: thumbnail)
        return image.jpegData(compressionQuality: 0.82) ?? data
    }
}
