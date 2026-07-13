# CLAUDE.md

## Project
Hybrid AIthletics — iOS exercise tracking app (SwiftUI + SwiftData + CloudKit).

## Build & Test
```bash
# Build app
xcodebuild -scheme "Hybrid AIthletics" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Run app unit tests
xcodebuild test -scheme "Hybrid AIthletics" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:"Hybrid AIthleticsTests"

# Run History tab functional UI tests
xcodebuild test -scheme "Hybrid AIthletics" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:"Hybrid AIthleticsUITests/HistoryUITests"

# Run AICoachCore package tests
cd Packages/AICoachCore && swift test

# Run AI coach evals (requires pip3 install mlx-lm)
cd Evals && python3 eval_runner.py

# Inspect AI coach prompts (no model needed)
cd Evals && swift run CoachEval inspect --scenario high-rpe --prompt-mode chat
```

## Architecture
- **No ViewModels** — `@Query` in top-level views only (`AerobicTrainingView`, `HistoryView`, `ContentView`). Child views receive data as `let` parameters.
- **Models**: `Exercise` (planned), `Workout` (recorded), `AppConfiguration` (preferences), `ExerciseType` (enum)
- **Distance storage**: Always miles internally. Display conversion via `Double.formattedDistance(metric:)`. Unit preference via `@Environment(\.useMetricUnits)`.
- **Week start**: Monthly calendar grids are always Sunday-first — standard `Calendar.current` week (see `Date+Week.swift`). The user's `AppConfiguration.weekStartDay` (1=Sun…7=Sat, injected via `@Environment(\.weekStartDay)`) governs (a) weekly *aggregation* (mileage buckets, "This Week" stats — threaded into `WorkoutAggregations` as `firstWeekday`) and (b) the Aerobic Training *weekly* calendar: its day ordering, week boundaries, navigation, and header mileage totals use the `firstWeekday:` variants (`daysInWeek(firstWeekday:)`, `startOfWeek(firstWeekday:)`, `endOfWeek(firstWeekday:)`) so the topmost swimlane is the configured week start. The no-arg Sunday-first helpers remain for monthly views and must not change.
- **CloudKit**: All model properties must have default values for CloudKit compatibility.
- **Enums in @Model classes** must be plain raw-value Codable enums (like `ExerciseType`). An enum with a custom `init(from:)` (e.g. `MuscleGroup`'s tolerant decode) makes SwiftData treat it as a composite Codable attribute and its encoder crashes on save — store the raw String instead and expose a computed enum property (see `StrengthExercise.muscleGroupRaw`, `Workout.source`).
- **AICoachCore local package**: `Packages/AICoachCore/` — shared library containing prompt builder, coaching types (`CoachWorkout`, `CoachExercise`, `CoachingRequest`, `CoachingResponse`), formatters, and `GenerationConfig`. Used by both the iOS app and the `Evals/` CLI. The app converts SwiftData models to AICoachCore types via `CoachTypeConversions.swift`.
- **AI Coach service layer**: `AICoachService` protocol with two implementations — `MLXAICoachService` (production, Gemma 3 4B via MLX-Swift) and `StubAICoachService` (previews/tests). Injected via `@Environment(\.aiCoach)`. Default environment value is the stub so previews never load real models. Uses `UserInput(chat:)` with separate system/user roles for proper Gemma 3 chat template formatting.
- **AI model delivery**: Gemma 3 4B QAT 4-bit weights are **not bundled** — they download from Hugging Face on first use via `ModelConfiguration(id:)` and are cached locally for offline access.
- **Conditional compilation**: All MLX-specific code is gated behind `#if canImport(MLXLLM)`. The `#else` branches throw `AICoachError.notImplemented` so the app compiles on simulators/CI without the SPM dependency resolved.
- **Google Sheets Sync**: `GoogleSheetsSyncCoordinator` (`@MainActor @Observable`) debounces workout mutations and exports via the `GoogleSheetsAPI` protocol (`LiveGoogleSheetsAPI` uses GoogleSignIn-iOS + URLSession behind `#if canImport(GoogleSignIn)`; `StubGoogleSheetsAPI` for previews/tests). Injected via `@Environment(\.googleSheetsSync)`. Uses the **`auth/drive.file` scope** (per-file access only — non-sensitive, no Google verification needed); never `auth/spreadsheets`. OAuth client + Info.plist setup is documented in README.

## Testing Requirements

**Every new feature must ship with unit tests. This is non-negotiable.**

- New model fields → test default value, explicit set, and SwiftData persistence.
- New service/logic types → test all public methods and edge cases (empty inputs, boundary values).
- New prompt/serialization logic → test each output field, metric/imperial variants, omission conditions.
- Prompt builder tests live in `Packages/AICoachCore/Tests/AICoachCoreTests/PromptBuilderTests.swift`.
- App-level tests live in `Hybrid AIthleticsTests/Hybrid_AIthleticsTests.swift`, grouped by `struct` with a `// MARK:` header.
- Functional UI tests for multi-step flows live in `Hybrid AIthleticsUITests/` using `XCTest` + `XCUIApplication` (UI tests stay on XCTest because Swift Testing doesn't integrate with XCUI). They launch the app with `-uiTestSeed` to install an in-memory container + deterministic fixtures via `Config/UITestFixtures.swift`. Add new identifiers via `.accessibilityIdentifier(...)` when introducing testable controls.
- SwiftData tests that touch a `ModelContext` should use `ModelContext(container)` rather than `container.mainContext` — `mainContext` is `@MainActor`-isolated and crashes under Swift Testing's parallel execution.
- Do not ship a feature without at least one test per public method.

## Conventions
- Swift Testing framework (not XCTest) — use `@Test`, `#expect()`, `import Testing`
- Header doc comments on all public/internal functions
- `ModelContainerFactory.makePreviewContainer()` for test and preview contexts
- Cached `DateFormatter` instances (static lets) — never allocate in computed properties
- **Sheets sync `syncNow()` vs `performSync()` must stay split.** The debounce `Task` calls `performSync()` directly. Calling `syncNow()` from inside the debounce task would `.cancel()` the task on itself, propagating cancellation to the in-flight `URLSession` and surfacing as `CancellationError("cancelled")`. `StubGoogleSheetsAPI.overwriteSheet` calls `Task.checkCancellation()` to catch regressions of this pattern.

## File Layout
```
Packages/
  AICoachCore/   Shared library: prompt builder, coaching types, formatters, GenerationConfig
Evals/           AI coach eval CLI + Python eval runner
Models/          Data models and enums
Config/          ModelContainer, environment keys (units, aiCoach), UITestFixtures
Extensions/      Date+Week, Double+Distance (distance, duration, pace formatting)
Services/
  AICoach/       Protocol, MLX implementation, stub, type conversions
Views/
  AerobicTraining/  Training tab
  History/          History tab (calendar, workout list, detail sheet)
  Strength/         Strength tab
  Shared/           Cross-tab building blocks (e.g. WorkoutFormFields)
```

## Key Files
- `Packages/AICoachCore/Sources/AICoachCore/AICoachPromptBuilder.swift` — stateless prompt serialization (shared by app + evals)
- `Packages/AICoachCore/Sources/AICoachCore/GenerationConfig.swift` — single source of truth for LLM generation parameters
- `Config/ModelContainerFactory.swift` — single place for container/CloudKit config
- `Config/AICoachEnvironment.swift` — `@Environment(\.aiCoach)` key; default is `StubAICoachService`
- `Config/UITestFixtures.swift` — deterministic fixture seed activated by `-uiTestSeed` launch arg
- `Extensions/Date+Week.swift` — all calendar arithmetic
- `Extensions/Double+Distance.swift` — distance, duration, and pace formatting (`Int.formattedPace(distanceMiles:metric:)` for min/mile and min/km)
- `Models/ExerciseType.swift` — exercise type enum with icons and colors
- `Services/AICoach/AICoachService.swift` — protocol + `AICoachError` enum
- `Services/AICoach/MLXAICoachService.swift` — production coach; swap model via `modelID` constant
- `Services/AICoach/CoachTypeConversions.swift` — SwiftData → AICoachCore type bridge
- `Services/GoogleSheetsSync/GoogleSheetsSyncCoordinator.swift` — debounce + lifecycle + `GoogleSheetsSyncStatus` enum
- `Services/GoogleSheetsSync/GoogleSheetsAPI.swift` — protocol + Live (GoogleSignIn + URLSession) + Stub implementations
- `Views/Shared/WorkoutFormFields.swift` — reusable workout form sections shared by `RecordWorkoutSheet` (create) and `WorkoutDetailSheet` (edit)
- `Views/History/WorkoutDetailSheet.swift` — edit + delete popup for a recorded workout; contains the `WorkoutEditor` helper enum that owns the mutation path (unit-tested)
- `Views/History/WorkoutListView.swift` — discrete 10-per-page pagination, tappable rows, calendar-driven navigation/highlight, `WorkoutListPagination` helper for testable page math
