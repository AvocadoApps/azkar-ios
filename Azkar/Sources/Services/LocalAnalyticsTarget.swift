import AzkarServices

final class LocalAnalyticsTarget: AnalyticsTarget {

    let deliveryPolicy: AnalyticsTargetDeliveryPolicy = .always

    private let recorder: LocalAnalyticsRecorder

    init(recorder: LocalAnalyticsRecorder) {
        self.recorder = recorder
    }

    func reportEvent(name: String, metadata: [String: Any]?) {
        Task {
            await recorder.recordEvent(name: name, metadata: metadata)
        }
    }

    func reportScreen(screenName: String, className: String?) {
        Task {
            await recorder.recordScreen(screenName: screenName, className: className)
        }
    }

    func setUserAttribute(_ type: UserAttributeType, value: String) {
        Task {
            await recorder.recordUserAttribute(type, value: value)
        }
    }

}
