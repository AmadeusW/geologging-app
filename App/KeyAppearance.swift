import SwiftUI
import GeoLogCore

/// Look of the on-screen keys (sizes, fills, flash). Emoji and labels come from
/// `SequenceMap.default` (Sources/GeoLogCore/SequenceMap.swift), shared with the map markers.
enum KeyAppearance {
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
    /// Last key of a sequence (entry logged): strong, settle to medium, fade out. 0.5 s total.
    static let finalFlash: [(opacity: Double, duration: Double)] = [(1.0, 0.05), (0.5, 0.15), (0.5, 0.1), (0, 0.2)]
    static var finalFlashDuration: Double { finalFlash.reduce(0) { $0 + $1.duration } }
}
