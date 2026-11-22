import SwiftUI
import GeoLogCore

/// The 3x3 on-screen keypad. Keys with no label in the current state are greyed out.
struct KeyGrid: View {
    let legend: [Key: String]
    let pending: [Key]
    let flashes: [Key: KeyFlash]
    let onPress: (Key) -> Void

    var body: some View {
        Grid(horizontalSpacing: KeyAppearance.spacing, verticalSpacing: KeyAppearance.spacing) {
            ForEach(0..<3, id: \.self) { row in
                GridRow {
                    ForEach(0..<3, id: \.self) { column in
                        keyButton(Key(rawValue: row * 3 + column)!)
                    }
                }
            }
        }
    }

    private func keyButton(_ key: Key) -> some View {
        let label = legend[key]
        let enabled = label != nil
        let isPending = pending.last == key
        return Button { onPress(key) } label: {
            RoundedRectangle(cornerRadius: 16)
                .fill(KeyAppearance.fill(for: key, enabled: enabled)
                .frame(maxWidth: .infinity)
                .frame(height: KeyAppearance.cellHeight)
                .overlay { FlashOverlay(flash: flashes[key]) }
                .overlay {
                    VStack(spacing: 4) {
                        Text(KeyAppearance.emoji[key] ?? "")
                            .font(.system(size: KeyAppearance.emojiSize))
                            .opacity(enabled ? 1 : 0.3)
                        if KeyAppearance.showCaption {
                            // Fixed one-line slot so captions never change the cell size.
                            Text(label ?? " ")
                                .font(.caption2)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(4)
                }
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

/// White overlay that plays the keyframe curve from `KeyAppearance` each time `flash.id` changes.
private struct FlashOverlay: View {
    let flash: KeyFlash?

    var body: some View {
        let curve = flash?.kind == .final ? KeyAppearance.finalFlash : KeyAppearance.stepFlash
        RoundedRectangle(cornerRadius: 16)
            .fill(KeyAppearance.flashColor)
            .keyframeAnimator(initialValue: 0.0, trigger: flash?.id) { view, opacity in
                view.opacity(opacity)
            } keyframes: { _ in
                KeyframeTrack {
                    for step in curve { LinearKeyframe(step.opacity, duration: step.duration) }
                }
            }
            .allowsHitTesting(false)
    }
}
