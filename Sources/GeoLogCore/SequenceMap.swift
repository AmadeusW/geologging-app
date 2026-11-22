import Foundation

/// Maps key sequences (e.g. topLeft then topMiddle) to the label recorded in the log.
public struct SequenceMap: Equatable {
    public let entries: [[Key]: String]
    /// key sequence -> emoji, used for both the on-screen keys and the map markers.
    /// Keyed by keys (not label) so entries sharing a label, e.g. "idling", can differ.
    public let emojis: [[Key]: String]

    public static let fallbackEmoji = "📍"
    public static let cancelEmoji = "🚫"

    public init(_ entries: [[Key]: String], emojis: [[Key]: String] = [:]) {
        precondition(entries.keys.allSatisfy { !$0.isEmpty }, "empty sequence")
        self.entries = entries
        self.emojis = emojis
    }

    /// One row of the table: the keys, the logged label, and its emoji.
    public struct Item {
        public let keys: [Key], label: String, emoji: String
        public init(_ keys: [Key], _ label: String, _ emoji: String) {
            self.keys = keys; self.label = label; self.emoji = emoji
        }
    }

    public init(items: [Item]) {
        self.init(Dictionary(uniqueKeysWithValues: items.map { ($0.keys, $0.label) }),
                  emojis: Dictionary(uniqueKeysWithValues: items.map { ($0.keys, $0.emoji) }))
    }

    public func emoji(for keys: [Key]) -> String { emojis[keys] ?? Self.fallbackEmoji }

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

    /// EDIT HERE: the single table for sequences, labels and emoji. The emoji is shown on the
    /// on-screen key (it follows the legend, so after pressing 6 the 6 key shows the pickup
    /// truck) and on the map marker for that key sequence.
    /// Layout from statemachine.md (keypad digits: 7 8 9 / 4 5 6 / 1 2 3).
    /// 7 mid-sequence cancels (see `SequenceMachine.cancelKey`); alone it logs "reset".
    /// 6 and 9 are entries themselves and commit on timeout unless a second key follows.
    /// Keys 2 and 3 are unassigned.
    public static let `default` = SequenceMap(items: [
        .init([.topLeft],     "reset",           "❌"),
        .init([.middleLeft],  "flag",            "🚩"),
        .init([.bottomLeft],  "bike path issue", "🚲"),

        .init([.topMiddle],   "traffic jam",     "🚦"),
        .init([.center],      "clean baseline",  "🌳"),

        .init([.middleRight],                  "personal",               "🚗"),
        .init([.middleRight, .middleRight],    "oversized",              "🛻"),
        .init([.middleRight, .bottomRight],    "needs repair",  "🔧"),
        .init([.middleRight, .bottomMiddle],   "antique",                "🏎️"),
        .init([.middleRight, .bottomLeft],     "idling",        "💨"),

        .init([.topRight],                     "commercial",             "🚚"),
        .init([.topRight, .topRight],          "truck",                          "🚛"),
        .init([.topRight, .topMiddle],         "bus",                            "🚌"),
        .init([.topRight, .bottomRight],       "truck needs repair",             "🔧"),
        .init([.topRight, .bottomMiddle],      "bus needs repair",               "🔧"),
        .init([.topRight, .bottomLeft],        "idling",      "💨"),
    ])
}
