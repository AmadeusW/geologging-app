import Foundation

/// A logged entry placed on the map. The emoji comes from `SequenceMap`, shared with the keypad.
public struct LogMarker: Equatable, Identifiable {
    public var id: Int            // index in the entry list: stable, since entries are append-only
    public var label: String
    public var timestamp: Date
    public var latitude: Double
    public var longitude: Double
    public var emoji: String

    /// Entries without a GPS fix cannot be placed and are skipped.
    public static func markers(from entries: [LogEntry], map: SequenceMap = .default) -> [LogMarker] {
        entries.enumerated().compactMap { i, e in
            guard let fix = e.fix else { return nil }
            return LogMarker(id: i, label: e.label, timestamp: e.timestamp,
                             latitude: fix.latitude, longitude: fix.longitude,
                             emoji: map.emoji(for: e.keys))
        }
    }
}
