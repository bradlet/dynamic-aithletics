# Future Model Upgrade: Gemma 4 via LiteRT-LM

## Current State

The AI coach uses **Gemma 3 4B QAT 4-bit** (`mlx-community/gemma-3-4b-it-qat-4bit`) via MLX-Swift. The model is downloaded from Hugging Face on first use and cached locally. Generation parameters are centralized in `AICoachCore.GenerationConfig.production`.

**Known issue:** The model produces poor output with mlx-swift 0.29.1 due to quantized inference bugs. Python MLX 0.31.1 produces excellent output from the same model and prompt. Updating `mlx-swift-examples` to a version that depends on mlx-swift 0.31.x+ should fix this. Verify with `cd Evals && python3 eval_runner.py` after updating.

## Why Gemma 4 Was Deferred

As of April 2026, Gemma 4 cannot run on iOS:

- **MLX-Swift:** `"gemma4"` is not in MLXLLM's built-in type registry (v2.29.1). Registering it under the Gemma 3 architecture causes parameter shape mismatches at runtime. Open issue: [ml-explore/mlx-swift-examples#467](https://github.com/ml-explore/mlx-swift-examples/issues/467).
- **LiteRT-LM:** Google's official edge inference framework supports Gemma 4, but the Swift SDK is marked "In Dev / Coming Soon" with no ETA. Only Kotlin, Python, and C++ are production-ready.

## When to Revisit

Check these periodically:

| Source | What to look for |
|--------|-----------------|
| [ml-explore/mlx-swift-examples releases](https://github.com/ml-explore/mlx-swift-examples/releases) | `"gemma4"` added to `LLMTypeRegistry` |
| [Google AI Edge LiteRT-LM](https://github.com/nicholasgasior/litertlm-swift) | Swift SDK reaches stable release |
| [google-ai-edge/LiteRT](https://github.com/google-ai-edge/LiteRT) | Official Swift/iOS samples published |

## Migration Steps (when ready)

### Option A: MLX-Swift adds Gemma 4 support

1. Update the mlx-swift-examples SPM dependency to the version that includes `"gemma4"`.
2. In `MLXAICoachService.swift`, change `modelID` to the Gemma 4 E2B MLX quant repo (e.g. `"mlx-community/gemma-4-e2b-it-4bit"`).
3. Update documentation references from Gemma 3 to Gemma 4.
4. Verify with eval suite: `cd Evals && python3 eval_runner.py` — all scenarios should score >= 80/100.
5. Test on a physical device — verify generation quality and performance.

### Option B: LiteRT-LM Swift SDK ships

1. Add the LiteRT-LM Swift package via SPM.
2. Create a new `LiteRTAICoachService` implementing `AICoachService`.
3. Use the `.litertlm` model format (download or bundle as appropriate).
4. Swap the service injection in `Hybrid_AIthleticsApp.swift`.
5. Optionally remove the mlx-swift-examples dependency if no longer needed.

The `AICoachService` protocol boundary was designed to make runtime swaps cheap — no view or test code needs to change.
