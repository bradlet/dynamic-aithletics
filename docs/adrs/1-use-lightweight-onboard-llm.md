# ADR 1: On-device LLM for the AI Coach feature

## Status

Accepted — 2026-04-06
**Amended — 2026-04-08:** Switched from Gemma 4 E2B (bundled) to Gemma 3 4B QAT (runtime download). See [Amendment](#amendment--2026-04-08) below.

## Context

Hybrid AIthletics ships as a **one-time-payment** iOS app (branded "Hybrid AIthletics"). The product vision includes an AI running coach that reviews the user's recent workouts — including a subjective 1–10 "how it felt" rating — and suggests adaptations to their upcoming two weeks of training.

A one-time-payment revenue model fundamentally constrains how we can deliver AI features:

- **Server-side LLM inference is not viable.** A user who pays once cannot continue to consume API tokens indefinitely on our dime. The unit economics break within a small number of interactions.
- **Subscription billing was considered and rejected.** It would solve the token-cost problem but contradicts the "Hybrid AIthletics" brand promise of a one-time purchase with premium AI features included.
- **Bring-your-own-API-key** (asking users to paste in their own OpenAI/Anthropic key) was rejected for UX reasons — it turns every AI interaction into a credentials-management problem and makes the premium experience feel half-finished.

The only remaining path that preserves both the business model and the user experience is **running a small LLM fully on-device**. This ADR captures the technology choices that make that feasible.

## Decision

We will integrate an on-device LLM with the following choices:

| Dimension | Choice |
|---|---|
| **Model** | Google Gemma 3 4B, QAT 4-bit quantization (`mlx-community/gemma-3-4b-it-qat-4bit`) |
| **Runtime** | MLX-Swift (Apple's native Swift machine-learning framework) |
| **Delivery** | Downloaded from Hugging Face on first use via MLXLLM's built-in `ModelConfiguration(id:)`, cached locally for offline access |
| **Abstraction** | `AICoachService` protocol in `Services/AICoach/` with `MLXAICoachService` and `StubAICoachService` implementations |

### Why Gemma 3 4B

- **Natively supported in MLXLLM.** Registered as `"gemma3"` in the built-in `LLMTypeRegistry` — no custom type registration hacks required.
- **Strong instruction-following and reasoning** for a 4B parameter model, including understanding of domain vocabulary (pace, RPE, tempo, intervals, recovery).
- **Apache 2.0 licensed.** Compatible with the project's MIT + Commons Clause license and with shipping as commercial software.
- **QAT quantization** (Quantization-Aware Training) preserves more quality than post-training quantization at the same 4-bit size.
- **128K context window** fits full workout history without truncation.
- **Battery efficient** — designed for mobile inference with competitive energy usage.

### Why MLX-Swift (not LiteRT-LM)

Our initial research pointed at Google's **LiteRT-LM** framework, which is the canonical runtime for `.litertlm` model files. Deeper investigation revealed a blocking gap: as of April 2026, LiteRT-LM's Swift API is still marked **"In Dev / Coming Soon"** in the official GitHub README. Only Kotlin (Android), Python, and C++ are production-stable. Shipping on LiteRT-LM today would require writing an Objective-C++ bridge over the C++ API with no official iOS samples and maintaining that bridge as Google's Swift story matures.

**MLX-Swift** is the better fit today:

- **First-class Swift bindings** with Apple's native ML framework — no bridging required.
- **Metal acceleration** optimized for Apple Silicon (all modern iPhones).
- **Built-in model downloading** from Hugging Face with local caching — no custom CDN or download infrastructure needed.
- **Actively used** by several Swift iOS LLM projects, with a well-documented integration path via Swift Package Manager.

### Model weights vs. the runtime

The model weights (safetensors, tokenizer, config files) are pure **data** — the numbers that define what the model knows. They are inert on their own. The **MLX-Swift runtime** (`MLXLLM` SPM package) is the separate piece of code that:

- Loads those weight files into GPU/ANE memory
- Runs the tokenizer (text → token IDs and back)
- Executes the neural-network forward pass (matrix math on Metal)
- Implements the autoregressive sampling loop (picking the next token, one at a time)

It is the same relationship as an `.mp4` video file and a video decoder: you can have the file locally all you want, but without a decoder that understands the format, it is just bytes.

### Why download-on-first-use (not bundled)

- **Small app binary.** The ~2 GB model is not included in the app download, keeping the App Store install size small.
- **No developer setup.** Contributors do not need to manually download weights from Hugging Face or configure Xcode folder references — the framework handles everything.
- **MLXLLM handles the complexity.** The framework provides downloading, caching, integrity checks, and offline fallback out of the box. No custom CDN or infrastructure needed.
- **Trade-off accepted:** First use requires an internet connection for the one-time download. Subsequent uses work fully offline from the local cache.

## Considered Alternatives

| Alternative | Why rejected |
|---|---|
| **Server-side LLM with subscription billing** | Contradicts the one-time-payment business model. |
| **Server-side LLM with BYO API keys** | Credentials-management friction; premium UX feels incomplete. |
| **LiteRT-LM via Objective-C++ bridge** | Swift API not production-ready; bridge maintenance burden; no official iOS samples. |
| **Apple Intelligence framework** | iOS 18+ language APIs are too restricted for free-form coaching use cases. |
| **MediaPipe LLM Inference API** | Deprecated in favor of LiteRT-LM; caps at Gemma 3 family (no Gemma 4 support). |
| **Apple On-Demand Resources (ODR)** | 2 GB per-tag limit forces splitting the model; adds platform lock-in. |
| **Gemma 3 1B** | Smaller and faster, but meaningfully weaker reasoning for multi-week training adaptation. |
| **Gemma 4 E2B (original choice)** | Not natively supported in MLXLLM v2.29.1; custom type registration using Gemma 3 architecture causes parameter shape mismatches at runtime. See amendment below. |
| **Bundled weights in app binary** | Inflates binary by ~1.5–2 GB; requires manual developer setup (HuggingFace download + Xcode folder reference). MLXLLM's built-in download eliminates both problems. |

## Consequences

### Positive

- Zero per-inference cost — aligns perfectly with the one-time-payment model.
- Fully offline after initial download — works on planes, trails, anywhere with or without signal.
- Privacy-preserving — the user's training data, RPE ratings, and notes never leave the device.
- No ongoing infrastructure — no servers, no CDNs, no rotating API keys.
- Small app binary — model downloads separately on first use.
- Simple developer experience — no manual weight management or Xcode configuration.

### Negative

- **First-use requires internet.** The ~2 GB model downloads on first coach invocation. Users on slow connections or without Wi-Fi on first launch will not be able to use the coach until the download completes.
- **First-run latency.** Cold model load on first coach invocation (after download) will take seconds; subsequent calls reuse the in-memory model.
- **Capability ceiling.** A 4B-parameter model is meaningfully less capable than frontier LLMs. We mitigate this by (a) constraining the prompt to a focused running-coach persona, (b) asking for concise outputs, and (c) not attempting agentic/tool-use behavior in V1.
- **MLX-Swift API drift.** The exact MLX-Swift API is still evolving; we have isolated the MLX-specific code inside `MLXAICoachService` so most of the codebase is insulated from surface changes.

## Amendment — 2026-04-08

**Changed:** Model from Gemma 4 E2B to Gemma 3 4B QAT; delivery from bundled binary to runtime download.

**Why:** Gemma 4 E2B is architecturally incompatible with MLXLLM v2.29.1. The `"gemma4"` model type is not in the built-in `LLMTypeRegistry`, and registering it under the Gemma 3 text architecture (`Gemma3TextConfiguration`/`Gemma3TextModel`) fails at runtime with parameter shape mismatches. No viable path for Gemma 4 on iOS exists as of April 2026 — mlx-swift-examples issue #467 is unresolved and LiteRT-LM's Swift SDK is still unreleased. See `docs/MODEL_UPGRADE.md` for the future migration path.

Switching to runtime download via MLXLLM's built-in `ModelConfiguration(id:)` also eliminates the manual weight-download and Xcode folder-reference setup that was previously required, significantly simplifying the developer experience and build process.

## Future work

- **Structured suggestion output.** V1 returns free-form narrative text. A V2 could parse suggestions into concrete edits (e.g. "change Monday's 10-mile long run to 8 miles easy") and offer one-tap apply.
- **Free-tier AI features.** Surface a lightweight coach summary ("this week in review") to free users, reinforcing the "Hybrid AIthletics" branding without gating the download.
- **Upgrade to Gemma 4 via LiteRT-LM.** When Google ships a production-ready Swift API for LiteRT-LM, evaluate upgrading to Gemma 4 E2B for better reasoning. The `AICoachService` protocol boundary makes this swap cheap. See `docs/MODEL_UPGRADE.md`.
- **Fine-tuning.** Explore LoRA adapters or small fine-tuning on a corpus of running-coach dialogue to improve domain fit without materially increasing model size.
