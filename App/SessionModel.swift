import SwiftUI
import UIKit
import GeoLogCore

/// Owns the state machine, the in-memory log, the location provider and the dim/wake logic.
@MainActor
final class SessionModel: ObservableObject {
    @Published private(set) var isDimmed = false
    @Published private(set) var pending: [Key] = []
    @Published private(set) var entries: [LogEntry] = []
    @Published private(set) var lastLabel = "-"

    private var machine = SequenceMachine()
    private let location = LocationProvider()
    private let keyboard = KeyboardMonitor()
    private let haptics = UIImpactFeedbackGenerator(style: .medium)

    private var savedBrightness: CGFloat = UIScreen.main.brightness
    private var dimTask: Task<Void, Never>?
    private var tickTimer: Timer?
    private var flushTimer: Timer?
    private var dirty = false

    private let dimDelay: TimeInterval = 10
    private let flushInterval: TimeInterval = 60
    private let fileURL: URL = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyyMMdd-HHmmss"
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("geolog-\(f.string(from: Date())).csv")
    }()

    /// What each key does from the current state, for drawing the grid.
    var legend: [Key: String] { SequenceMap.default.legend(after: pending) }

    var statusLine: String {
        "entries \(entries.count) | last \(lastLabel) | gps \(location.statusText)"
    }

    init() {
        UIApplication.shared.isIdleTimerDisabled = true
        location.onChange = { [weak self] in self?.objectWillChange.send() }
        location.start()

        keyboard.onKey = { [weak self] key in Task { @MainActor in self?.press(key) } }
        keyboard.start()

        tickTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.handle(self?.machine.tick(at: Self.now) ?? []) }
        }
        flushTimer = Timer.scheduledTimer(withTimeInterval: flushInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.flush() }
        }
        scheduleDim()
    }

    private static var now: TimeInterval { ProcessInfo.processInfo.systemUptime }

    // MARK: Input (touch and keyboard share this path)

    /// Any input (touch or keyboard) brings the screen back and restarts the dim countdown.
    /// Touches while dimmed never reach here: the overlay in ContentView swallows them.
    func press(_ key: Key) {
        wake()
        handle(machine.press(key, at: Self.now))
    }

    private func handle(_ events: [MachineEvent]) {
        for event in events {
            switch event {
            case .committed(let label, let keys):
                entries.append(LogEntry(timestamp: Date(), label: label, keys: keys, fix: location.currentFix))
                lastLabel = label
                dirty = true
                haptics.impactOccurred()
            case .advanced, .abandoned, .ignored:
                break
            }
        }
        if !events.isEmpty || !pending.isEmpty { pending = machine.prefix }
    }

    // MARK: Dimming

    func wake() {
        restoreBrightness()
        isDimmed = false
        scheduleDim()
    }

    private func scheduleDim() {
        dimTask?.cancel()
        let delay = dimDelay
        dimTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.dim()
        }
    }

    private func dim() {
        savedBrightness = UIScreen.main.brightness
        UIScreen.main.brightness = 0
        isDimmed = true
    }

    private func restoreBrightness() {
        if isDimmed { UIScreen.main.brightness = savedBrightness }
    }

    func scenePhaseChanged(_ phase: ScenePhase) {
        switch phase {
        case .active:
            if isDimmed { UIScreen.main.brightness = 0 } else { scheduleDim() }
        default:
            restoreBrightness()   // never leave the system dimmed outside the app
            flush()
        }
    }

    // MARK: Persistence (in memory, flushed to a CSV every minute)

    func flush() {
        guard dirty else { return }
        do {
            try CSV.render(entries).write(to: fileURL, atomically: true, encoding: .utf8)
            dirty = false
        } catch {
            print("CSV flush failed: \(error)")
        }
    }
}
