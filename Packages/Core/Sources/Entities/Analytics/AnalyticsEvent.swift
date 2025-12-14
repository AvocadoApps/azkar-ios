import Entities

public struct AnalyticsEvent: Encodable, Hashable {
    public enum OccurrenceKind: String, Encodable {
        case first
        case `repeat`
    }
    
    public let objectId: Int
    public let recordType: AnalyticsRecord.RecordType
    public let actionType: AnalyticsRecord.ActionType
    public let platform = "ios"
    public let occurrenceKind: OccurrenceKind?

    public init(
        objectId: Int,
        recordType: AnalyticsRecord.RecordType,
        actionType: AnalyticsRecord.ActionType,
        occurrenceKind: OccurrenceKind?
    ) {
        self.objectId = objectId
        self.recordType = recordType
        self.actionType = actionType
        self.occurrenceKind = occurrenceKind
    }
}
