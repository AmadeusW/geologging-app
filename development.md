# Development on macOS

GeoLog is built and run on a Mac with Xcode. Logic lives in the `GeoLogCore` Swift package
(testable without a device); the iOS app in `App/` is a thin shell around it.

## 1. Acquire tools

1. **Xcode** (from the Mac App Store or https://developer.apple.com/download/). It's large
   (10+ GB installed). Launch it once and accept the license / install the extra components.
2. **Command line tools and license** (if not already set up):
   ```sh
   xcode-select --install
   sudo xcodebuild -license accept
   ```
3. **XcodeGen** (generates `GeoLog.xcodeproj` from `project.yml`):
   ```sh
   brew install xcodegen
   ```
   Homebrew: https://brew.sh

4. **An Apple ID** signed in under Xcode > Settings > Accounts. A free account works, but
   apps installed with it expire after 7 days (reinstall to renew). A paid Developer account
   ($99/year) lasts a year.

Check: `xcodebuild -version`, `swift --version`, `xcodegen --version`.

## 2. Get the code

```sh
git clone <repo-url> geologging-app
cd geologging-app
```

## 3. Test the logic (no device needed)

```sh
swift test
```

This builds `GeoLogCore` and runs the XCTest suite (state machine, key layout, CSV).
Run it after any change to `Sources/GeoLogCore/`. The tests don't need the simulator or a phone.

## 4. Build the iOS app

```sh
xcodegen generate        # creates GeoLog.xcodeproj (git-ignored; re-run if project.yml changes)
open GeoLog.xcodeproj
```

In Xcode:
1. Select the **GeoLog** project > **GeoLog** target > **Signing & Capabilities**.
2. Tick *Automatically manage signing* and choose your **Team** (your Apple ID).
   - If the bundle ID `dev.geolog.app` is taken, change `PRODUCT_BUNDLE_IDENTIFIER` in
     `project.yml` to something unique (e.g. `com.yourname.geolog`) and re-run `xcodegen generate`.
   - To avoid re-picking the team after each regenerate, add `DEVELOPMENT_TEAM: <TEAMID>`
     under `settings.base` in `project.yml`.
3. The app code has never been compiled; expect to fix a few compile errors on the first build
   (Product > Build, Cmd+B).

Command-line build check (no signing, compile only):
```sh
xcodebuild -project GeoLog.xcodeproj -scheme GeoLog \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

## 5. Deploy to your iPhone

The simulator is not useful here (no real GPS, no USB keypad, no brightness/lock behaviour).
Use a real device.

1. **Enable Developer Mode on the iPhone**: Settings > Privacy & Security > Developer Mode >
   on, then restart. (The option appears after the phone has been connected to Xcode once.)
2. Connect the iPhone to the Mac by cable, unlock it, and tap **Trust This Computer**.
3. In Xcode, pick your iPhone in the run destination dropdown (top bar) and press **Run** (Cmd+R).
4. First launch with a free account: on the phone go to Settings > General > VPN & Device
   Management > your Apple ID > **Trust**, then launch the app again.
5. When prompted, allow location access. Choose **While Using the App** (it's enough, because
   the app starts tracking in the foreground and the `location` background mode keeps it alive).
   Optionally set Settings > GeoLog > Location > *Always* for extra robustness.
6. The Xcode run can be stopped and the cable removed; the app stays installed (for 7 days on a
   free account).

## 6. Get the CSV off the phone

Files are written to the app's Documents folder every 60 s as `geolog-<start time>.csv`.
- On the iPhone: **Files** app > On My iPhone > GeoLog, then share or AirDrop the file.
- Or in Finder: select the iPhone in the sidebar > Files tab > GeoLog.

## 7. Field-test checklist

Do this before relying on it for a multi-hour session:
1. Connect the USB keypad (Lightning/USB-C adapter) and press keys in the foreground. Confirm
   entries appear (the status line shows `entries N`).
2. **Dim mode**: leave it alone for 10 s; the screen should go black. Tap to wake; the first tap
   must not register a key. Keyboard presses should still register while dimmed.
3. **Lock test (the open question)**: with the placeholder map, the center key (5) logs a
   "Center" entry in one press (about 1.5 s timeout rules don't apply). Press the side button to
   lock the phone, press 5 several times, unlock and check whether the entry count went up
   (or open the CSV after the next minute flush). Repeat after 1+ hour locked
   (USB Restricted Mode may cut the accessory). If keys don't register when locked, use dim mode.
4. Walk outside and confirm GPS: the status line shows `gps ±Nm`, and CSV rows have lat/lon
   with a small `fix_age_s`.
5. Run for an hour and compare battery drain with the screen dimmed.

## Troubleshooting

- *"Untrusted Developer"* on launch: see step 5 of Deploy.
- *No signing team / provisioning errors*: sign in under Xcode > Settings > Accounts, pick the
  team, and make sure the bundle ID is unique.
- *"Could not find package GeoLogCore"* or a stale project: re-run `xcodegen generate`.
- *App expired after 7 days*: connect the phone and press Run again.
- *No GPS fix*: check Settings > Privacy & Security > Location Services is on and GeoLog is
  allowed; test outdoors.
- Update `AGENTS.md` ("Open items") with whatever you learn from the lock test.
