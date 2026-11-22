import SwiftUI
import GeoLogCore

/// The 3x3 on-screen keypad. Keys with no label in the current state are greyed out.
struct KeyGrid: View {
    let legend: [Key: String]
    let pending: [Key]
    let onPress: (Key) -> Void

    var body: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
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
        let isPending = pending.last == key
        return Button { onPress(key) } label: {
            RoundedRectangle(cornerRadius: 16)
                .fill(isPending ? Color.orange.opacity(0.5)
                      : key == .topLeft ? Color.red.opacity(label == nil ? 0.15 : 0.6)   // 7 = reset/cancel
                      : Color(white: label == nil ? 0.08 : 0.2))
                .overlay {
                    VStack(spacing: 6) {
                        Text("\(key.keypadDigit)")
                            .font(.system(size: 36, weight: .semibold, design: .rounded))
                        if let label {
                            Text(label)
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                                .minimumScaleFactor(0.6)
                        }
                    }
                    .padding(6)
                    .foregroundStyle(label == nil ? Color(white: 0.3) : .white)
                }
        }
        .buttonStyle(.plain)
        .disabled(label == nil)
    }
}
