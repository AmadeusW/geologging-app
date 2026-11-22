import Foundation
import Observation
import GeoLogCore

/// Feeds key presses into the `SequenceMachine`, drives its timeout, and reports each
/// completed entry through `onCommit`. Exposes what the grid needs to draw itself.
@Observable @MainActor
final class SequenceRunner {
    /// Keys pressed so far in the current sequence.
    private(set) var pending: [Key] = []

    /// Latest press feedback per key; `KeyGrid` animates a flash whenever a key's `id` changes.
    private(set) var flashes: [Key: KeyFlash] = [:]
    @ObservationIgnored private var flashCounter = 0

    @ObservationIgnored var onCommit: ((_ label: String, _ keys: [Key]) -> Void)?
    @ObservationIgnored private var machine = SequenceMachine()

    /// What each key would do if pressed now.
    var legend: [Key: String] { machine.legend }

    /// Seconds, from iOS Settings > GeoLog > Sequences (`sequenceTimeout`); re-read on every
    /// use so changes apply without relaunching. 5 s if never set.
    private static var timeout: TimeInterval {
        max(1, UserDefaults.standard.object(forKey: "sequenceTimeout") as? Double ?? 5)
    }

    func start() {
        Task {
            while true {
                try? await Task.sleep(for: .milliseconds(250))
                machine.timeout = Self.timeout
                handle(machine.tick(at: Self.now), pressed: nil)
            }
        }
    }

    func press(_ key: Key) {
        machine.timeout = Self.timeout
        handle(machine.press(key, at: Self.now), pressed: key)
    }

    private static var now: TimeInterval { ProcessInfo.processInfo.systemUptime }

    /// `.step` for a key that starts/continues a sequence (quick blink, so the next legend is
    /// visible); `.final` for the key that completes an entry (strong, then lingering).
    /// A final flash also fires when a pending entry commits by timeout.
    private func handle(_ events: [MachineEvent], pressed: Key?) {
        if let pressed, !events.isEmpty {
            if case .committed = events.last! {} else { flash(pressed, .step) }
        }
        for case .committed(let label, let keys) in events {
            if let last = keys.last { flash(last, .final) }
            onCommit?(label, keys)
        }
        if pending != machine.prefix { pending = machine.prefix }
    }

    private func flash(_ key: Key, _ kind: KeyFlash.Kind) {
        flashCounter += 1
        flashes[key] = KeyFlash(id: flashCounter, kind: kind)
    }
}

struct KeyFlash: Equatable {
    enum Kind { case step, final }
    let id: Int
    let kind: Kind
}
