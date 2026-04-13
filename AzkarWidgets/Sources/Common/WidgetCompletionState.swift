import Foundation

struct CompletionState: OptionSet, Equatable {
    let rawValue: Int

    static let morning = CompletionState(rawValue: 1 << 0)
    static let evening = CompletionState(rawValue: 1 << 1)
    static let night = CompletionState(rawValue: 1 << 2)

    static let none: CompletionState = []
    static let morningEvening: CompletionState = [.morning, .evening]
    static let all: CompletionState = [.morning, .evening, .night]
}
