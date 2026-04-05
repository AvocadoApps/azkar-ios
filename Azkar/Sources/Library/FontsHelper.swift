// Copyright © 2021 Al Jawziyya. All rights reserved. 

import UIKit

enum FontsHelper {
    
    enum FontsHelperError: Error {
        case fileNotFound(URL)
        case fontManagerError(CFError)
    }
    
    /// Register all fonts from fonts directory.
    static func registerFonts() {
        do {
            let subdirectories = try FileManager.default.contentsOfDirectory(at: FileManager.default.fontsDirectoryURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            for subdirectory in subdirectories {
                registerFonts(in: subdirectory)
            }
        } catch {}
    }
    
    static func registerFonts(_ urls: [URL]) {
        urls.forEach(FontsHelper.registerFont(at:))
    }
    
    private static func registerFonts(in directory: URL) {
        let fileManager = FileManager.default
        do {
            let fontFiles = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            for file in fontFiles {
                registerFont(at: file)
            }
        } catch {}
    }
    
    /// Register font at given URL.
    static func registerFont(at url: URL) {
        guard let data = try? Data(contentsOf: url) , let provider = CGDataProvider(data: data as CFData) else {
            return
        }
        var error: Unmanaged<CFError>?
        if let font = CGFont(provider) {
            CTFontManagerRegisterGraphicsFont(font, &error)
        }
        _ = error
    }
    
    /// Register font at given path.
    static func registerFont(at path: String) {
        let url = URL(fileURLWithPath: path)
        registerFont(at: url)
    }
    
}
