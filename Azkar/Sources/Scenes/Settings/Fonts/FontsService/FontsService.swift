// Copyright © 2021 Al Jawziyya. All rights reserved. 

import Foundation
import Alamofire
import ZIPFoundation
import Library
import Extensions

struct FontsService: FontsServiceType {
    
    func loadFonts<T>(of type: FontsType) async throws -> [T] where T : AppFont, T : Decodable {
        let fontsListURL = type.url
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try await AF.request(
            fontsListURL,
            method: HTTPMethod.get,
            headers: ["Cache-Control": "max-age=3600"]
        )
        .asyncDecodable(of: [T].self, decoder: decoder)
    }
    
    func loadFont(url: URL) async throws -> [URL] {
        let fileManager = FileManager.default
        let folderURL = fileManager.fontsDirectoryURL
        let unzippedFolderURL = folderURL.appendingPathComponent(url.deletingPathExtension().lastPathComponent)
        let fileURL = folderURL.appendingPathComponent(url.lastPathComponent)
        let destination: DownloadRequest.Destination = { _, _ in
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            AF.download(url, to: destination)
                .response { response in
                    if let error = response.error?.underlyingError {
                        continuation.resume(throwing: error)
                    } else {
                        do {
                            try fileManager.unzipItem(at: fileURL, to: unzippedFolderURL)
                            let files = try fileManager.contentsOfDirectory(at: unzippedFolderURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                            try fileManager.removeItem(at: fileURL)
                            continuation.resume(returning: files)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                }
        }
    }
    
}
