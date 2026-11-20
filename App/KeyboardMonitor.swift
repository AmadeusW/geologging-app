import GameController
import GeoLogCore

/// Receives USB keyboard / keypad presses via the GameController framework.
///
/// EXPERIMENT: whether this keeps delivering events when the app is backgrounded or the phone
/// is locked is unverified. Test on device (see AGENTS.md). The dimmed-foreground mode does not
/// depend on the answer.
final class KeyboardMonitor {
    var onKey: ((Key) -> Void)?

    func start() {
        NotificationCenter.default.addObserver(forName: .GCKeyboardDidConnect, object: nil, queue: .main) { [weak self] note in
            if let kb = note.object as? GCKeyboard { self?.attach(kb) }
        }
        if let kb = GCKeyboard.coalesced { attach(kb) }
    }

    private func attach(_ keyboard: GCKeyboard) {
        keyboard.keyboardInput?.keyChangedHandler = { [weak self] _, _, code, pressed in
            guard pressed, let key = Self.map(code) else { return }
            self?.onKey?(key)
        }
    }

    // Numeric keypad: 7 8 9 / 4 5 6 / 1 2 3 -> grid positions.
    private static func map(_ code: GCKeyCode) -> Key? {
        let digits: [GCKeyCode: Int] = [
            .keypad1: 1, .keypad2: 2, .keypad3: 3,
            .keypad4: 4, .keypad5: 5, .keypad6: 6,
            .keypad7: 7, .keypad8: 8, .keypad9: 9,
        ]
        return digits[code].flatMap { Key(keypadDigit: $0) }
    }
}
