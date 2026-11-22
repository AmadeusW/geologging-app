import Foundation
import Observation
import GeoLogCore

/// Feeds key presses into the `SequenceMachine`, drives its timeout, and reports each
/// completed entry through `onCommit`. Exposes what the grid needs to draw itself.
@Observable @MainActor
final class SequenceRunner {
    /// Keys pressed so far in the current sequence, as displayed. After a commit this keeps
    /// showing the old state until the final flash is over, so you see what you pressed.
    private(set) var pending: [Key] = []

    /// What each key would do, as displayed (same hold as `pending`).
    private(set) var legend: [Key: String] = SequenceMachine().legend
    @ObservationIgnored private var holdTask: Task<Void, Never>?

    /// Latest press feedback per key; `KeyGrid` animates a flash whenever a key's `id` changes.
    private(set) var flashes: [Key: KeyFlash] = [:]
    @ObservationIgnored private var flashCounter = 0

    @ObservationIgnored var onCommit: ((_ label: String, _ keys: [Key]) -> Void)?
    @ObservationIgnored private var machine = SequenceMachine()

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
        endHold()
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
        if holdTask == nil {
            if events.contains(where: { if case .committed = $0 { true } else { false } }) {
                // Keep the old legend under the final flash, then show the new state.
                let total = KeyAppearance.finalFlashDuration
                holdTask = Task { [weak self] in
                    try? await Task.sleep(for: .seconds(total))
                    guard !Task.isCancelled else { return }
                    self?.endHold()
                }
            } else {
                syncDisplay()
            }
        }
    }

    private func endHold() {
        guard holdTask != nil else { return }
        holdTask?.cancel()
        holdTask = nil
        syncDisplay()
    }

    private func syncDisplay() {
        if pending != machine.prefix { pending = machine.prefix }
        let current = machine.legend
        if legend != current { legend = current }
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
