import CoreLocation
import Observation
import GeoLogCore

/// Streams GPS fixes, including with the screen off, and keeps the latest one.
/// Permission and background keep-alive are handled by the two session objects below.
@Observable @MainActor
final class LocationService {
    private(set) var latest: LocationFix?
    private(set) var isDenied = false

    /// Called for every raw fix (about 1 Hz).
    @ObservationIgnored var onFix: ((LocationFix) -> Void)?

    // Held for their side effects: ask for permission / keep running in the background.
    @ObservationIgnored private var authorization: CLServiceSession?
    @ObservationIgnored private var background: CLBackgroundActivitySession?
    @ObservationIgnored private var task: Task<Void, Never>?

    var isRunning: Bool { task != nil }

    func start() {
        guard task == nil else { return }
        authorization = CLServiceSession(authorization: .whenInUse)
        background = CLBackgroundActivitySession()
        task = Task {
            do {
                for try await update in CLLocationUpdate.liveUpdates(.fitness) {
                    isDenied = update.authorizationDenied
                    guard let location = update.location else { continue }
                    let fix = LocationFix(latitude: location.coordinate.latitude,
                                          longitude: location.coordinate.longitude,
                                          horizontalAccuracy: location.horizontalAccuracy,
                                          timestamp: location.timestamp)
                    latest = fix
                    onFix?(fix)
                }
            } catch {
                print("Location updates ended: \(error)")
            }
        }
    }

    /// Ends updates and releases the sessions, which removes the location indicator and
    /// stops iOS from relaunching the app in the background.
    func stop() {
        task?.cancel()
        task = nil
        background?.invalidate()
        authorization?.invalidate()
        background = nil
        authorization = nil
    }
}
