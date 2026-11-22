import Foundation

/// Maps key sequences (e.g. topLeft then topMiddle) to the label recorded in the log.
public struct SequenceMap: Equatable {
    public let entries: [[Key]: String]
    /// key sequence -> emoji, used for both the on-screen keys and the map markers.
    /// Keyed by keys (not label) so entries sharing a label, e.g. "idling", can differ.
    public let emojis: [[Key]: String]

    /// key sequence -> short label written to the CSV (falls back to the display label).
    public let csvLabels: [[Key]: String]

    public static let fallbackEmoji = "📍"
    public static let cancelEmoji = "🚫"

    public init(_ entries: [[Key]: String], emojis: [[Key]: String] = [:],
                csvLabels: [[Key]: String] = [:]) {
        precondition(entries.keys.allSatisfy { !$0.isEmpty }, "empty sequence")
        self.entries = entries
        self.emojis = emojis
        self.csvLabels = csvLabels
    }

    /// One row of the table: the keys, the logged label, and its emoji.
    public struct Item {
        public let keys: [Key], label: String, emoji: String, csv: String
        public init(_ keys: [Key], _ label: String, _ emoji: String, csv: String) {
            self.keys = keys; self.label = label; self.emoji = emoji; self.csv = csv
        }
    }

    public init(items: [Item]) {
        self.init(Dictionary(uniqueKeysWithValues: items.map { ($0.keys, $0.label) }),
                  emojis: Dictionary(uniqueKeysWithValues: items.map { ($0.keys, $0.emoji) }),
                  csvLabels: Dictionary(uniqueKeysWithValues: items.map { ($0.keys, $0.csv) }))
    }

    public func emoji(for keys: [Key]) -> String { emojis[keys] ?? Self.fallbackEmoji }

    /// Short label for the CSV; falls back to the display label.
    public func csvLabel(for keys: [Key]) -> String? { csvLabels[keys] ?? entries[keys] }

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

    /// EDIT HERE: the single table for sequences, labels, emoji and CSV labels (`csv:`, keep short). The emoji is shown on the
    /// on-screen key (it follows the legend, so after pressing 6 the 6 key shows the pickup
    /// truck) and on the map marker for that key sequence.
    /// Layout from statemachine.md (keypad digits: 7 8 9 / 4 5 6 / 1 2 3).
    /// 7 mid-sequence cancels (see `SequenceMachine.cancelKey`); alone it logs "reset".
    /// 6 and 9 are entries themselves and commit on timeout unless a second key follows.
    /// Keys 2 and 3 are unassigned.
    public static let `default` = SequenceMap(items: [
        .init([.topLeft],     "reset",           "❌", csv: "reset"),
        .init([.middleLeft],  "flag",            "🚩", csv: "flag"),
        .init([.bottomLeft],  "bike path issue", "🚲", csv: "bike-issue"),

        .init([.topMiddle],   "traffic jam",     "🚦", csv: "traffic-jam"),
        .init([.center],      "clean baseline",  "🌳", csv: "baseline"),

        .init([.middleRight],                  "personal",               "🚗", csv: "personal"),
        .init([.middleRight, .middleRight],    "oversized",              "🛻", csv: "personal-oversized"),
        .init([.middleRight, .bottomRight],    "needs repair",  "🔧", csv: "personal-repair"),
        .init([.middleRight, .bottomMiddle],   "antique",                "🏎️", csv: "personal-antique"),
        .init([.middleRight, .bottomLeft],     "idling",        "💨", csv: "personal-idling"),

        .init([.topRight],                     "commercial",             "🚚", csv: "commercial"),
        .init([.topRight, .topRight],          "truck",                          "🚛", csv: "truck"),
        .init([.topRight, .topMiddle],         "bus",                            "🚌", csv: "bus"),
        .init([.topRight, .bottomRight],       "truck needs repair",             "🔧", csv: "truck-repair"),
        .init([.topRight, .bottomMiddle],      "bus needs repair",               "🔧", csv: "bus-repair"),
        .init([.topRight, .bottomLeft],        "idling",      "💨", csv: "commercial-idling"),
    ])
}
