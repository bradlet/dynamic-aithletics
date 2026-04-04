# Dynamic AIthletics

An iOS exercise tracking application built with SwiftUI, SwiftData, and CloudKit. Designed for runners and endurance athletes to plan weekly training routines, record completed workouts, and track mileage over time.

## Features

### Aerobic Training (Tab 1)
- **Weekly calendar** with Monday-Sunday swimlanes showing planned exercises
- **Drag-and-drop** to reschedule exercises between days
- **Mileage header** showing planned vs. completed miles for the current week with progress indicator
- **Record workouts** via the checkmark button on any exercise — pre-fills from the plan, all fields editable
- **Repeat weekly** — mark any exercise as repeating and it automatically appears on the same day every week
- **Exercise types**: Run, Long Run, Tempo Run, Interval Run, Easy Run, Recovery Run, Walk, Bike, Swim, Hike, Elliptical, Other

### Strength Training (Tab 2)
- Placeholder — weekly strength training calendar coming in a future release

### History (Tab 3)
- **Summary stats**: all-time, year-to-date, and month-to-date mileage
- **Monthly calendar** with colored workout indicators and day-tap detail popovers
- **Paginated workout log** sorted by most recent, with lazy-loading scroll

## Tech Stack

| Component | Technology |
|-----------|-----------|
| UI | SwiftUI |
| Data | SwiftData |
| Sync | CloudKit (automatic via SwiftData) |
| Testing | Swift Testing framework |
| Min iOS | 17.0 |

## Project Layout

```
Dynamic AIthletics/
  Models/           SwiftData @Model classes and ExerciseType enum
  Config/           ModelContainer factory, environment keys
  Extensions/       Date arithmetic, distance formatting
  Views/
    AerobicTraining/  Weekly calendar, exercise cards, add/record sheets
    Strength/         Placeholder view
    History/          Summary stats, monthly calendar, workout list
  ContentView.swift   Root TabView
  Dynamic_AIthleticsApp.swift  App entry point
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for architecture documentation and [docs/DATA_MODEL.md](docs/DATA_MODEL.md) for an in-depth data model reference.

## Building

Open `Dynamic AIthletics.xcodeproj` in Xcode 15+ and build for an iOS 17+ simulator or device.

### CloudKit Setup

CloudKit sync is configured but requires a container ID registered in the Apple Developer portal. Update the container identifier in:
1. `Dynamic_AIthletics.entitlements` — `icloud-container-identifiers` array
2. Apple Developer portal — register the iCloud container

## Running Tests

Tests use the Swift Testing framework. Run from Xcode (Cmd+U) or via:

```bash
xcodebuild test -scheme "Dynamic AIthletics" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:"Dynamic AIthleticsTests"
```

## Distance Units

All distances are stored internally in miles. A central `AppConfiguration` model controls display units (miles or kilometers), propagated via a SwiftUI `EnvironmentKey`. To switch to metric, update `AppConfiguration.useMetricUnits` — all views react automatically.

## License

This project is licensed under the [MIT License](LICENSE) with the [Commons Clause](https://commonsclause.com/) condition. You are free to view, fork, modify, and contribute to the source code, but you may not sell the software or any product substantially derived from it. See the [LICENSE](LICENSE) file for full terms.
