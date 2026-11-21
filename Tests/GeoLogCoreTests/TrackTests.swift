import XCTest
@testable import GeoLogCore

final class TrackTests: XCTestCase {
    let t0 = Date(timeIntervalSince1970: 1_000_000)

    func fix(_ dt: TimeInterval, acc: Double = 5) -> LocationFix {
        LocationFix(latitude: 52.0, longitude: 13.0, horizontalAccuracy: acc, timestamp: t0.addingTimeInterval(dt))
    }

    func testSamplerThinsOneHertzStream() {
        var s = TrackSampler(settings: TrackSettings(sampleInterval: 5))
        let accepted = (0...12).compactMap { s.offer(fix(Double($0))) }
        XCTAssertEqual(accepted.map { $0.timestamp.timeIntervalSince(t0) }, [0, 5, 10])
    }

    func testSamplerToleratesJitter() {
        var s = TrackSampler(settings: TrackSettings(sampleInterval: 5))
        XCTAssertNotNil(s.offer(fix(0)))
        XCTAssertNotNil(s.offer(fix(4.8)))
    }

    func testSamplerRejectsPoorAndInvalidAccuracy() {
        var s = TrackSampler(settings: TrackSettings(maxAccuracy: 30))
        XCTAssertNil(s.offer(fix(0, acc: 31)))
        XCTAssertNil(s.offer(fix(0, acc: -1)))
        XCTAssertNotNil(s.offer(fix(0, acc: 30)))
    }

    func testSettingsSanitizeAndJSONRoundTrip() throws {
        XCTAssertEqual(TrackSettings(sampleInterval: 0).sanitized.sampleInterval, 1)
        let s = TrackSettings(sampleInterval: 10, maxAccuracy: 20, maxGap: 60)
        XCTAssertEqual(TrackSettings.from(jsonData: try s.jsonData()), s)
        XCTAssertEqual(TrackSettings.from(jsonData: Data("junk".utf8)), .default)
        let styles = MarkerStyles.default
        XCTAssertEqual(MarkerStyles.from(jsonData: try styles.jsonData()), styles)
    }

    func testCSVRoundTripSkipsTornLine() {
        let p = TrackPoint(timestamp: t0, latitude: 52.123456, longitude: 13.654321, horizontalAccuracy: 4)
        let text = TrackCSV.header + "\n" + TrackCSV.line(p) + "\n" + "1000005,52.12"
        XCTAssertEqual(TrackCSV.parse(text), [p])
    }

    func testSegmentsSplitOnGap() {
        let pts = [0, 5, 10, 200, 205].map {
            TrackPoint(timestamp: t0.addingTimeInterval($0), latitude: 0, longitude: 0, horizontalAccuracy: 1)
        }
        XCTAssertEqual(Track.segments(pts, maxGap: 120).map(\.count), [3, 2])
        XCTAssertEqual(Track.segments([], maxGap: 120), [])
    }

    func testMarkersSkipEntriesWithoutFixAndUseStyles() {
        let e1 = LogEntry(timestamp: t0, label: "bus", keys: [.topRight, .topMiddle], fix: fix(0))
        let e2 = LogEntry(timestamp: t0, label: "flag", keys: [.middleLeft], fix: nil)
        let e3 = LogEntry(timestamp: t0, label: "unknown", keys: [.center], fix: fix(1))
        let m = LogMarker.markers(from: [e1, e2, e3], styles: .default)
        XCTAssertEqual(m.map(\.id), [0, 2])
        XCTAssertEqual(m[0].style.symbol, "bus.fill")
        XCTAssertEqual(m[1].style, MarkerStyles.default.fallback)
    }

    func testStylesFilledKeepsUserOverrides() {
        let custom = MarkerStyle(symbol: "star", colorHex: "000000")
        var user = MarkerStyles(byLabel: ["bus": custom], fallback: MarkerStyles.default.fallback)
        user = user.filled(with: .default)
        XCTAssertEqual(user.style(for: "bus"), custom)
        XCTAssertEqual(user.style(for: "flag"), MarkerStyles.default.style(for: "flag"))
    }

    func testDefaultStylesCoverEveryDefaultLabel() {
        for label in SequenceMap.default.entries.values {
            XCTAssertNotNil(MarkerStyles.default.byLabel[label], label)
        }
    }
}
