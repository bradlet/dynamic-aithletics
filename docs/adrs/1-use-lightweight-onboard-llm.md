# ADR 1: On-device LLM for the AI Coach feature

## Status

Accepted — 2026-04-06

## Context

Dynamic AIthletics ships as a **one-time-payment** iOS app (branded "Hybrid AIthletics"). The product vision includes an AI running coach that reviews the user's recent workouts — including a subjective 1–10 "how it felt" rating — and suggests adaptations to their upcoming two weeks of training.

A one-time-payment revenue model fundamentally constrains how we can deliver AI features:

- **Server-side LLM inference is not viable.** A user who pays once cannot continue to consume API tokens indefinitely on our dime. The unit economics break within a small number of interactions.
- **Subscription billing was considered and rejected.** It would solve the token-cost problem but contradicts the "Hybrid AIthletics" brand promise of a one-time purchase with premium AI features included.
- **Bring-your-own-API-key** (asking users to paste in their own OpenAI/Anthropic key) was rejected for UX reasons — it turns every AI interaction into a credentials-management problem and makes the premium experience feel half-finished.

The only remaining path that preserves both the business model and the user experience is **running a small LLM fully on-device**. This ADR captures the technology choices that make that feasible.

## Decision

We will integrate an on-device LLM with the following choices:

| Dimension | Choice |
|---|---|
| **Model** | Google Gemma 4 E2B (Effective 2B parameters), 4-bit MLX quantization |
| **Runtime** | MLX-Swift (Apple's native Swift machine-learning framework) |
| **Delivery** | Weights bundled in the app binary under `Resources/Models/gemma-4-e2b-it-mlx-4bit/` |
| **Abstraction** | `AICoachService` protocol in `Services/AICoach/` with `MLXAICoachService` and `StubAICoachService` implementations |

### Why Gemma 4 E2B

- **Purpose-built for edge devices.** Gemma 4's E-series uses Per-Layer Embeddings (PLE) to maximize effective capability per parameter. On iPhone 17 Pro, the `.litertlm` variant runs at ~25 tok/s (CPU) / ~56 tok/s (GPU) with 607 MB / 1.45 GB of RAM; the MLX 4-bit variant is in the same ballpark with a smaller on-disk footprint (~1.5 GB).
- **Apache 2.0 licensed.** Compatible with the project's MIT + Commons Clause license and with shipping as commercial software.
- **Strong instruction-following and reasoning** for a model in this weight class, including an understanding of the domain vocabulary we need (pace, RPE, tempo, intervals, recovery).
- **Community momentum.** The Hugging Face `litert-community` and `unsloth` organizations publish quantized variants in multiple formats, which de-risks maintenance.

### Why MLX-Swift (not LiteRT-LM)

Our initial research pointed at Google's **LiteRT-LM** framework, which is the canonical runtime for `.litertlm` model files. Deeper investigation revealed a blocking gap: as of April 2026, LiteRT-LM's Swift API is still marked **"🚀 In Dev / Coming Soon"** in the official GitHub README. Only Kotlin (Android), Python, and C++ are production-stable. Shipping on LiteRT-LM today would require writing an Objective-C++ bridge over the C++ API with no official iOS samples and maintaining that bridge as Google's Swift story matures.

**MLX-Swift** is the better fit today:

- **First-class Swift bindings** with Apple's native ML framework — no bridging required.
- **Metal acceleration** optimized for Apple Silicon (all modern iPhones).
- **Community-maintained 4-bit MLX quants of Gemma 4 E2B already exist** (`unsloth/gemma-4-E2B-it-UD-MLX-4bit`), meaning we can use the same target model we originally planned for, just via a different runtime.
- **Actively used** by several Swift iOS LLM projects, with a well-documented integration path via Swift Package Manager.

### Why bundle the weights in the app binary

- **Avoids CDN infrastructure.** A download-on-first-launch model would require hosting ~1.5 GB of weights on a CDN (Cloudflare R2, S3, or similar), plus logic for resumable downloads, integrity checks, and cache management. For a one-time-payment app this is complexity we'd rather not maintain.
- **Simple control flow.** The weights are guaranteed present the moment the app launches; there is no "downloading…" state to design or error path to handle.
- **Respects the "Hybrid AIthletics" positioning.** The user can also experience some AI features at the free tier — we may surface a lightweight version of the coach to free users so that even unpaid users see why the product is called "Hybrid AIthletics". Gating the download behind an upgrade would undermine that.

## Considered Alternatives

| Alternative | Why rejected |
|---|---|
| **Server-side LLM with subscription billing** | Contradicts the one-time-payment business model. |
| **Server-side LLM with BYO API keys** | Credentials-management friction; premium UX feels incomplete. |
| **LiteRT-LM via Objective-C++ bridge** | Swift API not production-ready; bridge maintenance burden; no official iOS samples. |
| **Apple Intelligence framework** | iOS 18+ language APIs are too restricted for free-form coaching use cases. |
| **MediaPipe LLM Inference API** | Deprecated in favor of LiteRT-LM; caps at Gemma 3 family (no Gemma 4 support). |
| **Download-on-upgrade from CDN** | Infrastructure burden; adds a "first-run download" UX step. |
| **Apple On-Demand Resources (ODR)** | 2 GB per-tag limit forces splitting the model; adds platform lock-in. |
| **Bundled Gemma 3 (1B) instead of Gemma 4 E2B** | Smaller and faster, but meaningfully weaker reasoning for multi-week training adaptation. |

## Consequences

### Positive

- Zero per-inference cost — aligns perfectly with the one-time-payment model.
- Fully offline — works on planes, trails, anywhere with or without signal.
- Privacy-preserving — the user's training data, RPE ratings, and notes never leave the device.
- No ongoing infrastructure — no servers, no CDNs, no rotating API keys.
- Single target model (Gemma 4 E2B) across future platforms (if we later port to macOS or iPadOS).

### Negative

- **App binary is ~1.5 GB larger.** Even free-tier users download the model, which inflates initial install size and App Store download times. We accept this as an intentional trade-off to surface AI to free users and avoid CDN complexity.
- **First-run latency.** Cold model load on first coach invocation will take seconds; subsequent calls reuse the in-memory model.
- **Capability ceiling.** A 2B-effective-parameter model is meaningfully less capable than frontier LLMs. We mitigate this by (a) constraining the prompt to a focused running-coach persona, (b) asking for concise outputs, and (c) not attempting agentic/tool-use behavior in V1.
- **MLX-Swift API drift.** The exact MLX-Swift API is still evolving; we have isolated the MLX-specific code inside `MLXAICoachService` so most of the codebase is insulated from surface changes.

## Future work

- **Structured suggestion output.** V1 returns free-form narrative text. A V2 could parse suggestions into concrete edits (e.g. "change Monday's 10-mile long run to 8 miles easy") and offer one-tap apply.
- **Free-tier AI features.** Surface a lightweight coach summary ("this week in review") to free users, reinforcing the "Hybrid AIthletics" branding without gating the download.
- **Reconsider LiteRT-LM.** When Google ships a production-ready Swift API for LiteRT-LM, re-evaluate whether migrating the runtime improves performance, binary size, or maintenance burden. The `AICoachService` protocol boundary was designed specifically to make such a swap cheap.
- **Model update path.** If a significantly better lightweight model ships (Gemma 5 E2B, or a stronger 4-bit quant), we can bundle the new weights in a future app update without touching the service protocol.
- **Fine-tuning.** Explore LoRA adapters or small fine-tuning on a corpus of running-coach dialogue to improve domain fit without materially increasing model size.
