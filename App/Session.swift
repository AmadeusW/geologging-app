import SwiftUI
import GeoLogCore

/// Composition root: creates the components and wires them together. No logic of its own.
///
///   keyboard / touch -> press -> sequence machine -> entry log (+ GPS fix) -> CSV
///   location -> track recorder -> track file          location -> map
@MainActor
final class Session {
    let keyboard = KeyboardInput()
    let sequence = SequenceRunner()
    let log = EntryLog()
    let location = LocationService()
    let dimmer = ScreenDimmer()
    let track: TrackRecorder
    let history = TrackHistory()

    private let logStore = EntryLogStore()
    private let trackStore = TrackStore()
    private let trackSettings: TrackSettings

    init() {
        trackSettings = ConfigFile<TrackSettings>(name: "track-settings.json").load()
        track = TrackRecorder(settings: trackSettings, store: trackStore)

        sequence.onCommit = { [log, location] label, keys in
            log.add(LogEntry(timestamp: Date(), label: label, keys: keys, fix: location.latest))
        }
        location.onFix = { [track] fix in track.offer(fix) }
    }

    private var started = false

    /// Only called when the app is in the foreground, so a background relaunch by the
    /// system never starts location tracking.
    func start() {
        guard !started, UIApplication.shared.applicationState == .active else { return }
        started = true
        location.start()
        sequence.start()
        Task { for await key in keyboard.keys { press(key) } }
        Task { await history.load(from: trackStore, maxGap: trackSettings.sanitized.maxGap) }
        Task {
            while true {
                try? await Task.sleep(for: .seconds(60))
                flush()
            }
        }
    }

    /// Touch and keyboard both come through here.
    func press(_ key: Key) {
        dimmer.wake()
        sequence.press(key)
    }

    func flush() {
        logStore.save(log.entries)
        track.flush()
    }

    /// App is being terminated: stop location so no background session outlives it.
    func terminate() {
        flush()
        location.stop()
    }

    func sceneChanged(to phase: ScenePhase) {
        dimmer.sceneChanged(to: phase)
        if phase != .active { flush() }
    }
}
