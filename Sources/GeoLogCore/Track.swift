import Foundation

/// One sample of the breadcrumb trail. Deliberately small: it is written every few seconds.
public struct TrackPoint: Equatable {
    public var timestamp: Date
    public var latitude: Double
    public var longitude: Double
    public var horizontalAccuracy: Double

    public init(timestamp: Date, latitude: Double, longitude: Double, horizontalAccuracy: Double) {
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.horizontalAccuracy = horizontalAccuracy
    }
}

/// User-tunable tracking parameters. Persisted as JSON by the app.
public struct TrackSettings: JSONConfig, Equatable {
    /// Minimum seconds between recorded points.
    public var sampleInterval: TimeInterval
    /// Fixes with a worse (larger) accuracy than this, in metres, are not recorded.
    public var maxAccuracy: Double
    /// A silence longer than this (seconds) breaks the drawn line (tunnel, GPS loss, app paused).
    public var maxGap: TimeInterval

    public init(sampleInterval: TimeInterval = 5, maxAccuracy: Double = 50, maxGap: TimeInterval = 120) {
        self.sampleInterval = sampleInterval
        self.maxAccuracy = maxAccuracy
        self.maxGap = maxGap
    }

    public static let `default` = TrackSettings()

    /// Clamps nonsense (zero/negative interval would record every fix).
    public var sanitized: TrackSettings {
        TrackSettings(sampleInterval: max(1, sampleInterval),
                      maxAccuracy: max(1, maxAccuracy),
                      maxGap: max(sampleInterval, maxGap))
    }
}

/// Down-samples the raw fix stream (CoreLocation delivers ~1 Hz) to `settings.sampleInterval`.
/// Time comes from the fix itself, so it is deterministic and testable.
public struct TrackSampler {
    public var settings: TrackSettings
    private var lastAccepted: Date?
    /// Fixes arrive with jitter; without slack a 5 s interval would often become 6 s.
    private let tolerance: TimeInterval = 0.5

    public init(settings: TrackSettings = .default) {
        self.settings = settings.sanitized
    }

    public mutating func offer(_ fix: LocationFix) -> TrackPoint? {
        guard fix.horizontalAccuracy >= 0, fix.horizontalAccuracy <= settings.maxAccuracy else { return nil }
        if let last = lastAccepted, fix.timestamp.timeIntervalSince(last) < settings.sampleInterval - tolerance {
            return nil
        }
        lastAccepted = fix.timestamp
        return TrackPoint(timestamp: fix.timestamp, latitude: fix.latitude,
                          longitude: fix.longitude, horizontalAccuracy: fix.horizontalAccuracy)
    }
}

/// Append-only text format, one point per line: `unix_seconds,lat,lon,accuracy_m`.
/// Appending a line never rewrites the file, so each write is O(1) and a crash loses at most
/// the buffered points. Malformed lines (e.g. a torn last line) are skipped on read.
public enum TrackCSV {
    public static let header = "unix_time,latitude,longitude,accuracy_m"

    public static func line(_ p: TrackPoint) -> String {
        String(format: "%d,%.6f,%.6f,%.0f", Int(p.timestamp.timeIntervalSince1970.rounded()),
               p.latitude, p.longitude, p.horizontalAccuracy)
    }

    public static func parse(_ text: String) -> [TrackPoint] {
        text.split(whereSeparator: \.isNewline).compactMap { raw in
            let f = raw.split(separator: ",", omittingEmptySubsequences: false)
            guard f.count == 4, let t = Double(f[0]), let lat = Double(f[1]),
                  let lon = Double(f[2]), let acc = Double(f[3]) else { return nil }
            return TrackPoint(timestamp: Date(timeIntervalSince1970: t),
                              latitude: lat, longitude: lon, horizontalAccuracy: acc)
        }
    }
}

public enum Track {
    /// Splits points into continuous runs wherever consecutive points are more than `maxGap`
    /// seconds apart, so the map doesn't draw a straight line across a gap.
    public static func segments(_ points: [TrackPoint], maxGap: TimeInterval) -> [[TrackPoint]] {
        var result: [[TrackPoint]] = []
        var current: [TrackPoint] = []
        for p in points {
            if let last = current.last, p.timestamp.timeIntervalSince(last.timestamp) > maxGap {
                result.append(current)
                current = []
            }
            current.append(p)
        }
        if !current.isEmpty { result.append(current) }
        return result
    }
}
