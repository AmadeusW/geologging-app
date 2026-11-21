import Observation
import GeoLogCore

/// Lines from earlier sessions, loaded once at launch off the main thread.
@Observable @MainActor
final class TrackHistory {
    private(set) var segments: [[TrackPoint]] = []

    func load(from store: TrackStore, maxGap: Double) async {
        segments = await Task.detached(priority: .utility) {
            store.loadPastSessions().flatMap { Track.segments($0, maxGap: maxGap) }
        }.value
    }
}
