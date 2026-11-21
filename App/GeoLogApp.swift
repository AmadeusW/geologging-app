import SwiftUI

@main
struct GeoLogApp: App {
    @State private var session = Session()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView(session: session)
                .task { session.start() }
                .onChange(of: scenePhase) { _, phase in session.sceneChanged(to: phase) }
        }
    }
}
