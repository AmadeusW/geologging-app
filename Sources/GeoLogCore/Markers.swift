import Foundation

/// How a logged label is drawn on the map: an SF Symbol name and a colour.
public struct MarkerStyle: Codable, Equatable {
    public var symbol: String
    /// `RRGGBB` hex.
    public var colorHex: String

    public init(symbol: String, colorHex: String) {
        self.symbol = symbol
        self.colorHex = colorHex
    }
}

/// Label -> style table. Persisted as JSON (`marker-styles.json` in Documents) so it can be
/// edited from the Files app. Labels not listed use `fallback`.
public struct MarkerStyles: JSONConfig, Equatable {
    public var byLabel: [String: MarkerStyle]
    public var fallback: MarkerStyle

    public init(byLabel: [String: MarkerStyle], fallback: MarkerStyle) {
        self.byLabel = byLabel
        self.fallback = fallback
    }

    public func style(for label: String) -> MarkerStyle { byLabel[label] ?? fallback }

    /// Adds defaults for labels missing from `self` (e.g. new labels added to the map after
    /// the JSON file was first written), keeping the user's own choices.
    public func filled(with defaults: MarkerStyles) -> MarkerStyles {
        MarkerStyles(byLabel: defaults.byLabel.merging(byLabel) { _, user in user }, fallback: fallback)
    }

    public static let `default` = MarkerStyles(
        byLabel: [
            "reset": MarkerStyle(symbol: "arrow.counterclockwise", colorHex: "8E8E93"),
            "flag": MarkerStyle(symbol: "flag.fill", colorHex: "FF9500"),
            "bike path issue": MarkerStyle(symbol: "bicycle", colorHex: "FF3B30"),
            "traffic jam": MarkerStyle(symbol: "car.2.fill", colorHex: "FF3B30"),
            "clean baseline": MarkerStyle(symbol: "checkmark.circle.fill", colorHex: "34C759"),
            "personal vehicle": MarkerStyle(symbol: "car.fill", colorHex: "0A84FF"),
            "oversized vehicle": MarkerStyle(symbol: "box.truck.fill", colorHex: "5E5CE6"),
            "personal vehicle needs repair": MarkerStyle(symbol: "wrench.and.screwdriver.fill", colorHex: "0A84FF"),
            "antique vehicle": MarkerStyle(symbol: "car.side.fill", colorHex: "AC8E68"),
            "personal vehicle idling": MarkerStyle(symbol: "car.fill", colorHex: "64D2FF"),
            "commercial vehicle": MarkerStyle(symbol: "box.truck", colorHex: "BF5AF2"),
            "truck": MarkerStyle(symbol: "box.truck.fill", colorHex: "BF5AF2"),
            "bus": MarkerStyle(symbol: "bus.fill", colorHex: "FFD60A"),
            "truck needs repair": MarkerStyle(symbol: "wrench.and.screwdriver.fill", colorHex: "BF5AF2"),
            "bus needs repair": MarkerStyle(symbol: "wrench.and.screwdriver.fill", colorHex: "FFD60A"),
            "commercial vehicle idling": MarkerStyle(symbol: "box.truck", colorHex: "FF6482"),
        ],
        fallback: MarkerStyle(symbol: "mappin.circle.fill", colorHex: "FFFFFF"))
}

/// A logged entry placed on the map.
public struct MapMarker: Equatable, Identifiable {
    public var id: Int            // index in the entry list: stable, since entries are append-only
    public var label: String
    public var timestamp: Date
    public var latitude: Double
    public var longitude: Double
    public var style: MarkerStyle

    /// Entries without a GPS fix cannot be placed and are skipped.
    public static func markers(from entries: [LogEntry], styles: MarkerStyles) -> [MapMarker] {
        entries.enumerated().compactMap { i, e in
            guard let fix = e.fix else { return nil }
            return MapMarker(id: i, label: e.label, timestamp: e.timestamp,
                             latitude: fix.latitude, longitude: fix.longitude,
                             style: styles.style(for: e.label))
        }
    }
}
