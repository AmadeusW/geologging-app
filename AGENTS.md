# GeoLog - iPhone key-press geo logger

Native iOS app (SwiftUI) used while walking around a city. A 9-key USB keypad (or the on-screen
3x3 grid) drives a state machine; each completed key sequence becomes a log row:
`timestamp, label, keys, latitude, longitude, accuracy_m, fix_age_s`.
Rows live in memory and are flushed to a CSV in the app's Documents folder every 60 s
(visible in the Files app: file sharing is enabled).

## Layout
- `Sources/GeoLogCore/` - pure Swift, Foundation only. `Key`, `SequenceMap` (sequence -> label),
  `SequenceMachine` (state machine, time injected), `LogEntry`/`CSV`. **All logic goes here.**
- `Tests/GeoLogCoreTests/` - XCTest. Runs on Linux and macOS with `swift test`.
- `App/` - thin iOS shell: `SessionModel` (glue, dimming, flushing), `LocationProvider`
  (background CoreLocation), `KeyboardMonitor` (GameController `GCKeyboard`), SwiftUI views.
  No logic here that can be tested in Core instead.
- `project.yml` - XcodeGen spec. The `.xcodeproj` is generated and git-ignored.

## Dev environment
- Dev machine is Linux (Fedora): can edit and `swift test` the Core package
  (`sudo dnf install swift-lang`), but cannot build the iOS app. Building needs macOS + Xcode:
  `brew install xcodegen && xcodegen generate && open GeoLog.xcodeproj`, set the signing team,
  run on a real iPhone (GPS/keyboard/brightness don't work in the simulator).
- App code has NOT been compiled yet. Expect small compile fixes on the first Xcode build.
- Free Apple ID signing expires after 7 days; fine for testing.

## Behaviour requirements
- Screen-off alternative: after 10 s without touch, UI goes pure black and
  `UIScreen.main.brightness = 0` (OLED = almost no power); `isIdleTimerDisabled = true`.
  Any input restores brightness and shows the current state-machine legend on the grid. A touch
  while dimmed only wakes (does not press a key); a keyboard press wakes AND registers.
  Every key press restarts the 10 s dim countdown. (Locked phone delivers no keyboard input: verified.)
- Location: background mode `location`, `allowsBackgroundLocationUpdates`, best accuracy,
  no auto-pause. The latest fix is attached to each entry at commit time; `fix_age_s` shows staleness.
- Touch and keyboard feed the same `SessionModel.press(_:)`.

## State machine rules (see `SequenceMachine.swift`, covered by tests)
- State = key prefix pressed so far. Valid path -> advance; complete entry with no longer
  extension -> commit immediately; entry that is also a prefix of a longer one -> commit on
  timeout (1.5 s since last key) or when the next key doesn't extend it.
- Invalid key: pending prefix is committed (if an entry) or abandoned, then the key is retried
  as a fresh start.
- `SequenceMap.default` implements `statemachine.md`. `cancelKey` (7): mid-sequence it drops the
  pending prefix silently; alone it logs "reset". 6 and 9 are entries too (commit on timeout).
  Keys 2 and 3 are unassigned: shown greyed/disabled. `SequenceMap.legend(after:)` drives the grid labels.

## Open items / unverified
1. **Keyboard while phone is locked/backgrounded**: unknown whether `GCKeyboard` delivers
   events; USB Restricted Mode may also cut the accessory after ~1 h locked. Test on device.
2. Keypad mapping assumes numeric-keypad key codes (7 8 9 / 4 5 6 / 1 2 3). A macropad that
   sends top-row digits would need an extra mapping in `KeyboardMonitor`.
3. Timeout value (1.5 s is a guess).
