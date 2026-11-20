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
        Button { session.press(key) } label: {
            RoundedRectangle(cornerRadius: 16)
                .fill(session.pending.contains(key) ? Color.orange : Color(white: 0.18))
                .overlay(
                    Text("\(key.keypadDigit)")
                        .font(.system(size: 40, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                )
        }
        .buttonStyle(.plain)
    }
}
