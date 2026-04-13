import Foundation
import AzkarServices

actor LocalAnalyticsRecorder {

    private let store: LocalAnalyticsStore
    private let commonMetadata: () -> [String: Any]
    private var sessionId: String?

    init(
        store: LocalAnalyticsStore,
        commonMetadata: @escaping () -> [String: Any] = { [:] }
    ) {
        self.store = store
        self.commonMetadata = commonMetadata
    }

    func setSessionId(_ sessionId: String?) {
        self.sessionId = sessionId
    }

    func recordEvent(
        name: String,
        metadata: [String: Any]? = nil,
        kind: LocalAnalyticsEventKind = .event
    ) async {
        do {
            try await store.recordEvent(
                name: name,
                kind: kind,
                metadata: sanitizeMetadata(mergedMetadata(metadata)),
                sessionId: sessionId,
                recordedAt: Date()
            )
        } catch {
            print("Failed to record local analytics event: \(error.localizedDescription)")
        }
    }

    func record(_ event: AppAnalyticsEvent) async {
        await recordEvent(
            name: event.name,
            metadata: event.metadata,
            kind: .event
        )
    }

    func recordScreen(screenName: String, className: String?) async {
        var metadata: [String: Any] = [:]
        metadata["class_name"] = className
        await recordEvent(name: screenName, metadata: metadata, kind: .screen)
    }

    func recordUserAttribute(_ type: UserAttributeType, value: String) async {
        await recordEvent(
            name: type.rawValue,
            metadata: ["value": value],
            kind: .userAttribute
        )
    }

    func cleanup(retainingEventsFor interval: TimeInterval) async {
        do {
            try await store.cleanupEvents(olderThan: interval)
        } catch {
            print("Failed to clean up local analytics events: \(error.localizedDescription)")
        }
    }

    private func sanitizeMetadata(_ metadata: [String: Any]?) -> [String: String] {
        guard let metadata else {
            return [:]
        }

        return metadata
            .sorted(by: { $0.key < $1.key })
            .prefix(24)
            .reduce(into: [String: String]()) { result, item in
                guard let value = sanitizeValue(item.value) else {
                    return
                }
                result[item.key] = value
            }
    }

    private func mergedMetadata(_ metadata: [String: Any]?) -> [String: Any] {
        var merged = commonMetadata()
        metadata?.forEach { key, value in
            merged[key] = value
        }
        return merged
    }

    private func sanitizeValue(_ value: Any) -> String? {
        switch value {
        case let value as String:
            return truncate(value)
        case let value as Bool:
            return value ? "true" : "false"
        case let value as Int:
            return String(value)
        case let value as Int64:
            return String(value)
        case let value as Double:
            return String(value)
        case let value as Float:
            return String(value)
        case let value as URL:
            return truncate(value.absoluteString)
        case let value as Date:
            return ISO8601DateFormatter().string(from: value)
        default:
            let description = String(describing: value)
            guard description.isEmpty == false, description != "nil" else {
                return nil
            }
            return truncate(description)
        }
    }

    private func truncate(_ value: String) -> String {
        String(value.prefix(120))
    }

}
