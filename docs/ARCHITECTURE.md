# Architecture

## Overview

Hybrid AIthletics uses a flat-layered architecture with SwiftUI + SwiftData. There are no ViewModels — SwiftData's `@Query` macro provides reactive data binding directly in views.

## Layers

```
Models/                    @Model classes, enums (data layer)
Config/                    ModelContainer setup, environment keys (infrastructure)
Extensions/                Date arithmetic, formatting (utilities)
Services/                  Protocol-based service layer (AI coach)
Views/                     SwiftUI views grouped by tab (presentation)
```

## Data Models

### Exercise
A planned workout assigned to a specific date in the weekly training calendar.

- `scheduledDate` is normalized to midnight (start of day) for consistent date-range queries
- Has a one-to-many relationship with `Workout` (delete rule: `.nullify`)
- `id: UUID` is explicit for drag-and-drop `Transferable` support

### Workout
A recorded instance of completing an exercise.

- `date` preserves full timestamp (not normalized) for time-of-day display
- Optional `sourceExercise` back-reference to the plan it was recorded from
- `Workout.draft(from:)` factory creates a pre-filled workout from an exercise template
- `feltRating: Int` — subjective Rate of Perceived Exertion (1–10), `0` when unrated. Feeds the AI coach's training-load assessment.

### AppConfiguration
Singleton preferences stored in SwiftData for CloudKit sync.

- `useMetricUnits: Bool` — controls distance display across the app
- Accessed via `@Query` in `ContentView`, propagated as a SwiftUI `EnvironmentKey`

### ExerciseType
`String`-backed enum shared by Exercise and Workout. Provides `systemImage` and `color` computed properties for consistent UI rendering.

## Key Design Decisions

### @Query placement
Only top-level tab views (`AerobicTrainingView`, `HistoryView`) and `ContentView` own `@Query` properties. All child views receive data as plain `let` parameters. This minimizes SwiftData subscription overhead — each `@Query` causes its entire view subtree to re-evaluate on any change to the queried model type.

### Distance storage
All distances are stored in miles internally. Conversion to display units (km) happens at the view layer using `Double.formattedDistance(metric:)` and `Double.toDisplayDistance(metric:)`. The `useMetricUnits` flag is read from the environment.

### Week boundaries
The app uses Monday as the first day of the week regardless of locale. A private `mondayCalendar` (with `firstWeekday = 2`) is used for all week boundary calculations in `Date+Week.swift`.

### Drag-and-drop
Exercises use a lightweight `ExerciseDragItem` (carrying only a UUID) as the `Transferable` payload. The custom UTType `com.hybridaithletics.exercise` is registered in Info.plist via `UTExportedTypeDeclarations`. The drop handler looks up the exercise by ID and mutates `scheduledDate`. Full model objects are never serialized for drag transfer.

### Repeating exercises
Exercises can be marked as `isRepeating: Bool`. A repeating exercise serves as a template that appears virtually on its matching day-of-week for the current week and all future weeks.

**Virtual display**: `AerobicTrainingView.weekExercises` includes repeating exercises from other weeks whose `mondayBasedWeekdayIndex` matches a day in the displayed week, provided no concrete instance (same name + type + day) already exists. Virtual exercises only appear for the current week forward — past weeks show only concrete data.

**On-demand materialization**: When the user interacts with a virtual exercise (record, edit, or drag), `WeeklyCalendarView.materializeIfNeeded` creates a concrete copy with `isRepeating: false` for that specific day. The original template remains unchanged.

**Day matching**: `WeeklyCalendarView.exercisesForDay` matches exercises by `isSameDay` (concrete) or `mondayBasedWeekdayIndex` (virtual repeating).

### CloudKit sync
Configured via `ModelConfiguration(cloudKitDatabase: .automatic)` in `ModelContainerFactory`. All model properties have default values for CloudKit compatibility. The CloudKit container ID must be registered in the Apple Developer portal and match the entitlements file.

### AI Coach service layer
The on-device coaching feature lives behind a protocol, `AICoachService`, so the rest of the app never imports MLX or any specific runtime directly.

**Protocol and environment injection.** `Services/AICoach/AICoachService.swift` defines `suggestAdaptations(_:)` and `streamSuggestion(_:)`. The service is exposed via `@Environment(\.aiCoach)` (`Config/AICoachEnvironment.swift`). The default environment value is `StubAICoachService`, so SwiftUI previews and unit tests never accidentally load real model weights. The app root (`Hybrid_AIthleticsApp.swift`) replaces the default with an `MLXAICoachService` instance at launch.

**Implementations.**
- `StubAICoachService` — returns a deterministic canned response and streams it in small chunks with artificial delay. Used by previews and tests.
- `MLXAICoachService` — production implementation backed by Gemma 3 4B via MLX-Swift. The model is downloaded from Hugging Face on first use and cached locally. The actual MLX calls are gated behind `#if canImport(MLXLLM)` so the file compiles even before the SPM dependency is added, throwing `AICoachError.notImplemented` until the dependency is in place.

**Prompt construction.** `AICoachPromptBuilder` is a stateless namespace enum that turns a `CoachingRequest` (recent workouts + upcoming exercises + unit preference) into a prompt string. It reuses `Double.formattedDistance(metric:)` and the cached `lineDateFormatter` and skips RPE lines when `feltRating == 0`.

**Request ownership.** The top-level `AerobicTrainingView` assembles the `CoachingRequest` from its own `@Query` data (last 4 weeks of workouts, next 2 weeks of exercises) in keeping with the project's "only top-level views hold queries" rule.

### Model delivery
The Gemma 3 4B QAT 4-bit model is **not bundled** in the app binary. Instead, `MLXAICoachService` uses `ModelConfiguration(id: "mlx-community/gemma-3-4b-it-qat-4bit")` to download the weights from Hugging Face on first use (~2 GB). MLXLLM caches the download in the app's caches directory for offline access on subsequent launches. This keeps the app binary small and eliminates the need for developers to manually download and configure model weights.

## Data Flow

### Adding an exercise
```
AddExerciseSheet → modelContext.insert(Exercise) → SwiftData persists →
CloudKit sync (async) → @Query in AerobicTrainingView fires → UI updates
```

### Recording a workout
```
ExerciseCardView tap → RecordWorkoutSheet → Workout.draft(from: exercise) pre-fills form →
User edits & saves → modelContext.insert(Workout) → @Query updates both tabs
```

### Rescheduling via drag-and-drop
```
Drag ExerciseCardView → ExerciseDragItem(UUID) transferred → Drop on target day →
exercise.scheduledDate = targetDay → SwiftData auto-saves → @Query fires → UI re-renders
```

### Interacting with a virtual repeating exercise
```
User taps record/edit on virtual exercise → materializeIfNeeded creates concrete copy →
concrete Exercise inserted into modelContext → callback receives concrete instance →
sheet opens with concrete exercise → @Query fires → UI shows new concrete + hides virtual
```

### Requesting AI coaching suggestions
```
User taps "Ask Coach" in AerobicTrainingView → buildCoachRequest() reads recent workouts
(last 4 weeks) and upcoming exercises (next 2 weeks) from @Query →
CoachingRequest assembled → AICoachSheet presented → on .task, calls
coach.streamSuggestion(request) → AICoachPromptBuilder serializes request to prompt →
MLXAICoachService (or StubAICoachService in previews) generates response token by token →
AICoachSheet appends chunks to responseText → UI updates live
```

## Testing

Unit tests cover:
- **Models**: persistence, relationships, factory methods, date normalization, repeat flag, felt-rating default and persistence
- **Extensions**: date arithmetic (week boundaries, month boundaries, same-day/week/month checks), distance formatting, duration formatting
- **Types**: ExerciseType codable round-trip, identifiable conformance
- **Drag items**: ExerciseDragItem codable round-trip
- **Repeat**: isRepeating default value, init parameter, persistence, day-of-week matching
- **AI Coach**: prompt builder formatting (RPE inclusion, notes handling, unit respect, ordering, empty inputs), `StubAICoachService` response and streaming

Tests use `ModelContainerFactory.makePreviewContainer()` for isolated in-memory SwiftData contexts. The MLX-backed coach is never exercised in unit tests — all coach tests run against `StubAICoachService`.
