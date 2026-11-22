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
                        flashes: session.sequence.flashes,
                        onPress: session.press)

                TrackMapView(pastSegments: session.history.segments,
                             sessionSegments: session.track.segments,
                             markers: LogMarker.markers(from: session.log.entries))
                    .clipShape(.rect(cornerRadius: 16))
                    .frame(maxHeight: .infinity)
            }
            .padding()
            // Any touch (map pan/pinch/rotate included) restarts the dim countdown without
            // interfering with the views underneath.
            .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in session.dimmer.wake() })

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
        return "gps \(gps)"
    }
}
