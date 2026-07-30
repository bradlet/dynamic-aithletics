# AI Coach Evals

CLI tool for evaluating and iterating on the AI Coach's prompt design and generation parameters outside the iOS app. Runs the same Gemma 3 4B model with the same `AICoachCore` library used in production.

## Prerequisites

- **Apple Silicon Mac** (M1 or later) — MLX requires Metal
- **macOS 14+**
- **Swift 5.9+**
- **Python 3.9+** with `mlx-lm` (`pip3 install mlx-lm`)
- **~2 GB disk** for model weight download (first run only, cached afterward)

## Quick Start

```bash
cd Evals

# Inspect the prompt without running the model (Swift, no model needed)
swift run CoachEval inspect --scenario high-rpe --prompt-mode chat

# Run all scenarios with the Python eval runner
python3 eval_runner.py

# Run a single scenario
python3 eval_runner.py --scenario high-rpe

# Compare flat vs chat prompt modes
python3 eval_runner.py --compare --scenario high-rpe

# Override generation parameters
python3 eval_runner.py --scenario high-rpe --temperature 0.3 --repetition-penalty 1.0
```

### Why Python?

The eval runner uses Python MLX (`mlx-lm`) for model generation because Swift Package Manager CLI builds cannot compile Metal shaders correctly (the metallib is missing). The iOS app builds with Xcode, which handles Metal compilation properly, so this is only an issue for command-line eval tools. The Swift `coach-eval inspect` command is still used to generate prompts from `AICoachCore`, ensuring prompt consistency with the live app.

## Commands

### `run` — Run evaluation scenarios

Runs one or all scenarios through the model and reports quality scores.

```
swift run CoachEval run [OPTIONS]

Options:
  --scenario <id>              Run only this scenario (default: all)
  --prompt-mode <flat|chat>    How to format the prompt (default: chat)
  --temperature <float>        Override temperature (e.g. 0.3)
  --top-p <float>              Override top-p (e.g. 0.85)
  --repetition-penalty <float> Override repetition penalty (e.g. 1.2)
  --max-tokens <int>           Override max tokens (e.g. 300)
  --iterations <int>           Run each scenario N times (default: 1)
```

**Prompt modes:**
- `flat` — current app behavior: entire prompt (system preamble + training data) stuffed into a single user message. This is the broken baseline.
- `chat` — fixed behavior: system preamble sent as a system-role message, training data as a user-role message. This is the intended correct usage.

### `inspect` — Print raw prompt

Prints the formatted prompt for a scenario without running the model. Useful for iterating on prompt text.

```
swift run CoachEval inspect --scenario <id> [--prompt-mode <flat|chat>]
```

### `compare` — A/B test parameter configs

Runs the same scenario with multiple parameter configurations and displays a comparison table.

```
swift run CoachEval compare --scenario <id>
```

Compares four configs: `production` (flat), `production` (chat), `lowerRepPenalty` (chat), `conservative` (chat).

## Scenarios

| ID | Name | Description |
|---|---|---|
| `high-rpe` | High RPE Overtraining | 5 workouts at RPE 8-9 feeling weak/very weak, demanding upcoming plan. Expect volume reduction advice. |
| `balanced` | Balanced Training | 4 workouts at RPE 5-7 feeling normal to strong, reasonable plan. Expect minor tweaks. |
| `empty` | Empty History | No recent workouts, 3 upcoming. Expect acknowledgment of no data. |
| `single-hard` | Single Hard Workout | One long run at RPE 9 feeling very weak, "legs felt like lead", intervals next day. Expect postpone intensity. |
| `mixed` | Mixed Signals | Easy runs at low RPE + one interval at RPE 9 feeling very weak. Expect nuanced advice. |

Perceived exertion (1–10) and feeling (1–5) are independent optional signals on
`CoachWorkout`. Each is serialized verbatim into the workout line and omitted when
`nil` — every scenario except `single-hard` leaves at least one workout's `feeling`
unrecorded so the omission path stays covered:

```
- 2026-07-26 Sun Interval Run, 4.0 mi, 35:00, RPE 9/10, felt very weak — "struggled on last interval"
- 2026-07-29 Wed Easy Run, 4.0 mi, 35:00, RPE 8/10
```

## Scoring Rubric

Each response is scored on a 100-point scale:

| Check | Points | Pass Criteria |
|---|---|---|
| **Word count** | 20 | 50–200 words |
| **No repetition** | 20 | No word-trigram appears 3+ times |
| **Bullet structure** | 20 | 3–5 bullet lines (`- `, `* `, or numbered) |
| **Actionable language** | 15 | Contains coaching verbs: reduce, swap, add, cap, etc. |
| **No hallucination** | 15 | No exercise types or dates absent from the input |
| **Coherent ending** | 10 | Ends with punctuation, no template artifacts |

## Adding Scenarios

Add new scenarios to `Sources/CoachEval/Scenarios/ScenarioLibrary.swift`:

```swift
static let myScenario = EvalScenario(
    id: "my-scenario",
    name: "My Scenario",
    description: "What this tests.",
    request: CoachingRequest(
        recentWorkouts: [ /* CoachWorkout instances */ ],
        upcomingExercises: [ /* CoachExercise instances */ ],
        useMetricUnits: false
    ),
    expectations: EvalExpectations(
        expectedKeywords: ["reduce", "recovery"]
    )
)
```

Then add it to the `all` array in `ScenarioLibrary`.

## Iterating on Prompts

1. Edit the prompt in `Packages/AICoachCore/Sources/AICoachCore/AICoachPromptBuilder.swift`
2. Preview with: `swift run CoachEval inspect --scenario high-rpe`
3. Run eval: `swift run CoachEval run --scenario high-rpe`
4. Changes propagate to the iOS app automatically since both use `AICoachCore`

## Iterating on Generation Parameters

Use command-line overrides for quick experiments:

```bash
# Try lower temperature
swift run CoachEval run --scenario high-rpe --temperature 0.3

# Try lower repetition penalty
swift run CoachEval run --scenario high-rpe --repetition-penalty 1.2

# Try tighter token budget
swift run CoachEval run --scenario high-rpe --max-tokens 250
```

To lock in a new default, update `GenerationConfig.production` in `Packages/AICoachCore/Sources/AICoachCore/GenerationConfig.swift`. Both the app and eval CLI read from this single source of truth.

## Example Output

```
============================================================
Scenario: high-rpe (High RPE Overtraining)
Prompt mode: chat
============================================================

--- Generated Output ---
- Replace Friday's Interval Run with an Easy Run at 3.0 mi to allow recovery.
- Reduce Sunday's Tempo Run from 7.0 mi to 4.0 mi and keep the pace conversational.
- Shorten Tuesday's Long Run from 14.0 mi to 10.0 mi — your body needs time to absorb the recent load.
- Add a full rest day on Saturday before the tempo effort.
- Keep easy runs truly easy: RPE should stay at 4-5 for the next two weeks.

--- Quality Score: 90/100 ---
  [PASS] Word count: 87 words (target: 50–200) (20/20)
  [PASS] No repetition (20/20)
  [PASS] Bullet structure: 5 bullets found (expected: 3–5) (20/20)
  [PASS] Actionable language: Found: replace, reduce, shorten, add, keep (15/15)
  [PASS] No hallucination: No unreferenced exercise types (15/15)
  [FAIL] Coherent ending: Does not end with punctuation. (5/10)

Generation stats: 28.5 tok/s, 4.98s total
```

## Architecture

```
Evals/
├── Package.swift              # Depends on AICoachCore, mlx-swift-examples, ArgumentParser
└── Sources/CoachEval/
    ├── CoachEvalCLI.swift      # Entry point
    ├── Commands/               # run, inspect, compare
    ├── Generation/             # CoachGenerator (MLX model wrapper)
    ├── Scenarios/              # EvalScenario + ScenarioLibrary
    └── Evaluation/             # QualityScorer + EvalReport
```

The eval CLI shares the `AICoachCore` package with the iOS app, ensuring that the prompt builder, coaching types, formatters, and generation config are identical between evals and production.
