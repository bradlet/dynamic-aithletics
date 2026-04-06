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

### AI Coach
- **On-device running coach** powered by Google's Gemma 4 E2B running locally via [MLX-Swift](https://github.com/ml-explore/mlx-swift-examples)
- Reviews the last four weeks of recorded workouts — including a new **"How did it feel?" (1–10 RPE)** rating — and the next two weeks of scheduled exercises
- Suggests concrete adaptations: workout type, duration, distance, intensity, additions, or removals
- **Fully offline**, no API calls, no subscription — aligned with the one-time-payment business model
- Model weights are bundled in the app binary (Gemma 4 E2B 4-bit MLX quant, ~1.5 GB)

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
| On-device LLM | MLX-Swift + Gemma 4 E2B (4-bit MLX quant, Apache 2.0) |
| Testing | Swift Testing framework |
| Min iOS | 17.0 |

## Project Layout

```
Dynamic AIthletics/
  Models/           SwiftData @Model classes and ExerciseType enum
  Config/           ModelContainer factory, environment keys (units, aiCoach)
  Extensions/       Date arithmetic, distance formatting
  Services/
    AICoach/        Protocol-based on-device coach (MLX + Gemma 4 E2B)
  Resources/
    Models/         Bundled Gemma 4 E2B MLX weights (see docs/adrs/1-...)
  Views/
    AerobicTraining/  Weekly calendar, exercise cards, add/record sheets, AI coach sheet
    Strength/         Placeholder view
    History/          Summary stats, monthly calendar, workout list
  ContentView.swift   Root TabView
  Dynamic_AIthleticsApp.swift  App entry point (injects AICoachService)
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for architecture documentation, [docs/DATA_MODEL.md](docs/DATA_MODEL.md) for an in-depth data model reference, [docs/adrs/](docs/adrs/) for architectural decision records, [docs/MOBILE_TESTING.md](docs/MOBILE_TESTING.md) for testing on a physical iPhone, and [docs/RELEASING.md](docs/RELEASING.md) for App Store publishing instructions.

## Building

Open `Dynamic AIthletics.xcodeproj` in Xcode 15+ and build for an iOS 17+ simulator or device.

### AI Model Weights

The AI Coach feature requires the Gemma 4 E2B MLX weights to be present in the project before building. The weights are **not checked into the repository** (they are ~1.5 GB). You must download them from Hugging Face and add them to Xcode as a folder reference.

**Model page:** [huggingface.co/unsloth/gemma-4-E2B-it-UD-MLX-4bit](https://huggingface.co/unsloth/gemma-4-E2B-it-UD-MLX-4bit)

**Download steps:**

1. Install the Hugging Face CLI if you don't have it:
   ```bash
   pip install huggingface_hub
   ```
   This provides the `hf` CLI command.

2. Download the model weights (requires a free Hugging Face account — run `hf auth login` first):
   ```bash
   hf download unsloth/gemma-4-E2B-it-UD-MLX-4bit \
     --local-dir "Dynamic AIthletics/Resources/Models/gemma-4-e2b-it-mlx-4bit"
   ```
   This places all safetensors, tokenizer, and config files inside the expected directory.

3. In Xcode, add the directory as a **folder reference** (blue folder icon, not yellow group):
   - Right-click `Resources/Models` in the Xcode navigator
   - **Add Files to "Dynamic AIthletics"…**
   - Select `gemma-4-e2b-it-mlx-4bit/`, check **"Create folder references"**, and confirm
   - Verify it appears as a blue folder under `Resources/Models`

4. Confirm the folder is listed under **Build Phases → Copy Bundle Resources**.

**To re-download** (e.g. after wiping your local copy or when a new checkpoint is released):
```bash
hf download unsloth/gemma-4-E2B-it-UD-MLX-4bit \
  --local-dir "Dynamic AIthletics/Resources/Models/gemma-4-e2b-it-mlx-4bit"
```
The CLI is incremental — it skips files that already exist and have matching checksums.

> **Note:** The app compiles and runs without the weights present. `MLXAICoachService` throws `AICoachError.notImplemented` when the model directory is missing. All unit tests use `StubAICoachService` and do not require the weights.

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
