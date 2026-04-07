# CLAUDE.md

## Project
Hybrid AIthletics — iOS exercise tracking app (SwiftUI + SwiftData + CloudKit).

## Build & Test
```bash
# Build
xcodebuild -scheme "Hybrid AIthletics" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Run unit tests only
xcodebuild test -scheme "Hybrid AIthletics" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:"Hybrid AIthleticsTests"
```

## Architecture
- **No ViewModels** — `@Query` in top-level views only (`AerobicTrainingView`, `HistoryView`, `ContentView`). Child views receive data as `let` parameters.
- **Models**: `Exercise` (planned), `Workout` (recorded), `AppConfiguration` (preferences), `ExerciseType` (enum)
- **Distance storage**: Always miles internally. Display conversion via `Double.formattedDistance(metric:)`. Unit preference via `@Environment(\.useMetricUnits)`.
- **Week start**: Monday always (hardcoded in `Date+Week.swift` via `mondayCalendar`).
- **CloudKit**: All model properties must have default values for CloudKit compatibility.

## Testing Requirements

**Every new feature must ship with unit tests. This is non-negotiable.**

- New model fields → test default value, explicit set, and SwiftData persistence.
- New service/logic types → test all public methods and edge cases (empty inputs, boundary values).
- New prompt/serialization logic → test each output field, metric/imperial variants, omission conditions.
- Tests live in `Hybrid AIthleticsTests/Hybrid_AIthleticsTests.swift`, grouped by `struct` with a `// MARK:` header.
- Do not ship a feature without at least one test per public method.

## Conventions
- Swift Testing framework (not XCTest) — use `@Test`, `#expect()`, `import Testing`
- Header doc comments on all public/internal functions
- `ModelContainerFactory.makePreviewContainer()` for test and preview contexts
- Cached `DateFormatter` instances (static lets) — never allocate in computed properties

## File Layout
```
Models/          Data models and enums
Config/          ModelContainer, environment keys
Extensions/      Date+Week, Double+Distance
Views/           Grouped by tab: AerobicTraining/, Strength/, History/
```

## Key Files
- `Config/ModelContainerFactory.swift` — single place for container/CloudKit config
- `Extensions/Date+Week.swift` — all calendar arithmetic
- `Models/ExerciseType.swift` — exercise type enum with icons and colors
