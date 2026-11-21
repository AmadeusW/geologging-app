import Foundation
import GeoLogCore

/// Persists the entry log as this session's CSV. Rewrites the whole file, only when entries
/// were added since the last save (the log is small and append-only).
final class EntryLogStore {
    private let url = Storage.documents.appending(path: "geolog-\(Storage.sessionStamp).csv")
    private var savedCount = 0

    func save(_ entries: [LogEntry]) {
        guard entries.count != savedCount else { return }
        do {
            try CSV.render(entries).write(to: url, atomically: true, encoding: .utf8)
            savedCount = entries.count
        } catch {
            print("Log save failed: \(error)")   // savedCount unchanged: retried next time
        }
    }
}
