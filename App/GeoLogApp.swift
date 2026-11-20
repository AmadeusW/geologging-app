import SwiftUI

@main
struct GeoLogApp: App {
    @StateObject private var session = SessionModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(session)
                .onChange(of: scenePhase) { phase in session.scenePhaseChanged(phase) }
        }
    }
}
