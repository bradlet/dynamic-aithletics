---
name: verify
description: Build, launch, and drive Hybrid AIthletics in the iOS simulator to verify changes at the UI surface.
---

# Verifying Hybrid AIthletics changes in the simulator

## Build + install + launch

```bash
xcodebuild -scheme "Hybrid AIthletics" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
UDID=$(xcrun simctl list devices | grep "iPhone 17 Pro (" | head -1 | grep -oE '[0-9A-F-]{36}')
xcrun simctl boot $UDID
APP="$HOME/Library/Developer/Xcode/DerivedData/Hybrid_AIthletics-*/Build/Products/Debug-iphonesimulator/Hybrid AIthletics.app"
xcrun simctl install $UDID $APP        # beware: a UITests-Runner.app sits next to it — install the app, not the runner
xcrun simctl launch $UDID bradlet.Hybrid-AIthletics
xcrun simctl io $UDID screenshot shot.png
```

## Driving the UI

There is no idb on this machine, and AppleScript/System Events + cliclick are
blocked by TCC automation permissions (AppleEvent timeout). The working handle is
a **throwaway XCUITest driver**: add a temporary test to `Hybrid AIthleticsUITests/`
that launches with `app.launchArguments = ["-uiTestSeed"]` (in-memory store +
deterministic fixtures), taps through the flow via the accessibility identifiers
sprinkled through the views, and writes screenshots straight to the scratchpad:

```swift
try? XCUIScreen.main.screenshot().pngRepresentation
    .write(to: URL(fileURLWithPath: "<scratchpad>/step.png"))
```

Run it with `-only-testing:"Hybrid AIthleticsUITests/<DriverClass>"`, read the
PNGs, then **delete the driver file** — it is not part of the committed suite.

## Gotchas

- If the build fails with `cannot execute tool 'metal'`, run
  `xcodebuild -downloadComponent MetalToolchain` (happens after Xcode updates;
  the MLX package compiles Metal shaders).
- Unit-test crashes take down a whole parallel-runner clone: every test in that
  clone reports "failed (0.000 seconds)". Find the real culprit via
  `-resultBundlePath` + `xcrun xcresulttool get test-results summary`, which
  names the crashing test.
