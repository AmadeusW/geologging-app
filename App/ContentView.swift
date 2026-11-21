import SwiftUI
import GeoLogCore

/// Layout only: status line, key grid, map, and the black overlay shown while dimmed.
struct ContentView: View {
    let session: Session

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                Text(statusLine)
                    .font(.footnote.monospaced())
                    .foregroundStyle(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)

                KeyGrid(legend: session.sequence.legend,
                        pending: session.sequence.pending,
                        onPress: session.press)
                    .frame(maxHeight: 300)

                TrackMapView(pastSegments: session.history.segments,
                             sessionSegments: session.track.segments,
                             markers: MapMarker.markers(from: session.log.entries, styles: session.markerStyles))
                    .clipShape(.rect(cornerRadius: 16))
                    .frame(maxHeight: .infinity)
            }
            .padding()

            // While dimmed, this swallows the first tap and only wakes the screen, so a tap in a
            // pocket can't log an entry by accident.
            if session.dimmer.isDimmed {
                Color.black
                    .ignoresSafeArea()
                    .onTapGesture { session.dimmer.wake() }
            }
        }
        .background(.black)
        .statusBarHidden(session.dimmer.isDimmed)
        .persistentSystemOverlays(session.dimmer.isDimmed ? .hidden : .automatic)
        .sensoryFeedback(.impact, trigger: session.log.entries.count)
    }

    private var statusLine: String {
        let gps = session.location.isDenied ? "DENIED"
            : session.location.latest.map { "±\(Int($0.horizontalAccuracy))m" } ?? "no fix"
        return "entries \(session.log.entries.count) | last \(session.log.lastLabel) | gps \(gps)"
    }
}
