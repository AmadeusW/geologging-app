import SwiftUI
import Observation

/// Screen-off alternative: black UI and zero brightness after `delay` without input.
/// `wake()` is the single entry point for "something happened".
@Observable @MainActor
final class ScreenDimmer {
    private(set) var isDimmed = false

    /// Seconds, from iOS Settings > GeoLog > Display (`dimDelay`); re-read on every restart so
    /// changes apply without relaunching. 10 s if never set.
    @ObservationIgnored private var delay: Duration {
        let seconds = UserDefaults.standard.object(forKey: "dimDelay") as? Double ?? 10
        return .seconds(max(1, seconds))
    }
    @ObservationIgnored private var savedBrightness: CGFloat = 1
    @ObservationIgnored private var countdown: Task<Void, Never>?

    init() {
        UIApplication.shared.isIdleTimerDisabled = true   // otherwise iOS locks the phone
        restartCountdown()
    }

    /// Restores brightness (if dimmed) and restarts the countdown.
    func wake() {
        if isDimmed {
            screen?.brightness = savedBrightness
            isDimmed = false
        }
        restartCountdown()
    }

    func sceneChanged(to phase: ScenePhase) {
        if phase == .active {
            if isDimmed { screen?.brightness = 0 } else { restartCountdown() }
        } else if isDimmed {
            screen?.brightness = savedBrightness   // never leave the system dark outside the app
        }
    }

    private func restartCountdown() {
        countdown?.cancel()
        countdown = Task {
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            savedBrightness = screen?.brightness ?? 1
            screen?.brightness = 0
            isDimmed = true
        }
    }

    private var screen: UIScreen? {
        UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.screen }.first
    }
}
