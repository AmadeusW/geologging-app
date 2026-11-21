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

    /// What each key would do if pressed after `prefix`: the label of the entry it completes,
    /// or nil if it is not a valid continuation. Used to draw the on-screen grid.
    public func legend(after prefix: [Key]) -> [Key: String] {
        var result: [Key: String] = [:]
        for key in Key.allCases {
            let path = prefix + [key]
            if let l = label(for: path) { result[key] = l }
        }
        return result
    }

    /// Layout from statemachine.md (keypad digits: 7 8 9 / 4 5 6 / 1 2 3).
    /// 7 mid-sequence cancels (see `SequenceMachine.cancelKey`); alone it logs "reset".
    /// 6 and 9 are entries themselves and commit on timeout unless a second key follows.
    public static let `default` = SequenceMap([
        [.topLeft]: "reset",
        [.middleLeft]: "flag",
        [.bottomLeft]: "bike path issue",

        [.topMiddle]: "traffic jam",
        [.center]: "clean baseline",

        [.middleRight]: "personal vehicle",
        [.middleRight, .middleRight]: "oversized vehicle",
        [.middleRight, .bottomRight]: "personal vehicle needs repair",
        [.middleRight, .bottomMiddle]: "antique vehicle",
        [.middleRight, .bottomLeft]: "personal vehicle idling",

        [.topRight]: "commercial vehicle",
        [.topRight, .topRight]: "truck",
        [.topRight, .topMiddle]: "bus",
        [.topRight, .bottomRight]: "truck needs repair",
        [.topRight, .bottomMiddle]: "bus needs repair",
        [.topRight, .bottomLeft]: "commercial vehicle idling",
    ])
}
