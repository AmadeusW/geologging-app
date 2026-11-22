import SwiftUI

@main
struct GeoLogApp: App {
    @State private var session = Session()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView(session: session)
                .onChange(of: scenePhase, initial: true) { _, phase in
                    session.sceneChanged(to: phase)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
                    session.terminate()
                }
        }
    }
}
