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
    @ObservationIgnored private let authorization = CLServiceSession(authorization: .whenInUse)
    @ObservationIgnored private let background = CLBackgroundActivitySession()

    func start() {
        Task {
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
}
