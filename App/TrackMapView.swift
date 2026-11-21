import SwiftUI
import MapKit
import GeoLogCore

/// MapKit does the work: user dot, heading, camera follow, tiles. We only declare the layers:
///   1. past sessions (faint blue)  2. this session (orange)  3. logged entries (icons)
struct TrackMapView: View {
    let pastSegments: [[TrackPoint]]
    let sessionSegments: [[TrackPoint]]
    let markers: [MapMarker]

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
                    MarkerIcon(style: marker.style)
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
    let style: MarkerStyle

    var body: some View {
        Image(systemName: style.symbol)
            .foregroundStyle(Color(hex: style.colorHex))
            .padding(6)
            .background(.white, in: .circle)
    }
}

private extension TrackPoint {
    var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
}

private extension MapMarker {
    var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
}

private extension Color {
    /// `RRGGBB`; anything unparsable becomes white.
    init(hex: String) {
        let value = UInt32(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0xFFFFFF
        self.init(red: Double((value >> 16) & 0xFF) / 255,
                  green: Double((value >> 8) & 0xFF) / 255,
                  blue: Double(value & 0xFF) / 255)
    }
}
