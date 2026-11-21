import Observation
import GeoLogCore

/// Records this session's breadcrumb trail: thins the GPS stream, keeps the points for the map,
/// and hands unsaved ones to the store on `flush()`.
@Observable @MainActor
final class TrackRecorder {
    /// This session's line, split where GPS went quiet.
    private(set) var segments: [[TrackPoint]] = []

    @ObservationIgnored private var sampler: TrackSampler
    @ObservationIgnored private let maxGap: Double
    @ObservationIgnored private let store: TrackStore
    @ObservationIgnored private var points: [TrackPoint] = []
    @ObservationIgnored private var unsaved: [TrackPoint] = []

    init(settings: TrackSettings, store: TrackStore) {
        sampler = TrackSampler(settings: settings)
        maxGap = settings.sanitized.maxGap
        self.store = store
    }

    func offer(_ fix: LocationFix) {
        guard let point = sampler.offer(fix) else { return }
        points.append(point)
        unsaved.append(point)
        segments = Track.segments(points, maxGap: maxGap)
    }

    func flush() {
        do {
            try store.append(unsaved)
            unsaved.removeAll()
        } catch {
            print("Track save failed: \(error)")   // kept in `unsaved`: retried next flush
        }
    }
}
