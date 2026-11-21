import Foundation

public enum MachineEvent: Equatable {
    /// Key accepted; the sequence so far is `prefix` and can still grow.
    case advanced(prefix: [Key])
    /// A complete entry was recognised.
    case committed(label: String, keys: [Key])
    /// A partial (non-entry) sequence was dropped, by timeout or because the next key didn't fit.
    case abandoned(prefix: [Key])
    /// A key that starts no sequence was pressed with nothing pending.
    case ignored(Key)
}

/// Pure, deterministic state machine. Time is injected so it is fully testable.
///
/// The state is the sequence of keys pressed so far (`prefix`). Rules:
/// - A key that extends `prefix` to a valid path advances. If that path is an entry with no
///   longer extension it commits immediately; if it is an entry that can still grow, it
///   commits on timeout (or when the next key doesn't extend it).
/// - A key that doesn't fit: the pending prefix is committed (if it is an entry) or abandoned,
///   then the key is retried as the start of a new sequence.
/// - If `timeout` seconds pass since the last key, the pending prefix is committed/abandoned.
public struct SequenceMachine {
    public let map: SequenceMap
    public let timeout: TimeInterval
    /// Pressed mid-sequence, this key silently drops the pending prefix (nothing is logged).
    /// Pressed with nothing pending, it is handled like any other key.
    public let cancelKey: Key?
    public private(set) var prefix: [Key] = []
    private var lastPress: TimeInterval = 0

    public init(map: SequenceMap = .default, timeout: TimeInterval = 1.5, cancelKey: Key? = .topLeft) {
        self.map = map
        self.timeout = timeout
        self.cancelKey = cancelKey
    }

    public mutating func press(_ key: Key, at now: TimeInterval) -> [MachineEvent] {
        var events = tick(at: now)
        if key == cancelKey, !prefix.isEmpty {
            events.append(.abandoned(prefix: prefix))
            prefix = []
            return events
        }
        let candidate = prefix + [key]

        if map.isValidPath(candidate) {
            prefix = candidate
            lastPress = now
            if let label = map.label(for: candidate), !map.hasLongerExtension(of: candidate) {
                events.append(.committed(label: label, keys: candidate))
                prefix = []
            } else {
                events.append(.advanced(prefix: candidate))
            }
            return events
        }

        if prefix.isEmpty {
            events.append(.ignored(key))
            return events
        }

        events += flush()
        return events + press(key, at: now)
    }

    /// Call periodically; resolves a pending prefix once the timeout has elapsed.
    public mutating func tick(at now: TimeInterval) -> [MachineEvent] {
        guard !prefix.isEmpty, now - lastPress >= timeout else { return [] }
        return flush()
    }

    private mutating func flush() -> [MachineEvent] {
        defer { prefix = [] }
        if let label = map.label(for: prefix) {
            return [.committed(label: label, keys: prefix)]
        }
        return [.abandoned(prefix: prefix)]
    }
}
