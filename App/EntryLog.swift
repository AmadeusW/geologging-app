import Observation
import GeoLogCore

/// The in-memory log of everything committed this session. Append-only.
@Observable @MainActor
final class EntryLog {
    private(set) var entries: [LogEntry] = []

    var lastLabel: String { entries.last?.label ?? "-" }

    func add(_ entry: LogEntry) { entries.append(entry) }
}
