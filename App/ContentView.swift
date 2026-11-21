import SwiftUI
import GeoLogCore

struct ContentView: View {
    @EnvironmentObject var session: SessionModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 12) {
                Text(session.statusLine)
                    .font(.footnote.monospaced())
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                    ForEach(0..<3, id: \.self) { row in
                        GridRow {
                            ForEach(0..<3, id: \.self) { col in
                                keyButton(Key(rawValue: row * 3 + col)!)
                            }
                        }
                    }
                }
            }
            .padding()

            // While dimmed, a black overlay swallows the first tap and just wakes the screen,
            // so a tap in a pocket can't log an entry by accident.
            if session.isDimmed {
                Color.black
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { session.wake() }
            }
        }
        .statusBarHidden(session.isDimmed)
        .persistentSystemOverlays(session.isDimmed ? .hidden : .automatic)
    }

    private func keyButton(_ key: Key) -> some View {
        let label = session.legend[key]
        return Button { session.press(key) } label: {
            RoundedRectangle(cornerRadius: 16)
                .fill(session.pending.last == key ? Color.orange.opacity(0.5) : Color(white: label == nil ? 0.08 : 0.2))
                .overlay(
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
                    .foregroundColor(label == nil ? Color(white: 0.3) : .white)
                )
        }
        .buttonStyle(.plain)
        .disabled(label == nil)
    }
}
