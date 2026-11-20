import Foundation

/// One of the 9 keys of the 3x3 grid, row-major from the top-left.
/// Matches a 9-key USB numeric keypad:  7 8 9 / 4 5 6 / 1 2 3.
public enum Key: Int, CaseIterable, Hashable {
    case topLeft, topMiddle, topRight
    case middleLeft, center, middleRight
    case bottomLeft, bottomMiddle, bottomRight

    public var row: Int { rawValue / 3 }
    public var column: Int { rawValue % 3 }

    /// The digit printed on the matching numeric-keypad key (7 8 9 / 4 5 6 / 1 2 3).
    public var keypadDigit: Int { 7 - 3 * row + column }

    public init?(keypadDigit d: Int) {
        guard (1...9).contains(d) else { return nil }
        self.init(rawValue: ((9 - d) / 3) * 3 + (d - 1) % 3)
    }
}
