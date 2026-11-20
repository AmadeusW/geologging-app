import XCTest
@testable import GeoLogCore

final class SequenceMachineTests: XCTestCase {
    let map = SequenceMap([
        [.topLeft, .topMiddle]: "AB",
        [.topLeft, .topRight]: "AC",
        [.middleLeft]: "M",
        [.middleLeft, .middleRight]: "MR",
        [.bottomRight, .bottomRight, .bottomRight]: "Triple",
    ])
    func machine() -> SequenceMachine { SequenceMachine(map: map, timeout: 1.0) }

    func testTwoKeySequenceCommits() {
        var m = machine()
        XCTAssertEqual(m.press(.topLeft, at: 0), [.advanced(prefix: [.topLeft])])
        XCTAssertEqual(m.press(.topMiddle, at: 0.2), [.committed(label: "AB", keys: [.topLeft, .topMiddle])])
        XCTAssertEqual(m.prefix, [])
    }

    func testDifferentSecondKeyGivesDifferentEntry() {
        var m = machine()
        _ = m.press(.topLeft, at: 0)
        XCTAssertEqual(m.press(.topRight, at: 0.1), [.committed(label: "AC", keys: [.topLeft, .topRight])])
    }

    func testUnknownKeyIgnoredWhenIdle() {
        var m = machine()
        XCTAssertEqual(m.press(.center, at: 0), [.ignored(.center)])
    }

    func testTimeoutAbandonsNonTerminalPrefix() {
        var m = machine()
        _ = m.press(.topLeft, at: 0)
        XCTAssertEqual(m.tick(at: 0.9), [])
        XCTAssertEqual(m.tick(at: 1.0), [.abandoned(prefix: [.topLeft])])
        XCTAssertEqual(m.prefix, [])
    }

    func testTerminalPrefixWaitsThenCommitsOnTimeout() {
        var m = machine()
        XCTAssertEqual(m.press(.middleLeft, at: 0), [.advanced(prefix: [.middleLeft])])
        XCTAssertEqual(m.tick(at: 1.0), [.committed(label: "M", keys: [.middleLeft])])
    }

    func testTerminalPrefixExtendsToLongerEntry() {
        var m = machine()
        _ = m.press(.middleLeft, at: 0)
        XCTAssertEqual(m.press(.middleRight, at: 0.3), [.committed(label: "MR", keys: [.middleLeft, .middleRight])])
    }

    func testTerminalPrefixCommitsThenRestartsOnNonExtendingKey() {
        var m = machine()
        _ = m.press(.middleLeft, at: 0)
        // topLeft doesn't extend [middleLeft]: commit "M", then start a new sequence with topLeft.
        XCTAssertEqual(m.press(.topLeft, at: 0.2), [
            .committed(label: "M", keys: [.middleLeft]),
            .advanced(prefix: [.topLeft]),
        ])
    }

    func testBadKeyAbandonsPrefixAndRestarts() {
        var m = machine()
        _ = m.press(.topLeft, at: 0)
        // center fits nowhere: drop [topLeft]; center starts nothing -> ignored.
        XCTAssertEqual(m.press(.center, at: 0.1), [.abandoned(prefix: [.topLeft]), .ignored(.center)])
        XCTAssertEqual(m.prefix, [])
    }

    func testBadKeyThatStartsNewSequence() {
        var m = machine()
        _ = m.press(.topLeft, at: 0)
        XCTAssertEqual(m.press(.bottomRight, at: 0.1), [.abandoned(prefix: [.topLeft]), .advanced(prefix: [.bottomRight])])
    }

    func testPressAfterTimeoutResolvesOldPrefixFirst() {
        var m = machine()
        _ = m.press(.middleLeft, at: 0)
        XCTAssertEqual(m.press(.topLeft, at: 5), [
            .committed(label: "M", keys: [.middleLeft]),
            .advanced(prefix: [.topLeft]),
        ])
    }

    func testRepeatedKeySequence() {
        var m = machine()
        _ = m.press(.bottomRight, at: 0)
        _ = m.press(.bottomRight, at: 0.1)
        XCTAssertEqual(m.press(.bottomRight, at: 0.2),
                       [.committed(label: "Triple", keys: [.bottomRight, .bottomRight, .bottomRight])])
    }

    func testTimeoutIsMeasuredFromLastKeyNotFirst() {
        var m = machine()
        _ = m.press(.bottomRight, at: 0)
        _ = m.press(.bottomRight, at: 0.8)
        XCTAssertEqual(m.tick(at: 1.5), [])   // 0.7s since last key
        XCTAssertEqual(m.press(.bottomRight, at: 1.6).count, 1)
    }

    func testDefaultMapIsSelfConsistent() {
        // Every default entry must be reachable by pressing its keys in order.
        for (keys, label) in SequenceMap.default.entries {
            var m = SequenceMachine(map: .default, timeout: 1)
            var events: [MachineEvent] = []
            for (i, k) in keys.enumerated() { events = m.press(k, at: Double(i) * 0.1) }
            events += m.tick(at: 100)
            XCTAssertTrue(events.contains(.committed(label: label, keys: keys)), "\(label) not reachable")
        }
    }
}

final class KeyTests: XCTestCase {
    func testKeypadLayout() {
        XCTAssertEqual(Key.topLeft.keypadDigit, 7)
        XCTAssertEqual(Key.topRight.keypadDigit, 9)
        XCTAssertEqual(Key.center.keypadDigit, 5)
        XCTAssertEqual(Key.bottomLeft.keypadDigit, 1)
        XCTAssertEqual(Key.bottomRight.keypadDigit, 3)
    }

    func testKeypadDigitRoundTrip() {
        for k in Key.allCases { XCTAssertEqual(Key(keypadDigit: k.keypadDigit), k) }
        XCTAssertNil(Key(keypadDigit: 0))
        XCTAssertNil(Key(keypadDigit: 10))
    }
}

final class CSVTests: XCTestCase {
    func testRenderWithAndWithoutFix() {
        let t = Date(timeIntervalSince1970: 1_700_000_000)
        let fix = LocationFix(latitude: 52.5, longitude: 13.25, horizontalAccuracy: 4.26, timestamp: t.addingTimeInterval(-2))
        let csv = CSV.render([
            LogEntry(timestamp: t, label: "A", keys: [.topLeft, .topMiddle], fix: fix),
            LogEntry(timestamp: t, label: "No fix", keys: [.center], fix: nil),
        ])
        let lines = csv.split(separator: "\n").map(String.init)
        XCTAssertEqual(lines[0], CSV.header)
        XCTAssertEqual(lines[1], "2023-11-14T22:13:20.000Z,A,7-8,52.500000,13.250000,4.3,2.0")
        XCTAssertEqual(lines[2], "2023-11-14T22:13:20.000Z,No fix,5,,,,")
    }

    func testEscaping() {
        XCTAssertEqual(CSV.escape("plain"), "plain")
        XCTAssertEqual(CSV.escape("a,b"), "\"a,b\"")
        XCTAssertEqual(CSV.escape("say \"hi\""), "\"say \"\"hi\"\"\"")
    }
}
