import Foundation
import os

/// Lightweight, greppable logging for the adhkar search pipeline.
///
/// Every message is tagged with `[AzkarSearch]` so it can be filtered in the
/// Xcode console or `Console.app`. Logs go through `os.Logger` (subsystem
/// `io.jawziyya.azkar-app`, category `search`) and are also printed to stdout so
/// they show up in plain `print`-style debugging too.
///
/// To capture a full session to share for debugging, filter the Xcode console
/// (or `Console.app`) by `[AzkarSearch]`.
public enum SearchLog {

    /// Toggle to silence all search logging without removing the call sites.
    public static var isEnabled = true

    private static let logger = Logger(subsystem: "io.jawziyya.azkar-app", category: "search")

    public static func log(
        _ message: @autoclosure () -> String,
        function: String = #function
    ) {
        guard isEnabled else { return }
        let line = "[AzkarSearch] \(function) — \(message())"
        logger.debug("\(line, privacy: .public)")
        print(line)
    }
}
