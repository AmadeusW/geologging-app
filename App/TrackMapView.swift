import SwiftUI
import MapKit
import GeoLogCore

/// MapKit does the work: user dot, heading, camera follow, tiles. We only declare the layers:
///   1. past sessions (faint blue)  2. this session (orange)  3. logged entries (icons)
struct TrackMapView: View {
    let pastSegments: [[TrackPoint]]
    let sessionSegments: [[TrackPoint]]
    let markers: [LogMarker]

    @State private var camera = MapCameraPosition.userLocation(followsHeading: true, fallback: .automatic)

    var body: some View {
        Map(position: $camera) {
            UserAnnotation()

            ForEach(pastSegments.indices, id: \.self) { i in
                MapPolyline(coordinates: pastSegments[i].map(\.coordinate))
                    .stroke(.blue.opacity(0.5), lineWidth: 3)
            }
            ForEach(sessionSegments.indices, id: \.self) { i in
                MapPolyline(coordinates: sessionSegments[i].map(\.coordinate))
                    .stroke(.orange, lineWidth: 4)
            }
            ForEach(markers) { marker in
                Annotation(marker.label, coordinate: marker.coordinate) {
                    MarkerIcon(emoji: marker.emoji)
                }
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .mapControls {
            MapUserLocationButton()   // re-centres after panning
            MapCompass()
        }
        .preferredColorScheme(.dark)
    }
}

private struct MarkerIcon: View {
    let emoji: String

    var body: some View {
        Text(emoji)
            .font(.title3)
            .padding(6)
            .background(.white, in: .circle)
    }
}

private extension TrackPoint {
    var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
}

private extension LogMarker {
    var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
}
