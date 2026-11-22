import SwiftUI

@main
struct GeoLogApp: App {
    @State private var session = Session()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView(session: session)
                .onChange(of: scenePhase, initial: true) { _, phase in
                    if phase == .active { session.start() }
                    session.sceneChanged(to: phase)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
                    session.terminate()
                }
        }
    }
}
