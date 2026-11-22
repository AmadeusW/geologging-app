import Foundation
import Observation
import GeoLogCore

/// Feeds key presses into the `SequenceMachine`, drives its timeout, and reports each
/// completed entry through `onCommit`. Exposes what the grid needs to draw itself.
@Observable @MainActor
final class SequenceRunner {
    /// Keys pressed so far in the current sequence.
    private(set) var pending: [Key] = []

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
                handle(machine.tick(at: Self.now))
            }
        }
    }

    func press(_ key: Key) {
        machine.timeout = Self.timeout
        handle(machine.press(key, at: Self.now))
    }

    private static var now: TimeInterval { ProcessInfo.processInfo.systemUptime }

    private func handle(_ events: [MachineEvent]) {
        for case .committed(let label, let keys) in events { onCommit?(label, keys) }
        if pending != machine.prefix { pending = machine.prefix }
    }
}
