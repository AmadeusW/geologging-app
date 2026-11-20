import Foundation

public struct LocationFix: Equatable {
    public var latitude: Double
    public var longitude: Double
    public var horizontalAccuracy: Double
    public var timestamp: Date

    public init(latitude: Double, longitude: Double, horizontalAccuracy: Double, timestamp: Date) {
        self.latitude = latitude
        self.longitude = longitude
        self.horizontalAccuracy = horizontalAccuracy
        self.timestamp = timestamp
    }
}

public struct LogEntry: Equatable {
    public var timestamp: Date
    public var label: String
    public var keys: [Key]
    public var fix: LocationFix?

    public init(timestamp: Date, label: String, keys: [Key], fix: LocationFix?) {
        self.timestamp = timestamp
        self.label = label
        self.keys = keys
        self.fix = fix
    }
}

public enum CSV {
    public static let header = "timestamp,label,keys,latitude,longitude,accuracy_m,fix_age_s"

    public static func render(_ entries: [LogEntry]) -> String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var lines = [header]
        for e in entries {
            var fields = [
                iso.string(from: e.timestamp),
                escape(e.label),
                e.keys.map { String($0.keypadDigit) }.joined(separator: "-"),
            ]
            if let f = e.fix {
                fields += [
                    String(format: "%.6f", f.latitude),
                    String(format: "%.6f", f.longitude),
                    String(format: "%.1f", f.horizontalAccuracy),
                    String(format: "%.1f", e.timestamp.timeIntervalSince(f.timestamp)),
                ]
            } else {
                fields += ["", "", "", ""]
            }
            lines.append(fields.joined(separator: ","))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    public static func escape(_ s: String) -> String {
        guard s.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" }) else { return s }
        return "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
