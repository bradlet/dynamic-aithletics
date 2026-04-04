# Data Model Reference

This document provides a detailed reference for the Dynamic AIthletics data model. It is written for senior engineers who may not have direct experience with Swift or SwiftData and need to understand the persistence layer, relationships, and design rationale.

## Technology Overview

Dynamic AIthletics uses **SwiftData**, Apple's ORM framework built on top of Core Data. If you're coming from other ecosystems:

- SwiftData is analogous to **SQLAlchemy** (Python), **ActiveRecord** (Ruby), or **Entity Framework** (.NET). It maps Swift classes to persistent storage (SQLite under the hood) and handles schema creation, migrations, and object lifecycle.
- The `@Model` macro (similar to a decorator/annotation) marks a class as a persistent entity. SwiftData inspects the class's properties at compile time and generates the necessary storage schema.
- **CloudKit sync** is layered on top — SwiftData can automatically mirror local records to Apple's cloud database so data syncs across a user's devices. This imposes a constraint: **every property must have a default value**, because CloudKit may deliver partial records during sync.

## Entity-Relationship Diagram

```
┌─────────────────────────┐       ┌─────────────────────────┐
│        Exercise          │       │         Workout          │
│─────────────────────────│       │─────────────────────────│
│ id: UUID                 │       │ id: UUID                 │
│ name: String             │       │ name: String             │
│ type: ExerciseType       │  1:N  │ type: ExerciseType       │
│ durationSeconds: Int     │◄──────│ durationSeconds: Int     │
│ distanceMiles: Double    │       │ distanceMiles: Double    │
│ notes: String            │       │ notes: String            │
│ scheduledDate: Date      │       │ date: Date               │
│ isRepeating: Bool        │       │ sourceExercise: Exercise? │
│ workouts: [Workout]      │       └─────────────────────────┘
└─────────────────────────┘
                                   ┌─────────────────────────┐
                                   │    AppConfiguration      │
                                   │─────────────────────────│
                                   │ useMetricUnits: Bool     │
                                   └─────────────────────────┘

                                   ┌─────────────────────────┐
                                   │     ExerciseType         │
                                   │─────────────────────────│
                                   │ (enum, not a table)      │
                                   │ 12 cases: run, longRun,  │
                                   │ tempoRun, intervalRun,   │
                                   │ easyRun, recoveryRun,    │
                                   │ walk, bike, swim, hike,  │
                                   │ elliptical, other        │
                                   └─────────────────────────┘
```

## Entities

### Exercise

**File:** `Models/Exercise.swift`

An Exercise represents a **planned workout** on the user's weekly training calendar. Think of it as a calendar event — "5K Run on Monday" — that may or may not be completed.

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `id` | `UUID` | Auto-generated | Primary key. Also used as the drag-and-drop transfer payload (only the UUID is serialized during drag, not the full object). |
| `name` | `String` | `""` | User-facing label, e.g. "Morning 5K", "Tempo Thursday". |
| `type` | `ExerciseType` | `.run` | Activity category. Stored as the enum's `String` raw value in the database (e.g. `"Tempo Run"`). See [ExerciseType](#exercisetype) below. |
| `durationSeconds` | `Int` | `0` | Planned duration. Stored in seconds to avoid floating-point precision issues. The UI decomposes this into hours/minutes/seconds for display and editing. |
| `distanceMiles` | `Double` | `0.0` | Planned distance in **miles**. This is the canonical storage unit regardless of user preference. Conversion to kilometers happens at the view layer only. See [Distance Convention](#distance-convention). |
| `notes` | `String` | `""` | Free-text field for user notes about the planned exercise. |
| `scheduledDate` | `Date` | `Date()` | The day this exercise is assigned to. **Always normalized to midnight** (start of day) via `Date.startOfDay` in the initializer. This ensures date-range queries work correctly — comparing `scheduledDate >= mondayMidnight && scheduledDate <= sundayMidnight` captures all exercises for a week without time-of-day edge cases. |
| `isRepeating` | `Bool` | `false` | When `true`, this exercise acts as a template that appears "virtually" on the same day-of-week every future week. See [Repeating Exercises](#repeating-exercises). |
| `workouts` | `[Workout]` | `[]` | Inverse relationship. All `Workout` records that were created from this exercise. See [Exercise-Workout Relationship](#exercise-workout-relationship). |

**Initialization behavior:** The initializer normalizes `scheduledDate` to midnight. This means if you create `Exercise(scheduledDate: "2026-04-04 at 3:30 PM")`, the stored date will be `2026-04-04 at 00:00:00`. This is intentional — exercises are day-level entities, not time-level.

---

### Workout

**File:** `Models/Workout.swift`

A Workout represents a **completed exercise session** — the user actually ran, biked, swam, etc. It is a separate entity from Exercise because:

1. A user may complete an exercise with different values than planned (ran 4 miles instead of 3).
2. A user may record a workout without any prior plan.
3. Multiple workouts can be recorded from the same exercise template (e.g., recording a morning and evening session).

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `id` | `UUID` | Auto-generated | Primary key. |
| `name` | `String` | `""` | Name as recorded. Pre-filled from the source exercise but editable. |
| `type` | `ExerciseType` | `.run` | Activity category. Same enum as Exercise. |
| `durationSeconds` | `Int` | `0` | Actual duration in seconds. |
| `distanceMiles` | `Double` | `0.0` | Actual distance in miles. Same storage convention as Exercise. |
| `notes` | `String` | `""` | Post-workout notes (e.g. "felt great", "knee pain at mile 2"). |
| `date` | `Date` | `Date()` | When the workout was performed. Unlike Exercise, this **preserves the full timestamp** (not normalized to midnight) so the app can display time-of-day. |
| `sourceExercise` | `Exercise?` | `nil` | Optional back-reference to the planned exercise this workout was recorded from. `nil` if the workout was logged independently. |

**Factory method: `Workout.draft(from:)`**

Creates a new Workout pre-filled from an Exercise template. This is the entry point when a user taps "Record Workout" on a planned exercise. The draft copies `name`, `type`, `durationSeconds`, and `distanceMiles` from the exercise, sets `sourceExercise` to establish the relationship, and leaves `notes` empty (the user provides fresh notes for each workout). The user can edit every field before saving.

---

### AppConfiguration

**File:** `Models/AppConfiguration.swift`

A **singleton** preferences record. The app creates exactly one instance on first launch and reads it reactively. There is no settings screen yet — the value is programmatically set and will be exposed to the user in a future release.

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `useMetricUnits` | `Bool` | `false` | When `true`, distances display in kilometers. When `false`, miles. |

**Singleton pattern:** `AppConfiguration.current(in:)` is a fetch-or-create method. It queries SwiftData for an existing record; if none exists, it inserts a new one with defaults. In the actual app, `ContentView` uses SwiftData's `@Query` macro to observe the configuration reactively and injects the value into SwiftUI's environment system so any view in the hierarchy can read it without its own database query.

**Why is this a database record and not UserDefaults?** Because it syncs via CloudKit alongside the other models, so a user's unit preference follows them across devices.

---

### ExerciseType

**File:** `Models/ExerciseType.swift`

This is a Swift `enum` — **not a database table**. It's stored inline as a `String` column in both the Exercise and Workout tables.

```
ExerciseType: String (raw values)
├── run          → "Run"
├── longRun      → "Long Run"
├── tempoRun     → "Tempo Run"
├── intervalRun  → "Interval Run"
├── easyRun      → "Easy Run"
├── recoveryRun  → "Recovery Run"
├── walk         → "Walk"
├── bike         → "Bike"
├── swim         → "Swim"
├── hike         → "Hike"
├── elliptical   → "Elliptical"
└── other        → "Other"
```

Each case has two computed properties for UI rendering:
- **`systemImage`**: An SF Symbols icon name (Apple's built-in icon library, similar to Material Icons or FontAwesome). All running variants share `"figure.run"`.
- **`color`**: A SwiftUI `Color` for visual grouping. Running types are blue/orange/green by intensity; cross-training types each have a distinct color.

**Serialization:** The enum conforms to `Codable` with `String` raw values. When SwiftData persists an Exercise with `type = .tempoRun`, the database column stores the string `"Tempo Run"`. When reading back, SwiftData deserializes the string into the enum case. Adding new cases is backward-compatible as long as existing raw values don't change.

---

## Relationships

### Exercise-Workout Relationship

This is a **one-to-many** relationship: one Exercise can have many Workouts, but each Workout references at most one Exercise.

```
Exercise (1) ──────── (0..N) Workout
             workouts ◄──── sourceExercise
```

**Ownership and lifecycle:**

The relationship is declared on the Exercise side:

```swift
@Relationship(deleteRule: .nullify, inverse: \Workout.sourceExercise)
var workouts: [Workout] = []
```

Key aspects for non-Swift developers:

- **`deleteRule: .nullify`** — When an Exercise is deleted, its associated Workouts are **not deleted**. Instead, their `sourceExercise` field is set to `nil`. This preserves workout history even if the user removes the plan. This is equivalent to `ON DELETE SET NULL` in SQL.
- **`inverse: \Workout.sourceExercise`** — Tells SwiftData that the `workouts` array on Exercise and the `sourceExercise` property on Workout are two sides of the same relationship. SwiftData maintains referential integrity automatically — inserting a Workout with `sourceExercise = someExercise` also appends it to `someExercise.workouts`.
- The relationship is **optional on the Workout side** (`Exercise?`). Workouts can exist independently (logged without a plan).

**Querying patterns:**

```
"What workouts came from this exercise?"     → exercise.workouts
"Was this exercise completed this week?"     → exercise.workouts.contains { ... }
"Which exercise was this workout based on?"  → workout.sourceExercise
"Is this a standalone workout?"              → workout.sourceExercise == nil
```

---

## Repeating Exercises

Exercises with `isRepeating = true` behave as **templates** that appear on the same day-of-week every week from the current week forward.

### How it works

The system uses a **virtual display with on-demand materialization** pattern:

1. **No records are pre-created.** A single Exercise with `isRepeating = true` and `scheduledDate = Monday April 6` is the only database record.

2. **Virtual display:** When the user views a future week (e.g., April 13-19), the app's query logic checks: "Are there any repeating exercises whose day-of-week matches a day in this week?" If `scheduledDate` falls on a Monday (index 0), the exercise appears on every future Monday.

3. **Duplicate suppression:** If a concrete Exercise with the same `name`, `type`, and day-of-week already exists for the target week, the virtual instance is not shown. This prevents duplicates after materialization.

4. **Materialization:** When the user interacts with a virtual exercise (records a workout, edits it, or drags it), the app creates a new **concrete** Exercise record for that specific date with `isRepeating = false`. The original template remains unchanged.

5. **Past weeks:** Virtual repeating exercises only appear for the current week and future weeks. Past weeks show only concrete records — what was actually scheduled and/or materialized.

### Data flow example

```
Week 1: User creates "Monday Run" with isRepeating=true, scheduledDate=Apr 6
         → Database: 1 Exercise record

Week 2: User views Apr 13-19
         → App finds the repeating exercise, mondayBasedWeekdayIndex=0
         → Monday Apr 13 has no concrete "Monday Run"
         → Virtual instance displayed on Monday Apr 13

Week 2: User taps "Record Workout" on the virtual Monday Run
         → App materializes: creates new Exercise(scheduledDate=Apr 13, isRepeating=false)
         → Workout created with sourceExercise pointing to the new concrete Exercise
         → Database: 2 Exercise records, 1 Workout record

Week 3: User views Apr 20-26
         → Virtual instance displayed on Monday Apr 20 (no concrete exists yet)
```

---

## Distance Convention

All distance values are stored in **miles** regardless of user preference. This is a single-source-of-truth pattern that avoids lossy round-trip conversions.

```
Storage (miles) ──► Conversion at display ──► UI (miles or km)
                    Double.formattedDistance(metric:)
                    Double.toDisplayDistance(metric:)

UI input (miles or km) ──► Conversion at save ──► Storage (miles)
                           distance / 1.60934 (if metric)
```

The conversion factor is `1 mile = 1.60934 km`. Conversion functions live in `Extensions/Double+Distance.swift`. The metric preference is read from the SwiftUI environment (`@Environment(\.useMetricUnits)`) which is set by `ContentView` based on `AppConfiguration`.

---

## Persistence Infrastructure

### ModelContainerFactory

**File:** `Config/ModelContainerFactory.swift`

A factory enum (no instances, only static methods) that creates SwiftData's `ModelContainer` — the top-level object that owns the database connection, schema, and sync configuration.

| Method | Storage | CloudKit | Use case |
|--------|---------|----------|----------|
| `makeContainer()` | On-disk (SQLite) | Enabled (`.automatic`) | Production app |
| `makePreviewContainer()` | In-memory only | Disabled | Unit tests and SwiftUI previews |

The schema is explicitly defined as `[Exercise.self, Workout.self, AppConfiguration.self]`. All three entities are registered regardless of which container type is created.

### UnitEnvironment

**File:** `Config/UnitEnvironment.swift`

Defines a custom SwiftUI `EnvironmentKey` for the metric preference. This is a **dependency injection** mechanism:

1. `ContentView` reads `AppConfiguration.useMetricUnits` from SwiftData.
2. It injects this value into the view hierarchy via `.environment(\.useMetricUnits, value)`.
3. Any descendant view reads it via `@Environment(\.useMetricUnits)`.

This avoids each view needing its own database query for the unit preference. The environment value updates reactively when the configuration changes.

---

## Schema Versioning and Migration

SwiftData handles **lightweight migrations** automatically when properties are added with default values. The addition of `isRepeating: Bool = false` to Exercise is a backward-compatible change — existing records get `false` automatically, and no explicit migration code is needed.

If a future change requires a non-trivial migration (renaming a column, changing a relationship's cardinality, splitting a table), SwiftData provides `VersionedSchema` and `MigrationPlan` APIs for explicit migration steps.

---

## CloudKit Compatibility Constraints

All model properties **must have default values** in their declarations (not just in initializers). This is because CloudKit may deliver partial records during sync — a record might arrive with some fields populated and others using defaults. The `@Model` class declarations satisfy this:

```swift
var name: String = ""           // Not var name: String (would crash on partial sync)
var distanceMiles: Double = 0.0
var isRepeating: Bool = false
```

Optional relationships (`sourceExercise: Exercise?`) are inherently compatible since they default to `nil`.
