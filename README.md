# Hybrid AIthletics

Hybrid AIletics (pronunciation: `/eɪˈθlɛtɪks/`; "ay-THLET-iks") is an iOS exercise tracking application designed for hybrid athletes with a focus on endurance training. It is a *personal* fitness application, explicitly without social aspects to support the notion that our fitness journies should not be built on comparison but through self-motivation to reach our own health and fitness goals.

The app helps plan weekly training routines, record completed workouts, and track mileage over time. It also provides dynamic exercise program insights and suggestions utilizing onboard AI. We explicitly opt to use small language models which can run entirely on your own mobile device for several key reasons:

1. We believe that you should always have complete ownership of your data. Your health data will never be shared with an AI provider / company through any API; it never leaves your phone (though, we do support ICloud storage, but this is highly secure and not shared with 3rd parties).
2. We want you to feel comfortable getting AI insights on your training as often as possible, without worrying about environmental impact: your usage is not adding to the plethora of data centers using energy and water; it's all on-device with lightweight AI models.
3. We will always maintain a **zero-subscription model**. We are tired of the subscription economy, too, and want to provide a highly-functional tool to aid you in your health and endurance competition journey, that will keep you performing at your peak for years to come.

We don't withhold any features from the free app. Upgrade one time only to support the creators and unlock an ad-free experience. Forever.

## Features

### Aerobic Training (Tab 1)
- **Weekly calendar** with Monday-Sunday swimlanes showing planned exercises
- **Drag-and-drop** to reschedule exercises between days
- **Mileage header** showing planned vs. completed miles for the current week with progress indicator
- **Record workouts** via the checkmark button on any exercise — pre-fills from the plan, all fields editable
- **Repeat weekly** — mark any exercise as repeating and it automatically appears on the same day every week
- **Exercise types**: Run, Long Run, Tempo Run, Interval Run, Easy Run, Recovery Run, Walk, Bike, Swim, Hike, Elliptical, Other

### AI Coach
- **On-device running coach** powered by Google's Gemma 3 4B running locally via [MLX-Swift](https://github.com/ml-explore/mlx-swift-examples)
- Reviews the last four weeks of recorded workouts — including a new **"How did it feel?" (1–10 RPE)** rating — and the next two weeks of scheduled exercises
- Suggests concrete adaptations: workout type, duration, distance, intensity, additions, or removals
- **Fully offline** after initial model download, no API calls, no subscription — aligned with the one-time-payment business model
- Model weights (~2 GB) are downloaded from Hugging Face on first use and cached locally for offline access

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
| On-device LLM | MLX-Swift + Gemma 3 4B QAT (4-bit, Apache 2.0, downloaded on first use) |
| Testing | Swift Testing framework |
| Min iOS | 17.0 |

## Project Layout

```
Hybrid AIthletics/
  Models/           SwiftData @Model classes and ExerciseType enum
  Config/           ModelContainer factory, environment keys (units, aiCoach)
  Extensions/       Date arithmetic, distance formatting
  Services/
    AICoach/        Protocol-based on-device coach (MLX + Gemma 3 4B)
  Views/
    AerobicTraining/  Weekly calendar, exercise cards, add/record sheets, AI coach sheet
    Strength/         Placeholder view
    History/          Summary stats, monthly calendar, workout list
  ContentView.swift   Root TabView
  Hybrid_AIthleticsApp.swift  App entry point (injects AICoachService)
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for architecture documentation, [docs/DATA_MODEL.md](docs/DATA_MODEL.md) for an in-depth data model reference, [docs/adrs/](docs/adrs/) for architectural decision records, [docs/MOBILE_TESTING.md](docs/MOBILE_TESTING.md) for testing on a physical iPhone, and [docs/RELEASING.md](docs/RELEASING.md) for App Store publishing instructions.

## Building

Open `Hybrid AIthletics.xcodeproj` in Xcode 15+ and build for an iOS 17+ simulator or device.

### AI Coach Model

The AI coach model (~2 GB, Gemma 3 4B QAT 4-bit) downloads automatically from Hugging Face on first use and is cached locally for offline access. No manual setup is required — the MLXLLM framework handles downloading and caching transparently.

> **Note:** The app compiles, runs, and passes all tests without any model present. All unit tests use `StubAICoachService`.

### CloudKit Setup

CloudKit sync is configured but requires a container ID registered in the Apple Developer portal. Update the container identifier in:
1. `Hybrid_AIthletics.entitlements` — `icloud-container-identifiers` array
2. Apple Developer portal — register the iCloud container

## Running Tests

Tests use the Swift Testing framework.

### Unit Tests (macOS — fast, no simulator needed)

Run from Xcode (Cmd+U) or via CLI:

```bash
# Run all unit tests on macOS
xcodebuild test -scheme "Hybrid AIthletics" \
  -only-testing:"Hybrid AIthleticsTests"
```

Unit tests run on macOS and don't require a simulator. They're fast and test all SwiftData models, CSV parsing, date/distance formatting, and logic layer code. Tests use `StubAICoachService` so the model is not needed.

### UI Tests (iOS Simulator)

Run UI tests with:

```bash
# Run all UI tests on iPhone 17 simulator
xcodebuild test -scheme "Hybrid AIthletics" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:"Hybrid AIthleticsUITests"
```

UI tests exercise the full app in the simulator and validate multi-step flows like calendar navigation, workout recording, and deletion.

### AICoachCore Package Tests

Test the shared prompt-building library:

```bash
cd Packages/AICoachCore && swift test
```

## Distance Units

All distances are stored internally in miles. A central `AppConfiguration` model controls display units (miles or kilometers), propagated via a SwiftUI `EnvironmentKey`. To switch to metric, update `AppConfiguration.useMetricUnits` — all views react automatically.

## License

This project is licensed under the [MIT License](LICENSE) with the [Commons Clause](https://commonsclause.com/) condition. You are free to view, fork, modify, and contribute to the source code, but you may not sell the software or any product substantially derived from it. See the [LICENSE](LICENSE) file for full terms.
