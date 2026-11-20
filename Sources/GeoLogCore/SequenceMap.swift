import Foundation

/// Maps key sequences (e.g. topLeft then topMiddle) to the label recorded in the log.
public struct SequenceMap: Equatable {
    public let entries: [[Key]: String]

    public init(_ entries: [[Key]: String]) {
        precondition(entries.keys.allSatisfy { !$0.isEmpty }, "empty sequence")
        self.entries = entries
    }

    public func label(for keys: [Key]) -> String? { entries[keys] }

    /// True if some entry is strictly longer than `keys` and starts with it.
    public func hasLongerExtension(of keys: [Key]) -> Bool {
        entries.keys.contains { $0.count > keys.count && $0.starts(with: keys) }
    }

    /// True if `keys` is a complete entry or a prefix of one.
    public func isValidPath(_ keys: [Key]) -> Bool {
        label(for: keys) != nil || hasLongerExtension(of: keys)
    }

    /// PLACEHOLDER mapping - replace with the real categories.
    public static let `default` = SequenceMap([
        [.topLeft, .topMiddle]: "Example A",
        [.topLeft, .topRight]: "Example B",
        [.middleLeft]: "Example C",
        [.middleLeft, .middleRight]: "Example C+",   // C is also a prefix: commits on timeout
        [.center]: "Center",
        [.bottomRight, .bottomRight, .bottomRight]: "Triple",
    ])
}
