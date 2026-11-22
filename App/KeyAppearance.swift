import SwiftUI
import GeoLogCore

/// EDIT HERE: how each on-screen key looks. The emoji is fixed per physical key (it does not
/// change as the state machine moves between prefixes); only enabled/greyed and the small
/// caption underneath follow `SequenceMap.legend(after:)`.
/// Which sequence each key triggers lives in `Sources/GeoLogCore/SequenceMap.swift`.
enum KeyAppearance {
    /// Keys 2 and 3 are unassigned.
    static let emoji: [Key: String] = [
        .bottomLeft: "🚲",    // 1
        .middleLeft: "🚩",    // 4
        .center: "🌳",        // 5
        .middleRight: "🚗",   // 6
        .topLeft: "❌",       // 7 (reset/cancel)
        .topMiddle: "🚦",     // 8
        .topRight: "🚚",      // 9
    ]

    /// Fill colour of the key when it is not the pending one.
    static func fill(for key: Key, enabled: Bool) -> Color {
        key == .topLeft ? Color.red.opacity(enabled ? 0.6 : 0.15)
                        : Color(white: enabled ? 0.2 : 0.08)
    }

    static let showCaption = true
    static let emojiSize: CGFloat = 40
    static let cellHeight: CGFloat = 92
    static let spacing: CGFloat = 12

    // Press feedback (opacity of a white overlay on the key).
    static let flashColor = Color.white
    /// Intermediate key of a sequence: quick blink so the next legend is visible straight away.
    static let stepFlash: [(opacity: Double, duration: Double)] = [(0.9, 0.04), (0, 0.18)]
    /// Last key of a sequence (entry logged): strong, settle to medium, linger, fade out.
    static let finalFlash: [(opacity: Double, duration: Double)] = [(1.0, 0.05), (0.5, 0.2), (0.5, 0.7), (0, 0.4)]
}
