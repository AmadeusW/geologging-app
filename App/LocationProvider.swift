import CoreLocation
import GeoLogCore

/// Streams GPS fixes continuously (including with the screen locked) and keeps the latest one.
final class LocationProvider: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private(set) var latest: CLLocation?
    var onChange: (() -> Void)?

    var currentFix: LocationFix? {
        guard let l = latest else { return nil }
        return LocationFix(latitude: l.coordinate.latitude, longitude: l.coordinate.longitude,
                           horizontalAccuracy: l.horizontalAccuracy, timestamp: l.timestamp)
    }

    var statusText: String {
        switch manager.authorizationStatus {
        case .denied, .restricted: return "DENIED"
        case .notDetermined: return "asking"
        default: break
        }
        guard let l = latest else { return "no fix" }
        return String(format: "±%.0fm %.0fs", l.horizontalAccuracy, -l.timestamp.timeIntervalSinceNow)
    }

    func start() {
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
        manager.activityType = .fitness
        manager.pausesLocationUpdatesAutomatically = false
        manager.allowsBackgroundLocationUpdates = true      // needs UIBackgroundModes=location
        manager.showsBackgroundLocationIndicator = true
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        latest = locations.last
        onChange?()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
        onChange?()
    }
}
