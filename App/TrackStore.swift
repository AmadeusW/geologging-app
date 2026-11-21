import Foundation
import GeoLogCore

/// Reads and writes breadcrumb files: `Documents/tracks/track-<stamp>.csv`, one per session.
/// Writing only ever appends; reading returns every earlier session.
struct TrackStore: Sendable {
    private let sessionURL = Storage.tracksDirectory.appending(path: "track-\(Storage.sessionStamp).csv")

    func append(_ points: [TrackPoint]) throws {
        guard !points.isEmpty else { return }
        let fm = FileManager.default
        try fm.createDirectory(at: Storage.tracksDirectory, withIntermediateDirectories: true)
        let isNew = !fm.fileExists(atPath: sessionURL.path)
        let lines = (isNew ? [TrackCSV.header] : []) + points.map(TrackCSV.line)
        let data = Data((lines.joined(separator: "\n") + "\n").utf8)

        if isNew {
            try data.write(to: sessionURL)
        } else {
            let handle = try FileHandle(forWritingTo: sessionURL)
            defer { try? handle.close() }
            try handle.seekToEnd()
            try handle.write(contentsOf: data)
        }
    }

    /// Points of every earlier session, oldest first, one array per file.
    func loadPastSessions() -> [[TrackPoint]] {
        let files = (try? FileManager.default.contentsOfDirectory(at: Storage.tracksDirectory,
                                                                  includingPropertiesForKeys: nil)) ?? []
        return files
            .filter { $0.pathExtension == "csv" && $0 != sessionURL }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .compactMap { try? String(contentsOf: $0, encoding: .utf8) }
            .map(TrackCSV.parse)
            .filter { !$0.isEmpty }
    }
}
