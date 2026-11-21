import GameController
import GeoLogCore

/// USB keypad -> stream of grid keys. Knows nothing about what the keys mean.
///
/// Open question (see AGENTS.md): whether GCKeyboard keeps delivering while the phone is locked.
final class KeyboardInput {
    let keys: AsyncStream<Key>
    private let continuation: AsyncStream<Key>.Continuation
    private var connectObserver: NSObjectProtocol?

    init() {
        (keys, continuation) = AsyncStream.makeStream()
        connectObserver = NotificationCenter.default.addObserver(
            forName: .GCKeyboardDidConnect, object: nil, queue: .main
        ) { [weak self] note in
            if let keyboard = note.object as? GCKeyboard { self?.attach(keyboard) }
        }
        if let keyboard = GCKeyboard.coalesced { attach(keyboard) }
    }

    private func attach(_ keyboard: GCKeyboard) {
        keyboard.keyboardInput?.keyChangedHandler = { [continuation] _, _, code, pressed in
            if pressed, let key = Self.key(for: code) { continuation.yield(key) }
        }
    }

    /// Numeric keypad 7 8 9 / 4 5 6 / 1 2 3.
    private static let keypad: [GCKeyCode: Int] = [
        .keypad1: 1, .keypad2: 2, .keypad3: 3,
        .keypad4: 4, .keypad5: 5, .keypad6: 6,
        .keypad7: 7, .keypad8: 8, .keypad9: 9,
    ]

    private static func key(for code: GCKeyCode) -> Key? {
        keypad[code].flatMap { Key(keypadDigit: $0) }
    }
}
