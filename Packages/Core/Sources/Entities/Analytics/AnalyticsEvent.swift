import Entities

public struct AnalyticsEvent: Encodable {
    public let objectId: Int
    public let recordType: AnalyticsRecord.RecordType
    public let actionType: AnalyticsRecord.ActionType
    public let platform = "ios"

    public init(
        objectId: Int,
        recordType: AnalyticsRecord.RecordType,
        actionType: AnalyticsRecord.ActionType
    ) {
        self.objectId = objectId
        self.recordType = recordType
        self.actionType = actionType
    }
}
